# frozen_string_literal: true

require_relative "hyll/version"
require_relative "hyll/constants"
require_relative "hyll/utils/hash"
require_relative "hyll/utils/math"
require_relative "hyll/algorithms/hyperloglog"
require_relative "hyll/algorithms/enhanced_hyperloglog"
require_relative "hyll/factory"
require "digest"

module Hyll
  class Error < StandardError; end

  # Shorthand method to create a new HyperLogLog counter
  # @param type [Symbol] the type of counter to create (:standard or :enhanced)
  # @param precision [Integer] the precision to use
  # @return [HyperLogLog, EnhancedHyperLogLog] a HyperLogLog counter
  def self.new(type: :standard, precision: 10)
    Factory.create(type: type, precision: precision)
  end

  # Shorthand method to deserialize a HyperLogLog counter
  # @param data [String] the serialized data
  # @return [HyperLogLog, EnhancedHyperLogLog] the deserialized counter
  def self.deserialize(data)
    Factory.from_serialized(data)
  end
end
