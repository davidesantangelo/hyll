# frozen_string_literal: true

require "hyll"

# ADVANCED USAGE EXAMPLES

# Define User class outside of method scope
class User
  attr_reader :id, :email

  def initialize(id, email)
    @id = id
    @email = email
  end

  # Override to_s for proper hashing
  def to_s
    "User:#{@id}:#{@email}"
  end
end

# Example 1: Estimating Intersection Size Between Sets
def intersection_example
  puts "=== Intersection Estimation Example ==="

  # Create two HyperLogLog counters
  hll1 = Hyll.new(precision: 12)
  hll2 = Hyll.new(precision: 12)

  # Add elements with controlled overlap (30% overlap)
  total_items = 100_000
  overlap = (total_items * 0.3).to_i

  # First set: 0 to 99,999
  total_items.times { |i| hll1.add("item-#{i}") }

  # Second set: 70,000 to 169,999 (30,000 items overlap)
  total_items.times { |i| hll2.add("item-#{i + total_items - overlap}") }

  # Create union by merging (make copy first to avoid modifying original)
  union = hll1.to_p4
  union.merge(hll2)

  # Calculate intersection using inclusion-exclusion principle
  # |A ∩ B| = |A| + |B| - |A ∪ B|
  estimate1 = hll1.cardinality
  estimate2 = hll2.cardinality
  union_estimate = union.cardinality
  intersection_estimate = estimate1 + estimate2 - union_estimate

  puts "Set A cardinality: #{estimate1.round}"
  puts "Set B cardinality: #{estimate2.round}"
  puts "Union cardinality: #{union_estimate.round}"
  puts "Estimated intersection: #{intersection_estimate.round}"
  puts "Actual intersection: #{overlap}"
  puts "Error rate: #{((intersection_estimate - overlap).abs / overlap * 100).round(2)}%"
  puts "\n"
end

# Example 2: Working with Custom Data Types
def custom_data_types_example
  puts "=== Custom Data Types Example ==="

  # Create HLL counter
  hll = Hyll.new

  # Add custom objects
  users = []
  1000.times do |i|
    # Some users will have the same email to simulate duplicates
    email = "user#{i % 800}@example.com"
    users << User.new(i, email)
  end

  # Add all users
  users.each { |user| hll.add(user) }

  # Check cardinality - should be close to 800 (unique emails)
  puts "Added #{users.size} users with #{users.map(&:email).uniq.size} unique emails"
  puts "HyperLogLog estimate: #{hll.cardinality.round}"
  puts "\n"

  # Track unique emails by domain
  domains = {}

  users.each do |user|
    domain = user.email.split("@").last
    domains[domain] ||= Hyll.new
    domains[domain].add(user.email)
  end

  domains.each do |domain, counter|
    puts "Domain #{domain}: ~#{counter.cardinality.round} unique emails"
  end
end

# Example 3: Monitoring Stream Cardinality with Time Windows
def time_window_example
  puts "=== Time Window Monitoring Example ==="

  # Create counters for different time windows
  minute_counter = Hyll.new
  hour_counter = Hyll.new
  day_counter = Hyll.new

  # Simulate time windows with different event rates
  # For simplicity, we'll compress time in this example

  puts "Simulating a stream of events with varying rates..."

  # Simulate a day's worth of data
  # Each "minute" has a different number of events
  24.times do |hour|
    puts "Hour #{hour}:"

    # Reset minute counter each hour
    minute_counter.reset

    60.times do |minute|
      # Generate some data for this minute
      # Use time of day to vary the rate (busier during work hours)
      base_rate = 100
      time_factor = if (9..17).include?(hour)
                      10  # Work hours - 10x more traffic
                    elsif (18..22).include?(hour)
                      5   # Evening - 5x more traffic
                    else
                      1   # Late night/early morning - base traffic
                    end

      # Add some randomness
      rate = (base_rate * time_factor * (0.5 + rand)).to_i

      # Add unique events for this minute
      # Some IDs will repeat across minutes/hours to simulate returning users
      rate.times do |i|
        # Event ID combines hour, minute and unique ID
        # We'll make some IDs repeat to simulate returning users
        event_id = "user-#{(hour * 60 + minute + i) % 10_000}"

        minute_counter.add(event_id)
        hour_counter.add(event_id)
        day_counter.add(event_id)
      end

      # Every 15 minutes, print stats
      next unless minute % 15 == 14

      puts "  Minute #{minute + 1} - Unique users in last:"
      puts "    - Minute: #{minute_counter.cardinality.round}"
      puts "    - Hour: #{hour_counter.cardinality.round}"
      puts "    - Day so far: #{day_counter.cardinality.round}"
    end

    # Reset hour counter at end of day
    hour_counter.reset unless hour == 23
  end

  puts "Simulation complete. Total unique users for the day: #{day_counter.cardinality.round}"
  puts "\n"
end

# Example 4: Advanced Serialization and Storage
def serialization_example
  puts "=== Advanced Serialization Example ==="

  # Create and populate HLL
  hll = Hyll.new
  puts "Adding 1 million items..."
  1_000_000.times { |i| hll.add("user-#{i}") }

  # Serialize to different formats
  binary = hll.serialize

  # Simulate storing in a database (Base64 encoded)
  require "base64"
  base64_string = Base64.strict_encode64(binary)

  puts "Original cardinality: #{hll.cardinality.round}"
  puts "Binary serialized size: #{binary.bytesize} bytes"
  puts "Base64 serialized size: #{base64_string.bytesize} bytes"

  # Demonstrate storage efficiency
  puts "Storage efficiency: #{(1_000_000 * 8 / binary.bytesize).round}x compression ratio"

  # Simulate retrieving and deserializing
  retrieved_binary = Base64.strict_decode64(base64_string)
  retrieved_hll = Hyll.deserialize(retrieved_binary)

  puts "Retrieved cardinality: #{retrieved_hll.cardinality.round}"
  puts "\n"

  # Convert to P4 format for interoperability
  p4_hll = hll.to_p4
  p4_binary = p4_hll.serialize

  puts "P4 format serialized size: #{p4_binary.bytesize} bytes"
  puts "\n"
end

# Example 5: Benchmark Different Precision Levels
def precision_benchmark
  puts "=== Precision Benchmark Example ==="

  # Create HLLs with different precision levels
  precisions = [6, 8, 10, 12, 14]
  hlls = precisions.map { |p| Hyll.new(precision: p) }

  # Number of unique elements to add
  num_elements = 1_000_000

  puts "Benchmarking with #{num_elements} unique elements"
  puts "Precision | Memory (bytes) | Estimate | Error (%)"
  puts "----------|----------------|----------|----------"

  precisions.each_with_index do |precision, i|
    # Add elements
    num_elements.times { |j| hlls[i].add("element-#{j}") }

    # Calculate statistics
    serialized = hlls[i].serialize
    memory_used = serialized.bytesize
    estimate = hlls[i].cardinality
    error_percent = ((estimate - num_elements).abs / num_elements.to_f * 100).round(2)

    puts format("%9d | %14d | %8d | %9.2f", precision, memory_used, estimate.round, error_percent)
  end
end

# Run all examples
intersection_example
custom_data_types_example
time_window_example
serialization_example
precision_benchmark

puts "Advanced examples completed!"
