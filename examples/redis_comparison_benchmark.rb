# frozen_string_literal: true

require "hyll"
require "redis"
require "benchmark"
require "benchmark/ips"
require "memory_profiler"
require "optparse"
require "json"

class HyllRedisComparison
  def initialize(precision: 10, data_size: 10_000, overlapping: 1_000, warm_up: true, benchmark_type: :all)
    @precision = precision
    @data_size = data_size
    @overlapping = overlapping
    @warm_up = warm_up
    @benchmark_type = benchmark_type
    @redis = Redis.new
    @results = {}

    puts "Initializing benchmark with:"
    puts "  - Precision: #{@precision}"
    puts "  - Data size: #{@data_size} elements"
    puts "  - Overlapping elements for merge tests: #{@overlapping}"
    puts "  - Warm-up: #{@warm_up ? "Enabled" : "Disabled"}"
    puts "\n"

    # Clean up any existing Redis keys
    @redis.del("hll1", "hll2", "hll_merged", "redis_hll1", "redis_hll2", "redis_merged", "accuracy_test")

    # Pre-generazione di dati per i test
    @elements = (0...@data_size).map { |i| "element-#{i}" }.freeze
    @set1_elements = (0...@data_size).map { |i| "set1-#{i}" }.freeze
    @set2_elements = (0...@data_size).map { |i| "set2-#{i + @data_size - @overlapping}" }.freeze

    # Pre-caricamento Redis
    if %i[all cardinality memory].include?(benchmark_type)
      @redis.pipelined do |pipeline|
        @elements.each { |e| pipeline.pfadd("hll1", e) }
      end
    end

    if %i[all merge].include?(benchmark_type)
      @redis.pipelined do |pipeline|
        @set1_elements.each { |e| pipeline.pfadd("redis_hll1", e) }
        @set2_elements.each { |e| pipeline.pfadd("redis_hll2", e) }
      end
    end

    if %i[all cardinality].include?(benchmark_type)
      @pre_hll_standard = Hyll::HyperLogLog.new(@precision)
      @pre_hll_enhanced = Hyll::EnhancedHyperLogLog.new(@precision)

      @elements.each do |e|
        @pre_hll_standard.add(e)
        @pre_hll_enhanced.add(e)
      end
    end

    if %i[all merge].include?(benchmark_type)
      @pre_merge_hll1 = Hyll::HyperLogLog.new(@precision)
      @pre_merge_hll2 = Hyll::HyperLogLog.new(@precision)
      @pre_merge_enhanced1 = Hyll::EnhancedHyperLogLog.new(@precision)
      @pre_merge_enhanced2 = Hyll::EnhancedHyperLogLog.new(@precision)

      @set1_elements.each do |e|
        @pre_merge_hll1.add(e)
        @pre_merge_enhanced1.add(e)
      end

      @set2_elements.each do |e|
        @pre_merge_hll2.add(e)
        @pre_merge_enhanced2.add(e)
      end

      @pre_merge_hll1_serialized = Marshal.dump(@pre_merge_hll1)
      @pre_merge_enhanced1_serialized = Marshal.dump(@pre_merge_enhanced1)
    end

    warm_up_benchmarks if @warm_up
  end

  def run_benchmarks
    case @benchmark_type
    when :insertion
      benchmark_insertion
    when :cardinality
      benchmark_cardinality
    when :merge
      benchmark_merge
    when :memory
      benchmark_memory_usage
    when :accuracy
      benchmark_accuracy
    else
      benchmark_insertion
      benchmark_cardinality
      benchmark_merge
      benchmark_memory_usage
      benchmark_accuracy
    end

    print_summary
  end

  def warm_up_benchmarks
    puts "Performing warm-up..."
    # Warm-up JIT compiler
    warm_up_count = [@data_size / 10, 1000].min

    # Warm-up insertion
    hll_warmup = Hyll::HyperLogLog.new(@precision)
    enhanced_warmup = Hyll::EnhancedHyperLogLog.new(@precision)

    warm_up_count.times do |i|
      hll_warmup.add("warmup-#{i}")
      enhanced_warmup.add("warmup-#{i}")
      @redis.pfadd("warmup_hll", "warmup-#{i}")
    end

    # Warm-up cardinality
    10.times do
      hll_warmup.cardinality
      hll_warmup.mle_cardinality
      enhanced_warmup.cardinality
      enhanced_warmup.cardinality(use_streaming: true)
      @redis.pfcount("warmup_hll")
    end

    # Warm-up merge
    warm_up_hll1 = Hyll::HyperLogLog.new(@precision)
    warm_up_hll2 = Hyll::HyperLogLog.new(@precision)
    5.times do
      warm_up_copy = Marshal.load(Marshal.dump(warm_up_hll1))
      warm_up_copy.merge(warm_up_hll2)
    end

    @redis.del("warmup_hll")
    puts "Warm-up complete.\n\n"
  end

  def benchmark_insertion
    puts "=== Insertion Performance ==="
    GC.start # Sincronizzazione GC per risultati più consistenti

    results = Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)

      # Hyll standard insertion
      x.report("Hyll Standard") do
        hll = Hyll::HyperLogLog.new(@precision)
        @elements.each { |e| hll.add(e) }
      end

      # Hyll enhanced insertion
      x.report("Hyll Enhanced") do
        hll = Hyll::EnhancedHyperLogLog.new(@precision)
        @elements.each { |e| hll.add(e) }
      end

      # Hyll batch insertion
      x.report("Hyll Batch") do
        Hyll::HyperLogLog.new(@precision).add_all(@elements)
      end

      # Redis insertion
      x.report("Redis PFADD") do
        @redis.del("bench_hll")
        @elements.each { |e| @redis.pfadd("bench_hll", e) }
      end

      # Redis pipelined insertion
      x.report("Redis Pipelined") do
        @redis.del("bench_hll")
        @redis.pipelined do |pipeline|
          @elements.each { |e| pipeline.pfadd("bench_hll", e) }
        end
      end

      x.compare!
    end

    @results[:insertion] = results
    puts "\n"
  end

  def benchmark_cardinality
    puts "=== Cardinality Estimation Performance ==="
    GC.start

    results = Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)

      # Hyll standard cardinality
      x.report("Hyll Standard") do
        @pre_hll_standard.cardinality
      end

      # Hyll standard MLE
      x.report("Hyll MLE") do
        @pre_hll_standard.mle_cardinality
      end

      # Hyll enhanced cardinality
      x.report("Hyll Enhanced") do
        @pre_hll_enhanced.cardinality
      end

      # Hyll enhanced streaming
      x.report("Hyll Enhanced Stream") do
        @pre_hll_enhanced.cardinality(use_streaming: true)
      end

      # Redis cardinality
      x.report("Redis PFCOUNT") do
        @redis.pfcount("hll1")
      end

      x.compare!
    end

    @results[:cardinality] = results
    puts "\n"
  end

  def benchmark_merge
    puts "=== Merge Performance ==="
    GC.start

    results = Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)

      # Hyll standard merge
      x.report("Hyll Standard") do
        hll_copy = Marshal.load(@pre_merge_hll1_serialized)
        hll_copy.merge(@pre_merge_hll2)
      end

      # Hyll enhanced merge
      x.report("Hyll Enhanced") do
        enhanced_copy = Marshal.load(@pre_merge_enhanced1_serialized)
        enhanced_copy.merge(@pre_merge_enhanced2)
      end

      # Redis merge
      x.report("Redis PFMERGE") do
        @redis.pfmerge("redis_merged", "redis_hll1", "redis_hll2")
      end

      x.compare!
    end

    @results[:merge] = results
    puts "\n"
  end

  def benchmark_memory_usage
    puts "=== Memory Usage ==="
    GC.start

    # Memory usage of standard HLL
    hll_standard_memory = report_memory("Hyll Standard") do
      hll = Hyll::HyperLogLog.new(@precision)
      @elements.each { |e| hll.add(e) }
      hll
    end

    # Memory usage of enhanced HLL
    hll_enhanced_memory = report_memory("Hyll Enhanced") do
      hll = Hyll::EnhancedHyperLogLog.new(@precision)
      @elements.each { |e| hll.add(e) }
      hll
    end

    # Memory usage of actual elements (for comparison)
    raw_elements_memory = report_memory("Raw Elements Array") do
      @elements.dup
    end

    # Redis memory usage
    redis_memory = @redis.memory("USAGE", "hll1")
    puts "Redis memory usage for HLL key: #{redis_memory} bytes"

    # Calcola compression ratio
    puts "\nCompression ratios:"
    puts "  Hyll Standard:  #{(raw_elements_memory[:allocated] / hll_standard_memory[:retained]).round(2)}x"
    puts "  Hyll Enhanced:  #{(raw_elements_memory[:allocated] / hll_enhanced_memory[:retained]).round(2)}x"
    puts "  Redis:          #{(raw_elements_memory[:allocated] * 1024 / redis_memory).round(2)}x"

    @results[:memory] = {
      hyll_standard: hll_standard_memory,
      hyll_enhanced: hll_enhanced_memory,
      raw_elements: raw_elements_memory,
      redis: redis_memory
    }

    puts "\n"
  end

  def benchmark_accuracy
    puts "=== Accuracy Comparison ==="
    GC.start

    accuracy_elements = (0...@data_size).map { |i| "accuracy-#{i}" }

    # Hyll standard
    hll_standard = Hyll::HyperLogLog.new(@precision)
    hll_standard.add_all(accuracy_elements)

    # Hyll enhanced
    hll_enhanced = Hyll::EnhancedHyperLogLog.new(@precision)
    hll_enhanced.add_all(accuracy_elements)

    hll_standard_high = Hyll::HyperLogLog.new([@precision + 2, 16].min)
    hll_standard_high.add_all(accuracy_elements)

    # Redis
    @redis.del("accuracy_test")
    @redis.pipelined do |pipeline|
      accuracy_elements.each { |e| pipeline.pfadd("accuracy_test", e) }
    end

    # Get estimates
    hll_standard_est = hll_standard.cardinality
    hll_standard_mle = hll_standard.mle_cardinality
    hll_standard_high_est = hll_standard_high.cardinality
    hll_enhanced_est = hll_enhanced.cardinality
    hll_enhanced_stream = hll_enhanced.cardinality(use_streaming: true)
    redis_est = @redis.pfcount("accuracy_test")

    # Calcola errori
    standard_error = calculate_error("Hyll Standard", hll_standard_est, @data_size)
    standard_mle_error = calculate_error("Hyll Standard MLE", hll_standard_mle, @data_size)
    standard_high_error = calculate_error("Hyll Standard (High Precision)", hll_standard_high_est, @data_size)
    enhanced_error = calculate_error("Hyll Enhanced", hll_enhanced_est, @data_size)
    enhanced_stream_error = calculate_error("Hyll Enhanced Stream", hll_enhanced_stream, @data_size)
    redis_error = calculate_error("Redis", redis_est, @data_size)

    @results[:accuracy] = {
      hyll_standard: standard_error,
      hyll_standard_mle: standard_mle_error,
      hyll_standard_high: standard_high_error,
      hyll_enhanced: enhanced_error,
      hyll_enhanced_stream: enhanced_stream_error,
      redis: redis_error
    }

    # Grafico dell'errore (ASCII art)
    puts "\nError comparison (lower is better):"
    print_error_bar("Hyll Standard", standard_error[:percent])
    print_error_bar("Hyll MLE", standard_mle_error[:percent])
    print_error_bar("Hyll (High Prec)", standard_high_error[:percent])
    print_error_bar("Hyll Enhanced", enhanced_error[:percent])
    print_error_bar("Hyll Enh Stream", enhanced_stream_error[:percent])
    print_error_bar("Redis", redis_error[:percent])
  end

  def print_error_bar(label, error_pct)
    display_error = [error_pct, 300].min
    bars = (display_error / 5).to_i
    truncated = display_error < error_pct

    printf("%-18s |%-60s| %.2f%%%s\n",
           label,
           "#" * bars,
           error_pct,
           truncated ? " (truncated)" : "")
  end

  def print_summary
    puts "\n=== BENCHMARK SUMMARY ==="
    puts "Precision: #{@precision}, Data size: #{@data_size}"

    puts "\nACCURACY WINNER: #{get_accuracy_winner}" if @results[:accuracy]

    if @results[:insertion] && @results[:cardinality] && @results[:merge]
      puts "\nPERFORMANCE WINNERS:"
      puts "  Insertion:   #{get_insertion_winner}"
      puts "  Cardinality: #{get_cardinality_winner}"
      puts "  Merge:       #{get_merge_winner}"
    end

    puts "\nMEMORY USAGE WINNER: #{get_memory_winner}" if @results[:memory]

    puts "\nRECOMMENDATION:"
    puts generate_recommendation
  end

  def get_accuracy_winner
    errors = @results[:accuracy].transform_values { |v| v[:percent] }
    winner = errors.min_by { |_, v| v }
    "#{winner[0].to_s.split("_").map(&:capitalize).join(" ")} (#{winner[1].round(2)}% error)"
  end

  def get_insertion_winner
    @results[:insertion].entries.max_by(&:ips).label
  end

  def get_cardinality_winner
    @results[:cardinality].entries.max_by(&:ips).label
  end

  def get_merge_winner
    @results[:merge].entries.max_by(&:ips).label
  end

  def get_memory_winner
    memories = {
      hyll_standard: @results[:memory][:hyll_standard][:retained],
      hyll_enhanced: @results[:memory][:hyll_enhanced][:retained],
      redis: @results[:memory][:redis]
    }

    winner = memories.min_by { |_, v| v }
    "#{winner[0].to_s.split("_").map(&:capitalize).join(" ")} (#{winner[1] / 1024.0} KB)"
  end

  def generate_recommendation
    return "Run accuracy benchmark to generate recommendation" unless @results[:accuracy]

    errors = @results[:accuracy].transform_values { |v| v[:percent] }

    if errors[:redis] < 5.0
      "Redis offers excellent accuracy and good performance, recommended for most use cases."
    elsif errors[:hyll_standard] < errors[:hyll_enhanced] && errors[:hyll_standard] < 15.0
      "Hyll Standard with precision #{@precision} offers good accuracy and best insertion performance."
    elsif errors[:hyll_enhanced] < 15.0
      "Hyll Enhanced offers better accuracy than Standard and good overall performance."
    else
      "Consider using higher precision (#{[@precision + 2, 16].min}) for better accuracy."
    end
  end

  def export_results(filename)
    File.write(filename, JSON.pretty_generate(@results))
    puts "Results exported to #{filename}"
  end

  private

  def report_memory(label)
    GC.start # Force GC before measurement
    result = nil
    report = MemoryProfiler.report do
      result = yield
    end

    allocated = report.total_allocated_memsize / 1024.0
    retained = report.total_retained_memsize / 1024.0

    puts "#{label}:"
    puts "  Total allocated: #{allocated.round(2)} KB"
    puts "  Total retained: #{retained.round(2)} KB"

    # Return memory stats
    { allocated: allocated, retained: retained, result: result }
  end

  def calculate_error(label, estimate, actual)
    error_pct = ((estimate - actual).abs / actual.to_f) * 100
    result = {
      estimate: estimate.round,
      actual: actual,
      difference: (estimate - actual).round,
      percent: error_pct.round(2)
    }

    puts "#{label}: Estimated #{result[:estimate]} vs Actual #{actual} (Error: #{result[:percent]}%)"
    result
  end
