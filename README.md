# Hyll

![Gem Version](https://img.shields.io/gem/v/hyll)
![Gem Total Downloads](https://img.shields.io/gem/dt/hyll)
[![Build Status](https://github.com/davidesantangelo/hyll/workflows/Ruby%20Tests/badge.svg)](https://github.com/davidesantangelo/hyll/actions)

Hyll is a Ruby implementation of the [HyperLogLog algorithm](https://en.wikipedia.org/wiki/HyperLogLog) for the count-distinct problem, which efficiently approximates the number of distinct elements in a multiset with minimal memory usage. It supports both standard and Enhanced variants, offering a flexible approach for large-scale applications and providing convenient methods for merging, serialization, and maximum likelihood estimation.

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
standard_hll = Hyll.new(type: :standard) # You can also use :hll as an alias for :standard


# EnhancedHyperLogLog
enhanced_hll = Hyll.new(type: :enhanced)
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

### Using EnhancedHyperLogLog Format

EnhancedHyperLogLog a strictly enhanced version of HyperLogLog with additional features - inspired by Presto's P4HYPERLOGLOG:

```ruby
# Create a EnhancedHyperLogLog directly
enhanced = Hyll.new(type: :enhanced)
enhanced.add_all(["apple", "banana", "cherry"])

# Convert from standard HyperLogLog to EnhancedHyperLogLog
hll = Hyll.new
hll.add_all(["apple", "banana", "cherry"])
enhanced = hll.to_enhanced

# Convert from EnhancedHyperLogLog to standard HyperLogLog
hll = enhanced.to_hll

# Use the streaming cardinality estimator for improved accuracy
# This implementation is based on the martingale estimator from Daniel Ting's paper
streaming_estimate = enhanced.cardinality(use_streaming: true)

# Get variance and confidence intervals for the streaming estimate
variance = enhanced.streaming_variance
bounds = enhanced.streaming_error_bounds(confidence: 0.95) # 95% confidence interval
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
empty_enhanced = Hyll::Factory.create(type: :enhanced, precision: 14)

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

![hll](https://github.com/user-attachments/assets/6cb4431e-1e97-4493-a7eb-db4a31797425)

> This chart visualizes the relationship between precision values in HyperLogLog and the theoretical error rates. HyperLogLog is a probabilistic algorithm used for cardinality estimation with a typical error of **1.04/√m** (or **1.04·m⁻¹/²**), where **m = 2^precision** is the number of registers.

## Performance Comparison

This table compares different configurations of the HyperLogLog algorithm:

| Precision | Memory Usage | Error Rate | Max Elements | Implementation |
| --------- | ------------ | ---------- | ------------ | -------------- |
| 4         | 0.13 KB      | ~26%       | ~100K        | Standard       |
| 8         | 2.0 KB       | ~6.5%      | ~10M         | Standard       |
| 10        | 8.0 KB       | ~3.25%     | ~1B          | Standard       |
| 12        | 32.0 KB      | ~1.625%    | ~10B         | Standard       |
| 14        | 128.0 KB     | ~0.8125%   | ~100B        | Standard       |
| 16        | 512.0 KB     | ~0.4%      | ~1T          | Standard       |
| 10        | 9.0 KB       | ~3.25%     | ~1B          | Enhanced       |
| 12        | 36.0 KB      | ~1.625%    | ~10B         | Enhanced       |

### Comparison with Other Cardinality Estimators

| Algorithm        | Memory Efficiency | Accuracy (Cardinality) | Merge Support (Cardinality)    | Implementation Complexity | Primary Use Case(s)                                      |
| ---------------- | ----------------- | ---------------------- | ------------------------------ | ------------------------- | -------------------------------------------------------- |
| HyperLogLog      | High              | High (Approximate)     | Yes                            | Medium                    | High-scale cardinality estimation                        |
| Linear Counting  | Medium            | Medium (Approximate)   | Limited                        | Low                       | Moderate scale cardinality estimation, simplicity        |
| LogLog           | High              | Medium (Approximate)   | Yes                            | Low                       | Very high memory efficiency cardinality estimation       |
| K-Minimum Values | Medium            | High (Approximate)     | Yes                            | Medium                    | High accuracy cardinality estimation, set operations     |
| Bloom Filter     | Medium            | N/A (Membership)       | No (Cardinality) / Yes (Union) | Low                       | Membership testing with false positives, not cardinality |

### Benchmark Results

Below are actual performance measurements from an Apple Mac Mini M4 with 24GB RAM:

| Operation               | Implementation       | Time (seconds) | Items/Operations |
| ----------------------- | -------------------- | -------------- | ---------------- |
| Element Addition        | Standard HyperLogLog | 0.0176         | 10,000 items     |
| Element Addition        | EnhancedHyperLogLog        | 0.0109         | 10,000 items     |
| Cardinality Calculation | Standard HyperLogLog | 0.0011         | 10 calculations  |
| Cardinality Calculation | EnhancedHyperLogLog        | 0.0013         | 10 calculations  |
| Serialization           | Standard HyperLogLog | 0.0003         | 10 operations    |
| Deserialization         | Standard HyperLogLog | 0.0005         | 10 operations    |

#### Memory Efficiency

| Data Structure | Memory Usage (bytes) | Items   | Compression Ratio |
| -------------- | -------------------- | ------- | ----------------- |
| Standard Array | 800,040              | 100,000 | 1x                |
| HyperLogLog    | 128                  | 100,000 | 6,250x            |

These benchmarks demonstrate HyperLogLog's exceptional memory efficiency, maintaining a compression ratio of over 6,250x compared to storing the raw elements, while still providing accurate cardinality estimates.

## Features

- Standard HyperLogLog implementation with customizable precision
- Memory-efficient register storage with 4-bit packing (inspired by Facebook's Presto implementation)
- Sparse representation for small cardinalities
- Dense representation for larger datasets
- EnhancedHyperLogLog format for compatibility with other systems
- Streaming martingale estimator for improved accuracy with EnhancedHyperLogLog
- Maximum Likelihood Estimation for improved accuracy
- Merge and serialization capabilities
- Factory pattern for creating and deserializing counters

## Implementation Details

Hyll offers two main implementations:

1. **Standard HyperLogLog**: Optimized for accuracy and memory efficiency, uses sparse format for small cardinalities and dense format with 4-bit packing for larger sets.

2. **EnhancedHyperLogLog**: A strictly dense format similar to Facebook's Presto P4HYPERLOGLOG type, where "P4" refers to the 4-bit precision per register. This format is slightly less memory-efficient but offers better compatibility with other HyperLogLog implementations. It also includes a streaming martingale estimator that can provide up to 1.56x better accuracy for the same memory usage.

The internal architecture follows a modular approach:

- `Hyll::Constants`: Shared constants used throughout the library
- `Hyll::Utils::Hash`: Hash functions for element processing
- `Hyll::Utils::Math`: Mathematical operations for HyperLogLog calculations
- `Hyll::HyperLogLog`: The standard implementation
- `Hyll::EnhancedHyperLogLog`: The enhanced implementation
- `Hyll::Factory`: Factory pattern for creating counters

## Examples

A basic examples file has been created to demonstrate how to use Hyll:

```ruby
# examples/basic.rb
require 'hyll'

# Create a new HyperLogLog counter
counter = Hyll::HyperLogLog.new

# Add some elements
1000.times { |i| counter.add(i) }

# Get the cardinality estimate
puts "Estimated cardinality: #{counter.count}"

# Using Maximum Likelihood Estimation (often more accurate)
puts "MLE cardinality: #{counter.mle_cardinality}"
```

For a comprehensive overview of all features, see `examples/basic.rb` which includes:
- Basic counting
- Custom precision settings
- Merging counters
- Serialization
- EnhancedHyperLogLog usage
- Batch operations
- Large dataset handling
- Set operations

For advanced usage scenarios, check out `examples/advance.rb` which includes:
- Set intersection estimation
- Working with custom data types
- Time-window based cardinality monitoring
- Advanced serialization techniques
- Precision vs. memory usage benchmarks

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## References and Acknowledgements

- Original HyperLogLog paper: ["HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm"](https://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf) by Philippe Flajolet, Éric Fusy, Olivier Gandouet, and Frédéric Meunier (2007).
- Improved bias correction: ["HyperLogLog in Practice: Algorithmic Engineering of a State of the Art Cardinality Estimation Algorithm"](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/40671.pdf) by Stefan Heule, Marc Nunkesser, and Alexander Hall (2013).
- Streaming cardinality estimation: ["Streamed Approximate Counting of Distinct Elements: Beating Optimal Batch Methods"](https://research.facebook.com/publications/streamed-approximate-counting-of-distinct-elements/) by Daniel Ting (2014).
- Facebook's Presto implementation details: ["HyperLogLog in Presto: A significantly faster way to handle cardinality estimation"](https://engineering.fb.com/2018/12/13/data-infrastructure/hyperloglog/) by Mehrdad Honarkhah and Arya Talebzadeh.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidesantangelo/hyll. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/davidesantangelo/hyll/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
