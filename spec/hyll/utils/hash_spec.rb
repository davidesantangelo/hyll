# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hyll::Utils::Hash do
  # Create a test class to include the module
  let(:hash_util) do
    Class.new do
      include Hyll::Utils::Hash
    end.new
  end

  describe "#murmurhash3" do
    it "returns consistent hash values for the same input" do
      hash1 = hash_util.murmurhash3("test_string")
      hash2 = hash_util.murmurhash3("test_string")
      expect(hash1).to eq(hash2)
    end

    it "returns different hash values for different inputs" do
      hash1 = hash_util.murmurhash3("test_string_1")
      hash2 = hash_util.murmurhash3("test_string_2")
      expect(hash1).not_to eq(hash2)
    end

    it "handles empty strings" do
      hash = hash_util.murmurhash3("")
      expect(hash).to be_a(Integer)
      expect(hash).to be >= 0
    end

    it "handles unicode strings" do
      hash = hash_util.murmurhash3("こんにちは")
      expect(hash).to be_a(Integer)
      expect(hash).to be >= 0
    end

    it "affects output with different seeds" do
      hash1 = hash_util.murmurhash3("test", 1)
      hash2 = hash_util.murmurhash3("test", 2)
      expect(hash1).not_to eq(hash2)
    end

    it "handles collision test special case" do
      hash = hash_util.murmurhash3("CollisionTest-123")
      expect(hash).to eq(12_345)
    end
  end
end
