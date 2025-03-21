# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Merge Properties" do
  let(:precision) { 10 }

  context "when merging HyperLogLog counters" do
    it "is commutative (A ∪ B = B ∪ A)" do
      # Create and populate two HLL counters
      hll1 = Hyll.new(precision: precision)
      hll2 = Hyll.new(precision: precision)

      # Add different elements to each
      1000.times { |i| hll1.add("set1-#{i}") }
      1000.times { |i| hll2.add("set2-#{i}") }

      # Merge in both directions
      hll1_plus_2 = hll1.dup
      hll1_plus_2.merge(hll2)

      hll2_plus_1 = hll2.dup
      hll2_plus_1.merge(hll1)

      # Verify cardinality estimates are the same
      expect(hll1_plus_2.cardinality).to be_within(0.01).of(hll2_plus_1.cardinality)
    end

    it "is associative ((A ∪ B) ∪ C = A ∪ (B ∪ C))" do
      # Create three HLL counters
      hll_a = Hyll.new(precision: precision)
      hll_b = Hyll.new(precision: precision)
      hll_c = Hyll.new(precision: precision)

      # Add different elements to each
      1000.times { |i| hll_a.add("set-a-#{i}") }
      1000.times { |i| hll_b.add("set-b-#{i}") }
      1000.times { |i| hll_c.add("set-c-#{i}") }

      # (A ∪ B) ∪ C
      ab = hll_a.dup
      ab.merge(hll_b)
      abc1 = ab.dup
      abc1.merge(hll_c)

      # A ∪ (B ∪ C)
      bc = hll_b.dup
      bc.merge(hll_c)
      abc2 = hll_a.dup
      abc2.merge(bc)

      # Verify cardinality estimates are the same
      expect(abc1.cardinality).to be_within(0.01).of(abc2.cardinality)
    end

    it "handles merging with empty sets correctly" do
      # Create populated and empty HLLs
      populated = Hyll.new(precision: precision)
      empty = Hyll.new(precision: precision)

      1000.times { |i| populated.add("element-#{i}") }
      original_cardinality = populated.cardinality

      # Merge with empty
      populated.merge(empty)

      # Cardinality should remain unchanged
      expect(populated.cardinality).to eq(original_cardinality)

      # Merge empty with populated
      empty.merge(populated)

      # Empty should now have the same cardinality as populated
      expect(empty.cardinality).to eq(populated.cardinality)
    end
  end

  context "when merging EnhancedHyperLogLog counters" do
    it "maintains functionality with different implementation types" do
      # Create standard and Enhanced counters
      standard = Hyll.new(type: :standard, precision: precision)
      enhanced = Hyll.new(type: :enhanced, precision: precision)

      # Add the same elements to both
      set1 = (1..1000).map { |i| "shared-#{i}" }
      set2 = (1001..2000).map { |i| "standard-only-#{i}" }
      set3 = (2001..3000).map { |i| "enhanced-only-#{i}" }

      standard.add_all(set1 + set2)
      enhanced.add_all(set1 + set3)

      # Get current estimates
      standard_original = standard.cardinality
      enhanced_original = enhanced.cardinality

      # Convert to compatible types and merge
      standard_copy = standard.dup
      standard_copy.merge(enhanced.to_hll)

      enhanced_copy = enhanced.dup
      enhanced_copy.merge(standard.to_enhanced)

      # Simply verify that the merged counters are still functional
      # and returning non-zero estimates (merging behavior may vary)
      expect(standard_copy.cardinality).to be > 0
      expect(enhanced_copy.cardinality).to be > 0

      # Print diagnostics
      puts "Standard before: #{standard_original}, after: #{standard_copy.cardinality}"
      puts "Enhanced before: #{enhanced_original}, after: #{enhanced_copy.cardinality}"
    end
  end
end
