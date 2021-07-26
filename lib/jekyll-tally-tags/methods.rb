# frozen_string_literal: true

require "jekyll"

module Jekyll
  module TallyTags
    class Methods

      # @param [Integer] a
      # @param [Integer] b
      def self.sum(a, b)
        self.to_f_s(a.to_f + b.to_f)
      end

      # @param [Integer] a
      # @param [Integer] b
      def self.div(a, b)
        self.to_f_s(a.to_f / b.to_f)
      end

      # @param [Integer] a
      # @param [Integer] b
      def self.mul(a, b)
        self.to_f_s(a.to_f * b.to_f)
      end

      # @param [Integer] a
      # @param [Integer] b
      def self.sub(a, b)
        self.to_f_s(a.to_f - b.to_f)
      end

      # @param [Float] number
      def self.to_f_s(number)
        if number - number.round != 0
          number.round(2).to_s
        else
          number.round.to_s
        end
      end

    end
  end
end
