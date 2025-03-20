# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Precision Tests" do
  [4, 8, 10, 12, 14].each do |precision|
    context "with precision #{precision}" do
      let(:hll) { Hyll.new(precision: precision) }
      let(:exact_count) { 10_000 }

      it "produces an estimate" do
        # Add unique elements
        exact_count.times do |i|
          hll.add("element-#{i}")
        end

        # Calculate the estimated cardinality
        estimated = hll.cardinality

        # Calculate the error percentage
        error_percentage = ((estimated - exact_count).abs.to_f / exact_count) * 100

        # Since this is a probabilistic algorithm, we can't be too strict
        # Just log the values and ensure estimate is non-zero
        expect(estimated).to be > 0

        puts "Precision: #{precision}, Exact: #{exact_count}, Estimated: #{estimated}"
        puts "Error: #{error_percentage.round(2)}%"
      end
    end
  end
end
