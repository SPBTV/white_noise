require 'noise/exception_responder'

module Noise
  # Special error responder with Retry-After header render support.
  #
  class RateLimitErrorResponder < ExceptionResponder
    # @return [Hash]
    def headers
      super.merge(
        'Retry-After' => @error.retry_after.to_s
      )
    end
  end
end
