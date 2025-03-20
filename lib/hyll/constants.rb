# frozen_string_literal: true

module Hyll
  # Constants used by the HyperLogLog implementation
  module Constants
    # The bias correction alpha values for different register sizes
    ALPHA = {
      16 => 0.673,
      32 => 0.697,
      64 => 0.709,
      128 => 0.7213,
      256 => 0.7327,
      512 => 0.7439,
      1024 => 0.7553,
      2048 => 0.7667,
      4096 => 0.7780,
      8192 => 0.7894,
      16_384 => 0.8009,
      32_768 => 0.8124,
      65_536 => 0.8239
    }.freeze

    # Default threshold for switching from sparse to dense format
    DEFAULT_SPARSE_THRESHOLD = 25

    # Maximum value for a 4-bit register (dense format)
    MAX_4BIT_VALUE = 15
  end
end
