# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hyll do
  describe ".new" do
    it "creates a standard HyperLogLog by default" do
      hll = described_class.new
      expect(hll).to be_a(Hyll::HyperLogLog)
      expect(hll).not_to be_a(Hyll::EnhancedHyperLogLog)
    end

    it "creates a EnhancedHyperLogLog when specified" do
      hll = described_class.new(type: :enhanced)
      expect(hll).to be_a(Hyll::EnhancedHyperLogLog)
    end

    it "respects precision parameter" do
      hll = described_class.new(precision: 12)
      expect(hll.precision).to eq(12)
    end
  end

  describe ".deserialize" do
    it "correctly deserializes standard HyperLogLog data" do
      original = Hyll::HyperLogLog.new(10)
      (1..100).each { |i| original.add(i) }

      serialized = original.serialize
      deserialized = described_class.deserialize(serialized)

      expect(deserialized).to be_a(Hyll::HyperLogLog)
      expect(deserialized).not_to be_a(Hyll::EnhancedHyperLogLog)
      expect(deserialized.cardinality).to be_within(1).of(original.cardinality)
    end

    it "correctly deserializes EnhancedHyperLogLog data" do
      original = Hyll::EnhancedHyperLogLog.new(10)
      (1..100).each { |i| original.add(i) }

      serialized = original.serialize
      deserialized = described_class.deserialize(serialized)

      expect(deserialized).to be_a(Hyll::EnhancedHyperLogLog)
      expect(deserialized.cardinality).to be_within(1).of(original.cardinality)
    end
  end

  it "has a version number" do
    expect(Hyll::VERSION).not_to be nil
  end
end
