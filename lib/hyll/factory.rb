# frozen_string_literal: true

module Hyll
  # Factory for creating HyperLogLog instances
  class Factory
    # Create a new HyperLogLog counter
    # @param type [Symbol] the type of HyperLogLog counter to create (:standard or :p4)
    # @param precision [Integer] the precision to use
    # @return [HyperLogLog, P4HyperLogLog] a HyperLogLog counter
    def self.create(type: :standard, precision: 10)
      case type
      when :standard, :hll
        HyperLogLog.new(precision)
      when :p4, :presto
        P4HyperLogLog.new(precision)
      else
        raise Error, "Unknown HyperLogLog type: #{type}"
      end
    end

    # Create a HyperLogLog counter from serialized data
    # @param data [String] the serialized data
    # @return [HyperLogLog, P4HyperLogLog] the deserialized counter
    def self.from_serialized(data)
      format_version, _, is_p4, = data.unpack("CCCC")

      if format_version == 3 && is_p4 == 1
        P4HyperLogLog.deserialize(data)
      else
        HyperLogLog.deserialize(data)
      end
    end
  end
end
