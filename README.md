# Hyll

[![Build Status](https://github.com/davidesantangelo/hyll/workflows/Ruby%20Tests/badge.svg)](https://github.com/davidesantangelo/hyll/actions)
[![Maintainability](https://api.codeclimate.com/v1/badges/a99a88d28ad37a79dbf6/maintainability)](https://codeclimate.com/github/davidesantangelo/hyll/maintainability)

Hyll is a Ruby implementation of the [HyperLogLog algorithm](https://en.wikipedia.org/wiki/HyperLogLog) for the count-distinct problem, which efficiently approximates the number of distinct elements in a multiset with minimal memory usage.

> The name "Hyll" is a shortened form of "HyperLogLog", keeping the characteristic "H" and "LL" sounds.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hyll'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install hyll
```

## Usage

### Basic Usage

```ruby
require 'hyll'

# Create a new HyperLogLog counter with default precision (10)
hll = Hyll::HyperLogLog.new

# Add elements to the counter
hll.add("apple")
hll.add("banana")
hll.add("cherry")
hll.add("apple")  # Duplicates don't affect the cardinality

# Get the estimated cardinality (count of distinct elements)
puts hll.cardinality  # Output: approximately 3
```

### With Custom Precision

```ruby
# Create with custom precision (4-16)
# Higher precision means more memory usage but better accuracy
hll = Hyll::HyperLogLog.new(12)

# Add many elements
1000.times do |i|
  hll.add("element-#{i}")
end

puts hll.cardinality  # Output: approximately 1000
```

### Adding Multiple Elements

```ruby
# Add multiple elements at once
hll.add_all(["apple", "banana", "cherry", "date"])
```

### Merging HyperLogLog Counters

```ruby
# Creating and populating two HLL counters
hll1 = Hyll::HyperLogLog.new(10)
hll2 = Hyll::HyperLogLog.new(10)

hll1.add_all(["apple", "banana", "cherry"])
hll2.add_all(["cherry", "date", "elderberry"])

# Merge hll2 into hll1
hll1.merge(hll2)

puts hll1.cardinality  # Output: approximately 5
```

### Using Different Estimation Methods

```ruby
# Standard HyperLogLog estimator
puts hll.cardinality

# Maximum Likelihood Estimator (generally more accurate)
puts hll.maximum_likelihood_cardinality
# or use the shorter alias
puts hll.mle_cardinality
```

### Using P4HyperLogLog Format

P4HyperLogLog is a strictly dense format similar to Facebook's Presto implementation:

```ruby
# Create a P4HyperLogLog directly
p4 = Hyll::P4HyperLogLog.new(10)
p4.add_all(["apple", "banana", "cherry"])

# Convert from standard HyperLogLog to P4HyperLogLog
hll = Hyll::HyperLogLog.new(10)
hll.add_all(["apple", "banana", "cherry"])
p4 = hll.to_p4

# Convert from P4HyperLogLog to standard HyperLogLog
hll = p4.to_hll
```

### Serialization and Deserialization

```ruby
# Serialize for storage
hll.add_all(["apple", "banana", "cherry"])
serialized = hll.serialize

# Store in a file
File.binwrite("hll_data.bin", serialized)

# Later, restore the HyperLogLog
data = File.binread("hll_data.bin")
restored_hll = Hyll::HyperLogLog.deserialize(data)
```

### Creating Empty HLLs with Factory Method

```ruby
empty_hll = Hyll::HyperLogLog.empty(12)  # With precision 12
```

## Algorithm Overview

HyperLogLog is a probabilistic algorithm for counting unique elements in a dataset with very low memory overhead. It was introduced by Flajolet et al. in 2007 as an improvement on the earlier LogLog algorithm.

The algorithm works through the following principles:

1. **Hash Function**: Each element is hashed to produce a pseudo-random value.
2. **Register Selection**: A portion of the hash is used to select one of `m` registers (where `m = 2^precision`).
3. **Register Value**: The algorithm counts the number of leading zeros (+1) in the remaining hash bits. Each register stores the maximum observed value.
4. **Cardinality Estimation**: The harmonic mean of the register values is used to estimate the cardinality.

The algorithm provides a trade-off between memory usage and accuracy:
- Lower precision (4-6): Uses less memory but has higher error rates (>10%)
- Medium precision (7-11): Uses moderate memory with reasonable error rates (3-10%)
- Higher precision (12-16): Uses more memory with better accuracy (<3%)

## Features

- Standard HyperLogLog implementation with customizable precision
- Memory-efficient register storage with 4-bit packing (inspired by Facebook's Presto implementation)
- Sparse representation for small cardinalities
- Dense representation for larger datasets
- P4HyperLogLog format for compatibility with other systems
- Maximum Likelihood Estimation for improved accuracy
- Merge and serialization capabilities

## Use Cases

HyperLogLog is particularly useful in situations where you need to count unique elements in very large datasets with limited memory:

1. **Web Analytics**: Count unique visitors to a website without storing each visitor ID
2. **Database Query Optimization**: Efficiently estimate the cardinality of query results for query planning
3. **Network Traffic Analysis**: Track unique IP addresses in network flows
4. **Data Deduplication**: Quickly estimate potential space savings from deduplication
5. **Real-time Dashboards**: Provide approximate counts of distinct items for monitoring systems
6. **Distributed Systems**: Aggregate distinct counts across multiple machines with minimal network transfer

### Concrete Example: Tracking Unique Users Across Multiple Services

Imagine you run a platform with multiple microservices and want to track unique users across the entire system. Each service logs user interactions independently, but you need a global view of unique users.

```ruby
require 'hyll'
require 'json'

# Initialize a counter for each service
service_counters = {
  'web_app' => Hyll::HyperLogLog.new(12),
  'mobile_api' => Hyll::HyperLogLog.new(12),
  'recommendation_engine' => Hyll::HyperLogLog.new(12)
}

# Global counter for combined metrics
global_counter = Hyll::HyperLogLog.new(12)

# Simulate processing log files from each service
def process_service_logs(service_name, counter)
  puts "Processing logs for #{service_name}..."
  
  # Simulate reading user IDs from a log file
  user_ids = case service_name
  when 'web_app'
    # Web has many users with some overlap with mobile
    (1..50_000).to_a + (1..10_000).map { |i| "mobile_user_#{i}" }
  when 'mobile_api'
    # Mobile has fewer users but some not on web
    (1..30_000).to_a + (1..5_000).map { |i| "exclusive_mobile_#{i}" }
  when 'recommendation_engine'
    # Recommendations only for active users
    (1..25_000).to_a
  end
  
  # Add user IDs to the counter
  counter.add_all(user_ids)
  
  # Report the unique users for this service
  puts "Service #{service_name} has approximately #{counter.cardinality.to_i} unique users"
end

# Process logs for each service
service_counters.each do |service, counter|
  process_service_logs(service, counter)
end

# Merge all service counters into the global counter
service_counters.each do |_, counter|
  global_counter.merge(counter)
end

# Report global unique users
puts "\nPlatform-wide unique users: #{global_counter.cardinality.to_i}"

# Serialize the counter for later use
serialized = global_counter.serialize
File.binwrite("unique_users.bin", serialized)

puts "\nCounter serialized to unique_users.bin (#{serialized.bytesize} bytes)"
puts "Memory efficiency: tracking #{global_counter.cardinality.to_i} unique users using only #{serialized.bytesize} bytes"

# Later, we can deserialize and continue using it
restored = Hyll::HyperLogLog.deserialize(File.binread("unique_users.bin"))
puts "\nRestored counter shows #{restored.cardinality.to_i} unique users"

# To update based on new data the next day
puts "\nUpdating with new data..."
new_users = (80_000..85_000).to_a
restored.add_all(new_users)
puts "After adding new users, count is now #{restored.cardinality.to_i}"
```

## Memory Efficiency

Hyll implements several techniques for minimizing memory usage:

1. **Sparse representation** for small cardinalities (exact counting)
2. **4-bit register packing** for dense representation (2 registers per byte)
3. **Delta encoding** against a baseline value
4. **Overflow handling** for outlier values

For most practical uses, Hyll requires less than 1KB of memory regardless of the input data size.

## Error Rates

The standard error for HyperLogLog depends on the precision parameter:

| Precision | Registers (m) | Standard Error | Memory Usage |
|-----------|---------------|----------------|--------------|
| 4         | 16            | 26.0%          | 16 bytes     |
| 6         | 64            | 13.0%          | 64 bytes     |
| 8         | 256           | 6.5%           | 256 bytes    |
| 10        | 1,024         | 3.25%          | 1 KB         |
| 12        | 4,096         | 1.625%         | 4 KB         |
| 14        | 16,384        | 0.8125%        | 16 KB        |
| 16        | 65,536        | 0.40625%       | 64 KB        |

## Implementation Details

Hyll offers two main implementations:

1. **Standard HyperLogLog**: Optimized for accuracy and memory efficiency, uses sparse format for small cardinalities and dense format with 4-bit packing for larger sets.

2. **P4HyperLogLog**: A strictly dense format similar to Facebook's Presto P4HYPERLOGLOG type, where "P4" refers to the 4-bit precision per register. This format is slightly less memory-efficient but offers better compatibility with other HyperLogLog implementations.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## References and Acknowledgements

- Original HyperLogLog paper: "HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm" by Philippe Flajolet, Éric Fusy, Olivier Gandouet, and Frédéric Meunier (2007).
- Improved bias correction: "HyperLogLog in Practice: Algorithmic Engineering of a State of the Art Cardinality Estimation Algorithm" by Stefan Heule, Marc Nunkesser, and Alexander Hall (2013).
- Facebook's Presto implementation details: ["HyperLogLog in Presto: A significantly faster way to handle cardinality estimation"](https://engineering.fb.com/2018/12/13/data-infrastructure/hyperloglog/) by Mehrdad Honarkhah and Arya Talebzadeh.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidesantangelo/hyll. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/davidesantangelo/hyll/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Hyll project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/davidesantangelo/hyll/blob/master/CODE_OF_CONDUCT.md).
