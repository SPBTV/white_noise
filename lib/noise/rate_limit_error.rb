require 'noise/public_error'
require 'noise/rate_limit_error_responder'

module Noise
  # Rate limit error.
  #
  class RateLimitError < PublicError
    attr_reader :retry_after

    # @param message_id [Symbol]
    # @param [String] retry_after
    #
    def initialize(message_id, retry_after:)
      super(message_id)

      @retry_after = retry_after
    end

    def responder
      RateLimitErrorResponder.new(self)
    end
  end
end

Noise::RateLimitError.register_as :too_many_requests, severity: :info
