# Hyll

[![Build Status](https://github.com/davidesantangelo/hyll/workflows/Ruby%20Tests/badge.svg)](https://github.com/davidesantangelo/hyll/actions)

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
hll = Hyll.new

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
hll = Hyll.new(precision: 12)

# Add many elements
1000.times do |i|
  hll.add("element-#{i}")
end

puts hll.cardinality  # Output: approximately 1000
```

### Using Different Algorithm Variants

```ruby
# Standard HyperLogLog (default)
standard_hll = Hyll.new(type: :standard)

# P4HyperLogLog (Presto-compatible implementation)
p4_hll = Hyll.new(type: :p4)

# You can also use :hll as an alias for :standard
# and :presto as an alias for :p4
presto_hll = Hyll.new(type: :presto)
```

### Adding Multiple Elements

```ruby
# Add multiple elements at once
hll.add_all(["apple", "banana", "cherry", "date"])
```

### Merging HyperLogLog Counters

```ruby
# Creating and populating two HLL counters
hll1 = Hyll.new(precision: 10)
hll2 = Hyll.new(precision: 10)

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
p4 = Hyll.new(type: :p4)
p4.add_all(["apple", "banana", "cherry"])

# Convert from standard HyperLogLog to P4HyperLogLog
hll = Hyll.new
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
restored_hll = Hyll.deserialize(data)
```

### Creating Empty HLLs with Factory Method

```ruby
# Using the Factory directly for advanced use cases
empty_standard = Hyll::Factory.create(type: :standard, precision: 12)
empty_p4 = Hyll::Factory.create(type: :p4, precision: 14)

# Or use the simple module method
empty_hll = Hyll.new(precision: 12)
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
- Factory pattern for creating and deserializing counters

## Implementation Details

Hyll offers two main implementations:

1. **Standard HyperLogLog**: Optimized for accuracy and memory efficiency, uses sparse format for small cardinalities and dense format with 4-bit packing for larger sets.

2. **P4HyperLogLog**: A strictly dense format similar to Facebook's Presto P4HYPERLOGLOG type, where "P4" refers to the 4-bit precision per register. This format is slightly less memory-efficient but offers better compatibility with other HyperLogLog implementations.

The internal architecture follows a modular approach:

- `Hyll::Constants`: Shared constants used throughout the library
- `Hyll::Utils::Hash`: Hash functions for element processing
- `Hyll::Utils::Math`: Mathematical operations for HyperLogLog calculations
- `Hyll::HyperLogLog`: The standard implementation
- `Hyll::P4HyperLogLog`: The Presto-compatible implementation
- `Hyll::Factory`: Factory pattern for creating counters

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