end

# Parse command line options
options = {
  precision: 10,
  data_size: 10_000,
  overlapping: 1_000,
  warm_up: true,
  benchmark_type: :all,
  output_file: nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby redis_comparison_benchmark.rb [options]"

  opts.on("-p", "--precision PRECISION", Integer, "HyperLogLog precision (4-16)") do |p|
    options[:precision] = p
  end

  opts.on("-d", "--data-size SIZE", Integer, "Number of elements to add") do |d|
    options[:data_size] = d
  end

  opts.on("-o", "--overlapping SIZE", Integer, "Number of overlapping elements for merge tests") do |o|
    options[:overlapping] = o
  end

  opts.on("--no-warm-up", "Skip warm-up phase") do
    options[:warm_up] = false
  end

  opts.on("-b", "--benchmark TYPE", %i[all insertion cardinality merge memory accuracy],
          "Run specific benchmark type (all, insertion, cardinality, merge, memory, accuracy)") do |b|
    options[:benchmark_type] = b
  end

  opts.on("--output FILE", "Export results to JSON file") do |f|
    options[:output_file] = f
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Run benchmarks
puts "Starting HyperLogLog Comparison Benchmark: Hyll vs Redis"
puts "-----------------------------------------------------"

begin
  comparison = HyllRedisComparison.new(
    precision: options[:precision],
    data_size: options[:data_size],
    overlapping: options[:overlapping],
    warm_up: options[:warm_up],
    benchmark_type: options[:benchmark_type]
  )

  comparison.run_benchmarks

  comparison.export_results(options[:output_file]) if options[:output_file]
rescue Redis::CannotConnectError
  puts "ERROR: Cannot connect to Redis server."
  puts "Please ensure Redis is running locally on the default port (6379)."
  puts "You can start Redis with: redis-server"
end

puts "Benchmark complete!"
