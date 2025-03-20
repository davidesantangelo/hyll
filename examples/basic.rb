# frozen_string_literal: true

require "hyll"

# BASIC USAGE EXAMPLES

# Example 1: Basic Counting
puts "Example 1: Basic counting of unique elements"
counter = Hyll::HyperLogLog.new
100.times { |i| counter.add(i) }
puts "Added 100 unique numbers. Estimated count: #{counter.count}"
puts "Raw cardinality estimate: #{counter.cardinality}"
puts "\n"

# Example 2: MLE Estimation
puts "Example 2: Using Maximum Likelihood Estimation"
counter = Hyll::HyperLogLog.new
1000.times { |i| counter.add(i) }
puts "Standard estimation: #{counter.cardinality}"
puts "MLE estimation: #{counter.mle_cardinality}"
puts "\n"

# Example 3: Custom Precision
puts "Example 3: Setting custom precision"
# Lower precision (less memory, less accuracy)
counter_low = Hyll::HyperLogLog.new(6)
# Higher precision (more memory, more accuracy)
counter_high = Hyll::HyperLogLog.new(14)

10_000.times do |i|
  counter_low.add(i)
  counter_high.add(i)
end

puts "Low precision (2^6 registers): #{counter_low.count}"
puts "High precision (2^14 registers): #{counter_high.count}"
puts "\n"

# Example 4: Adding non-integer elements
puts "Example 4: Counting different data types"
counter = Hyll::HyperLogLog.new
%w[apple banana cherry apple durian].each { |fruit| counter.add(fruit) }
puts "Unique fruit count: #{counter.count}" # Should be approximately 4

counter.reset
["user1@example.com", "user2@example.com", "USER1@example.com"].each { |email| counter.add(email.downcase) }
puts "Unique email count (case insensitive): #{counter.count}" # Should be approximately 2
puts "\n"

# ADVANCED USAGE EXAMPLES

# Example 5: Merging counters
puts "Example 5: Merging counters"
counter1 = Hyll::HyperLogLog.new
counter2 = Hyll::HyperLogLog.new

# Add some unique elements to each counter
100.times { |i| counter1.add("item-#{i}") }
100.times { |i| counter2.add("item-#{i + 50}") } # 50 overlapping items

puts "Counter 1 estimate: #{counter1.count}"
puts "Counter 2 estimate: #{counter2.count}"

# Merge counter2 into counter1
counter1.merge(counter2)
puts "Merged counter estimate: #{counter1.count}" # Should be approximately 150
puts "\n"

# Example 6: Serialization
puts "Example 6: Serializing and deserializing"
original = Hyll::HyperLogLog.new
1000.times { |i| original.add(i) }

# Serialize the counter
serialized = original.serialize
puts "Serialized size: #{serialized.bytesize} bytes"

# Deserialize
deserialized = Hyll::HyperLogLog.deserialize(serialized)
puts "Original count: #{original.count}"
puts "Deserialized count: #{deserialized.count}"
puts "\n"

# Example 7: Using P4HyperLogLog
puts "Example 7: Using P4HyperLogLog"
p4_counter = Hyll::P4HyperLogLog.new(10)
10_000.times { |i| p4_counter.add(i) }
puts "P4HyperLogLog count: #{p4_counter.count}"

# Convert standard HLL to P4HLL
standard = Hyll::HyperLogLog.new(10)
10_000.times { |i| standard.add(i) }
p4_converted = standard.to_p4
puts "Standard HLL converted to P4: #{p4_converted.count}"

# Convert P4HLL back to standard HLL
standard_again = p4_counter.to_hll
puts "P4 converted back to standard: #{standard_again.count}"
puts "\n"

# Example 8: Batch Adding
puts "Example 8: Batch adding elements"
counter = Hyll::HyperLogLog.new
elements = (1..10_000).to_a
start_time = Time.now
counter.add_all(elements)
end_time = Time.now
puts "Added 10,000 elements in batch: #{counter.count}"
puts "Time taken: #{end_time - start_time} seconds"
puts "\n"

# Example 9: Dealing with large datasets
puts "Example 9: Memory efficiency with large datasets"
counter = Hyll::HyperLogLog.new(12) # 2^12 = 4096 registers
puts "Memory usage for 100 million elements is roughly the same as for 1000 elements"
puts "Sparse representation used until #{Hyll::Constants::DEFAULT_SPARSE_THRESHOLD} elements are added"

# Simulate adding 1000 elements and check memory footprint
1000.times { |i| counter.add(i) }
puts "Estimated memory for 1000 elements: #{counter.serialize.bytesize} bytes"

# Example 10: Estimating intersection size
puts "Example 10: Estimating intersection size"
set_a = Hyll::HyperLogLog.new
set_b = Hyll::HyperLogLog.new

# Add elements to both sets with some overlap
1000.times { |i| set_a.add("item-#{i}") }
1000.times { |i| set_b.add("item-#{i + 500}") } # 500 overlapping items

# Create a union set by merging
union = set_a.to_p4 # Make a copy first
union.merge(set_b)

# Estimate intersection using inclusion-exclusion principle
# |A ∩ B| = |A| + |B| - |A ∪ B|
intersection_size = set_a.count + set_b.count - union.count
puts "Set A size: #{set_a.count}"
puts "Set B size: #{set_b.count}"
puts "Union size: #{union.count}"
puts "Estimated intersection size: #{intersection_size} (actual: 500)"
puts "\n"

# Example 11: Streaming data application
puts "Example 11: Streaming data application"
puts "HyperLogLog is perfect for streaming applications where you can't store all data:"

counter = Hyll::HyperLogLog.new
puts "Imagine processing a stream of user IDs from web logs..."
# Simulate stream processing
10_000.times do
  # In a real stream, you'd process each item as it arrives
  user_id = rand(5000) # Simulate about 5000 unique users
  counter.add(user_id)

  # Periodically report statistics without storing all IDs
  puts "Processed #{user_id} records, estimated unique users: #{counter.count}" if (user_id % 2500).zero?
end

puts "Final unique user estimate: #{counter.count}"
puts "All this with minimal memory usage and O(1) update time!"
