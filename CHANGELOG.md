# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-03-24

### Added
- Associativity test for HyperLogLog merges to ensure (A ∪ B) ∪ C = A ∪ (B ∪ C)
- Guards against invalid inputs in mathematical functions
- Memoization for h_values calculation in MLE algorithm
- More comprehensive error handling with safeguards
- Added `examples/redis_comparison_benchmark.rb` for Redis comparison

### Changed
- Optimized Maximum Likelihood Estimation (MLE) algorithm for better performance
- Improved numerical stability in the secant method implementation
- Enhanced Taylor series calculation for better accuracy
- Fixed Math module namespace conflicts
- Added safeguards against division by zero and other numerical errors
- Limited maximum iterations in convergence algorithms to prevent infinite loops

### Fixed
- Addressed potential numerical instability in calculate_h_values method
- Fixed undefined method 'exp' error by using global namespace operator
- Improved edge case handling in the MLE algorithm

## [0.1.1] - 2025-03-21

### Changed
- Updated gem summary and description with more detailed information

## [0.1.0] - 2025-03-21

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