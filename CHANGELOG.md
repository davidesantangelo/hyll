# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-03-22

### Added
- Initial implementation of HyperLogLog algorithm
- Customizable precision (4-16) with appropriate error rates
- Memory-efficient storage optimizations:
  - Sparse representation for small cardinalities (exact counting)
  - Dense format with 4-bit register packing (2 registers per byte)
  - Delta encoding against baseline values
  - Overflow handling for outlier register values
- Maximum Likelihood Estimation (MLE) for improved accuracy
- EnhancedHyperLogLog enhanced version of HyperLogLog with additional features
- Merge functionality for combining multiple HyperLogLog counters
- Serialization and deserialization support
- Auto-detection and correction for sequential integer inputs
- Method chaining support for all operations
- Utility methods:
  - `add_all` for adding multiple elements at once
  - `count` for integer cardinality
  - `mle_cardinality` as an alias for maximum likelihood estimation
  - Factory method `empty` for creating empty counters
  - Format conversion methods `to_enhanced` and `to_hll`
- Comprehensive test suite with edge case handling

## About the Release Date

This first release honors the memory of Philippe Flajolet (1948-2011), the brilliant computer scientist who invented the HyperLogLog algorithm. Flajolet died on March 22, 2011. His pioneering work in probabilistic algorithms and analytic combinatorics revolutionized the way we deal with cardinality estimation problems in large data sets.

The HyperLogLog algorithm he created (along with co-authors) allows us to count distinct elements in massive datasets with minimal memory requirements, making previously impossible computations feasible.