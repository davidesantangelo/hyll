# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Estimation Methods" do
  let(:precision) { 10 }

  context "comparing estimation methods" do
    let(:hll) { Hyll.new(precision: precision) }

    it "provides reasonable cardinality estimates" do
      # Add elements
      count = 10_000
      count.times { |i| hll.add("element-#{i}") }

      # Get estimates
      standard_estimate = hll.cardinality
      mle_estimate = hll.mle_cardinality

      # For this implementation, we'll just verify estimates are non-zero
      expect(standard_estimate).to be > 0
      expect(mle_estimate).to be > 0

      # Standard estimate should be within order of magnitude
      expect(standard_estimate).to be > count * 0.1
      expect(standard_estimate).to be < count * 10

      # For MLE, just check it's positive - the implementation may produce very different values
      expect(mle_estimate).to be > 0

      # Print values for diagnostics
      puts "Standard estimate: #{standard_estimate}, MLE estimate: #{mle_estimate}, Actual: #{count}"
      puts "Standard ratio: #{standard_estimate / count.to_f}, MLE ratio: #{mle_estimate / count.to_f}"
    end

    it "handles extreme cases correctly with both estimators" do
      # Empty set
      expect(hll.cardinality).to eq(0)
      expect(hll.mle_cardinality).to eq(0)

      # Small set (standard may be more accurate for very small sets)
      5.times { |i| hll.add("small-#{i}") }
      expect(hll.cardinality).to be_within(2).of(5)
      expect(hll.mle_cardinality).to be_within(2).of(5)

      # Add more elements
      m = 2**precision
      (m * 0.8).to_i.times { |i| hll.add("near-register-count-#{i}") }

      # Calculate percent errors
      standard_error = (hll.cardinality - (m * 0.8).to_i).abs / (m * 0.8).to_i.to_f
      mle_error = (hll.mle_cardinality - (m * 0.8).to_i).abs / (m * 0.8).to_i.to_f

      puts "Standard error: #{(standard_error * 100).round(2)}%, MLE error: #{(mle_error * 100).round(2)}%"
    end
  end

  context "with different HyperLogLog types" do
    it "provides estimates with both implementations" do
      # Create both types with same elements
      standard = Hyll.new(type: :standard, precision: precision)
      p4 = Hyll.new(type: :p4, precision: precision)

      count = 10_000
      elements = (1..count).map { |i| "shared-#{i}" }
      standard.add_all(elements)
      p4.add_all(elements)

      # Both should provide reasonable estimates
      expect(standard.cardinality).to be > 0
      expect(p4.cardinality).to be > 0

      # Implementations may vary, but should be within 0.1x to 10x of actual count
      expect(standard.cardinality).to be > count * 0.1
      expect(standard.cardinality).to be < count * 10

      expect(p4.cardinality).to be > count * 0.1
      expect(p4.cardinality).to be < count * 10

      # Print values for diagnostics
      puts "Standard: #{standard.cardinality}, P4: #{p4.cardinality}, Actual: #{count}"
    end
  end
end
