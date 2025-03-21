# frozen_string_literal: true

require "spec_helper"
require "benchmark"
# Add require for objspace which provides memory measurement methods
require "objspace"

RSpec.describe "HyperLogLog Performance", :performance do
  let(:precision) { 10 }
  let(:element_count) { 10_000 }
  let(:hll) { Hyll::HyperLogLog.new(precision) }
  let(:enhancedhll) { Hyll::EnhancedHyperLogLog.new(precision) }

  it "has good add performance for HyperLogLog" do
    time = Benchmark.realtime do
      element_count.times { |i| hll.add("item-#{i}") }
    end

    # This is just a guideline - adjust based on actual performance
    expect(time).to be < 2.0 # Should add 10,000 items in under 2 seconds
    puts "HyperLogLog add performance: #{time} seconds for #{element_count} items"
  end

  it "has good add performance for EnhancedHyperLogLog" do
    time = Benchmark.realtime do
      element_count.times { |i| enhancedhll.add("item-#{i}") }
    end

    # This is just a guideline - adjust based on actual performance
    expect(time).to be < 2.0 # Should add 10,000 items in under 2 seconds
    puts "EnhancedHyperLogLog add performance: #{time} seconds for #{element_count} items"
  end

  it "has good cardinality calculation performance for HyperLogLog" do
    element_count.times { |i| hll.add("item-#{i}") }

    time = Benchmark.realtime do
      10.times { hll.cardinality }
    end

    # This is just a guideline - adjust based on actual performance
    expect(time).to be < 0.1 # Should calculate cardinality 10 times in under 0.1 seconds
    puts "HyperLogLog cardinality calculation performance: #{time} seconds for 10 calculations"
  end

  it "has good cardinality calculation performance for EnhancedHyperLogLog" do
    element_count.times { |i| enhancedhll.add("item-#{i}") }

    time = Benchmark.realtime do
      10.times { enhancedhll.cardinality }
    end

    # This is just a guideline - adjust based on actual performance
    expect(time).to be < 0.1 # Should calculate cardinality 10 times in under 0.1 seconds
    puts "EnhancedHyperLogLog cardinality calculation performance: #{time} seconds for 10 calculations"
  end

  it "has good serialization/deserialization performance" do
    element_count.times { |i| hll.add("item-#{i}") }

    serialization_time = Benchmark.realtime do
      10.times { hll.serialize }
    end

    serialized = hll.serialize

    deserialization_time = Benchmark.realtime do
      10.times { Hyll::HyperLogLog.deserialize(serialized) }
    end

    # These are just guidelines - adjust based on actual performance
    expect(serialization_time).to be < 0.1 # Should serialize 10 times in under 0.1 seconds
    expect(deserialization_time).to be < 0.1 # Should deserialize 10 times in under 0.1 seconds

    puts "HyperLogLog serialization performance: #{serialization_time} seconds for 10 operations"
    puts "HyperLogLog deserialization performance: #{deserialization_time} seconds for 10 operations"
  end

  context "with large datasets" do
    let(:large_element_count) { 100_000 }

    it "maintains reasonable memory usage" do
      # Skip the test if ObjectSpace.memsize_of is not available
      unless ObjectSpace.respond_to?(:memsize_of)
        skip "ObjectSpace.memsize_of is not available on this Ruby implementation"
      end

      # Create a sizable reference object to compare against
      reference_size = ObjectSpace.memsize_of(Array.new(large_element_count) { |i| "item-#{i}" })

      # Build a large HyperLogLog
      large_hll = Hyll::HyperLogLog.new(precision)
      large_element_count.times { |i| large_hll.add("item-#{i}") }

      # Estimate the size of the HyperLogLog object
      hll_size = ObjectSpace.memsize_of(large_hll)

      # The HyperLogLog should be much smaller than storing all the items
      expect(hll_size).to be < (reference_size * 0.01) # Should be less than 1% of reference size

      puts "Memory usage for #{large_element_count} items:"
      puts "  Array size: #{reference_size} bytes"
      puts "  HyperLogLog size: #{hll_size} bytes"
      puts "  Compression ratio: #{(reference_size.to_f / hll_size).round(2)}x"
    end
  end
end
