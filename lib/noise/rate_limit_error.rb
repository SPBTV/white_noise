# frozen_string_literal: true
require 'noise/public_error'
require 'noise/rate_limit_error_responder'

module Noise
  # Rate limit error.
  #
  class RateLimitError < PublicError
    attr_reader :retry_after

    # @param code [Symbol]
    # @param [String] retry_after
    #
    def initialize(code, retry_after:)
      super(code)

      @retry_after = retry_after
    end

    def responder_class
      RateLimitErrorResponder
    end
  end
end

Noise::RateLimitError.register_as :too_many_requests, severity: :info
