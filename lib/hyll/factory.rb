# frozen_string_literal: true

module Hyll
  # Factory for creating HyperLogLog instances
  class Factory
    # Create a new HyperLogLog counter
    # @param type [Symbol] the type of HyperLogLog counter to create (:standard or :enhanced)
    # @param precision [Integer] the precision to use
    # @return [HyperLogLog, EnhancedHyperLogLog] a HyperLogLog counter
    def self.create(type: :standard, precision: 10)
      case type
      when :standard, :hll
        HyperLogLog.new(precision)
      when :enhanced
        EnhancedHyperLogLog.new(precision)
      else
        raise Error, "Unknown HyperLogLog type: #{type}"
      end
    end

    # Create a HyperLogLog counter from serialized data
    # @param data [String] the serialized data
    # @return [HyperLogLog, EnhancedHyperLogLog] the deserialized counter
    def self.from_serialized(data)
      format_version, _, is_enhanced, = data.unpack("CCCC")

      if format_version == 3 && is_enhanced == 1
        EnhancedHyperLogLog.deserialize(data)
      else
        HyperLogLog.deserialize(data)
      end
    end
  end
end
