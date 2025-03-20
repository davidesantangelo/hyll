# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hyll do
  describe ".new" do
    it "creates a standard HyperLogLog by default" do
      hll = described_class.new
      expect(hll).to be_a(Hyll::HyperLogLog)
      expect(hll).not_to be_a(Hyll::P4HyperLogLog)
    end

    it "creates a P4HyperLogLog when specified" do
      hll = described_class.new(type: :p4)
      expect(hll).to be_a(Hyll::P4HyperLogLog)
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
      expect(deserialized).not_to be_a(Hyll::P4HyperLogLog)
      expect(deserialized.cardinality).to be_within(1).of(original.cardinality)
    end

    it "correctly deserializes P4HyperLogLog data" do
      original = Hyll::P4HyperLogLog.new(10)
      (1..100).each { |i| original.add(i) }

      serialized = original.serialize
      deserialized = described_class.deserialize(serialized)

      expect(deserialized).to be_a(Hyll::P4HyperLogLog)
      expect(deserialized.cardinality).to be_within(1).of(original.cardinality)
    end
  end

  it "has a version number" do
    expect(Hyll::VERSION).not_to be nil
  end
end
