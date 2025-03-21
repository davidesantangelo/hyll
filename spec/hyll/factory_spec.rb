# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hyll::Factory do
  describe ".create" do
    it "creates a standard HyperLogLog by default" do
      hll = described_class.create
      expect(hll).to be_a(Hyll::HyperLogLog)
      expect(hll).not_to be_a(Hyll::EnhancedHyperLogLog)
    end

    it "creates a standard HyperLogLog with :standard type" do
      hll = described_class.create(type: :standard)
      expect(hll).to be_a(Hyll::HyperLogLog)
      expect(hll).not_to be_a(Hyll::EnhancedHyperLogLog)
    end

    it "creates a standard HyperLogLog with :hll type" do
      hll = described_class.create(type: :hll)
      expect(hll).to be_a(Hyll::HyperLogLog)
      expect(hll).not_to be_a(Hyll::EnhancedHyperLogLog)
    end

    it "creates a EnhancedHyperLogLog with :enhanced type" do
      hll = described_class.create(type: :enhanced)
      expect(hll).to be_a(Hyll::EnhancedHyperLogLog)
    end

    it "creates a EnhancedHyperLogLog with :enhanced type" do
      hll = described_class.create(type: :enhanced)
      expect(hll).to be_a(Hyll::EnhancedHyperLogLog)
    end

    it "uses the specified precision" do
      hll = described_class.create(precision: 8)
      expect(hll.precision).to eq(8)
    end

    it "raises an error for unknown types" do
      expect { described_class.create(type: :unknown) }.to raise_error(Hyll::Error)
    end
  end

  describe ".from_serialized" do
    it "correctly deserializes standard HyperLogLog data" do
      original = Hyll::HyperLogLog.new(10)
      (1..100).each { |i| original.add(i) }

      serialized = original.serialize
      deserialized = described_class.from_serialized(serialized)

      expect(deserialized).to be_a(Hyll::HyperLogLog)
      expect(deserialized).not_to be_a(Hyll::EnhancedHyperLogLog)
      expect(deserialized.cardinality).to be_within(1).of(original.cardinality)
    end

    it "correctly deserializes EnhancedHyperLogLog data" do
      original = Hyll::EnhancedHyperLogLog.new(10)
      (1..100).each { |i| original.add(i) }

      serialized = original.serialize
      deserialized = described_class.from_serialized(serialized)

      expect(deserialized).to be_a(Hyll::EnhancedHyperLogLog)
      expect(deserialized.cardinality).to be_within(1).of(original.cardinality)
    end
  end
end
