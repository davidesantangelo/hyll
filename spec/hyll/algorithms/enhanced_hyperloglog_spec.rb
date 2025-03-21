# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hyll::EnhancedHyperLogLog do
  let(:enhanced) { described_class.new(10) }

  it "initializes with the specified precision" do
    expect(enhanced.precision).to eq(10)
  end

  it "always uses dense format" do
    expect(enhanced.instance_variable_get(:@using_exact_counting)).to be false
  end

  it "estimates cardinality accurately" do
    (1..100).each { |i| enhanced.add(i) }
    expect(enhanced.cardinality).to be_within(15).of(100)
  end

  it "can convert back to standard HyperLogLog" do
    (1..100).each { |i| enhanced.add(i) }

    hll = enhanced.to_hll
    expect(hll).to be_a(Hyll::HyperLogLog)
    expect(hll.cardinality).to be_within(15).of(enhanced.cardinality)
  end

  it "serializes and deserializes correctly" do
    (1..100).each { |i| enhanced.add(i) }

    serialized = enhanced.serialize
    restored = described_class.deserialize(serialized)

    expect(restored).to be_a(described_class)
    expect(restored.cardinality).to be_within(1).of(enhanced.cardinality)
  end

  it "merges with other EnhancedHyperLogLog instances" do
    enhanceda = described_class.new(10)
    enhancedb = described_class.new(10)

    (1..500).each { |i| enhanceda.add(i) }
    (401..900).each { |i| enhancedb.add(i) }

    enhanceda.merge(enhancedb)
    expect(enhanceda.cardinality).to be_within(300).of(900)
  end

  it "merges with standard HyperLogLog instances" do
    enhanced = described_class.new(10)
    hll = Hyll::HyperLogLog.new(10)

    (1..500).each { |i| enhanced.add(i) }
    (401..900).each { |i| hll.add(i) }

    enhanced.merge(hll)
    expect(enhanced.cardinality).to be_within(300).of(900)
  end

  it "raises error when merging with different precision" do
    enhanceda = described_class.new(10)
    enhancedb = described_class.new(12)

    expect { enhanceda.merge(enhancedb) }.to raise_error(Hyll::Error)
  end

  context "register handling" do
    it "uses direct register access instead of 4-bit packing" do
      enhanced.add("test")
      register_array = enhanced.instance_variable_get(:@registers)
      expect(register_array.size).to eq(2**10) # Direct 1:1 mapping
    end

    it "updates register values correctly" do
      index = 42
      enhanced.send(:update_register, index, 5)
      expect(enhanced.send(:get_register_value, index)).to eq(5)

      # Update to a higher value
      enhanced.send(:update_register, index, 8)
      expect(enhanced.send(:get_register_value, index)).to eq(8)

      # Attempt to update to a lower value (shouldn't change)
      enhanced.send(:update_register, index, 3)
      expect(enhanced.send(:get_register_value, index)).to eq(8)
    end
  end

  context "with different data types" do
    it "handles strings efficiently" do
      strings = (1..100).map { |i| "string-#{i}" }
      strings.each { |s| enhanced.add(s) }
      expect(enhanced.cardinality).to be_within(20).of(100)
    end

    it "handles integers efficiently" do
      (1..1000).each { |i| enhanced.add(i) }
      expect(enhanced.cardinality).to be_within(200).of(1000)
    end

    it "handles mixed data types" do
      mixed = [
        42, "string", :symbol, 3.14, true, false, nil,
        [1, 2, 3], { a: 1, b: 2 }, Time.now
      ]
      mixed.each { |item| enhanced.add(item) }
      expect(enhanced.cardinality).to be_within(3).of(mixed.size)
    end
  end
end
