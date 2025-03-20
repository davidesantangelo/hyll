# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hyll::P4HyperLogLog do
  let(:p4) { described_class.new(10) }

  it "initializes with the specified precision" do
    expect(p4.precision).to eq(10)
  end

  it "always uses dense format" do
    expect(p4.instance_variable_get(:@using_exact_counting)).to be false
  end

  it "estimates cardinality accurately" do
    (1..100).each { |i| p4.add(i) }
    expect(p4.cardinality).to be_within(15).of(100)
  end

  it "can convert back to standard HyperLogLog" do
    (1..100).each { |i| p4.add(i) }

    hll = p4.to_hll
    expect(hll).to be_a(Hyll::HyperLogLog)
    expect(hll.cardinality).to be_within(15).of(p4.cardinality)
  end

  it "serializes and deserializes correctly" do
    (1..100).each { |i| p4.add(i) }

    serialized = p4.serialize
    restored = described_class.deserialize(serialized)

    expect(restored).to be_a(described_class)
    expect(restored.cardinality).to be_within(1).of(p4.cardinality)
  end

  it "merges with other P4HyperLogLog instances" do
    p4a = described_class.new(10)
    p4b = described_class.new(10)

    (1..500).each { |i| p4a.add(i) }
    (401..900).each { |i| p4b.add(i) }

    p4a.merge(p4b)
    expect(p4a.cardinality).to be_within(300).of(900)
  end

  it "merges with standard HyperLogLog instances" do
    p4 = described_class.new(10)
    hll = Hyll::HyperLogLog.new(10)

    (1..500).each { |i| p4.add(i) }
    (401..900).each { |i| hll.add(i) }

    p4.merge(hll)
    expect(p4.cardinality).to be_within(300).of(900)
  end

  it "raises error when merging with different precision" do
    p4a = described_class.new(10)
    p4b = described_class.new(12)

    expect { p4a.merge(p4b) }.to raise_error(Hyll::Error)
  end

  context "register handling" do
    it "uses direct register access instead of 4-bit packing" do
      p4.add("test")
      register_array = p4.instance_variable_get(:@registers)
      expect(register_array.size).to eq(2**10) # Direct 1:1 mapping
    end

    it "updates register values correctly" do
      index = 42
      p4.send(:update_register, index, 5)
      expect(p4.send(:get_register_value, index)).to eq(5)

      # Update to a higher value
      p4.send(:update_register, index, 8)
      expect(p4.send(:get_register_value, index)).to eq(8)

      # Attempt to update to a lower value (shouldn't change)
      p4.send(:update_register, index, 3)
      expect(p4.send(:get_register_value, index)).to eq(8)
    end
  end

  context "with different data types" do
    it "handles strings efficiently" do
      strings = (1..100).map { |i| "string-#{i}" }
      strings.each { |s| p4.add(s) }
      expect(p4.cardinality).to be_within(20).of(100)
    end

    it "handles integers efficiently" do
      (1..1000).each { |i| p4.add(i) }
      expect(p4.cardinality).to be_within(200).of(1000)
    end

    it "handles mixed data types" do
      mixed = [
        42, "string", :symbol, 3.14, true, false, nil,
        [1, 2, 3], { a: 1, b: 2 }, Time.now
      ]
      mixed.each { |item| p4.add(item) }
      expect(p4.cardinality).to be_within(3).of(mixed.size)
    end
  end
end
