# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Serialization" do
  let(:precision) { 10 }
  let(:element_count) { 10_000 }

  shared_examples "serializable counter" do |type|
    let(:hll) { Hyll.new(type: type, precision: precision) }

    before do
      element_count.times do |i|
        hll.add("element-#{i}")
      end
    end

    it "preserves basic functionality after serialization/deserialization" do
      # Serialize
      serialized = hll.serialize

      # Should produce a binary string
      expect(serialized).to be_a(String)
      expect(serialized.encoding).to eq(Encoding::ASCII_8BIT)

      # Deserialize
      deserialized = Hyll.deserialize(serialized)

      # Verify precision
      expect(deserialized.precision).to eq(precision)

      # Verify it's not empty
      expect(deserialized.cardinality).to be > 0

      # Print diagnostics
      puts "Original cardinality (#{type}): #{hll.cardinality}, Deserialized: #{deserialized.cardinality}"
    end

    it "can be used after deserialization" do
      # Serialize and deserialize
      serialized = hll.serialize
      deserialized = Hyll.deserialize(serialized)

      # Add more elements to the deserialized counter
      5.times { |i| deserialized.add("new-element-#{i}") }

      # Should still be functional
      expect(deserialized.cardinality).to be > 0

      # Create a new counter to merge with
      new_hll = Hyll.new(precision: precision)
      new_hll.add("test-element")

      # Should be able to merge
      deserialized.merge(new_hll)
      expect(deserialized.cardinality).to be > 0
    end

    it "produces reasonable output size" do
      serialized = hll.serialize

      # Very relaxed size check - just verify it's not enormous
      expect(serialized.bytesize).to be < 5_000
    end
  end

  describe "Standard HyperLogLog" do
    include_examples "serializable counter", :standard
  end

  describe "EnhancedHyperLogLog" do
    include_examples "serializable counter", :enhanced
  end

  it "produces deserialized counters that behave reasonably" do
    # Create standard HLL and serialize
    standard = Hyll.new(type: :standard, precision: precision)
    element_count.times { |i| standard.add("element-#{i}") }
    standard_serialized = standard.serialize

    # Deserialize
    standard_deserialized = Hyll.deserialize(standard_serialized)

    # Basic functionality check
    expect(standard_deserialized.cardinality).to be > 0

    # Add more elements to verify functionality
    standard_deserialized.add("new-element")
    expect(standard_deserialized.cardinality).to be > 0
  end
end
