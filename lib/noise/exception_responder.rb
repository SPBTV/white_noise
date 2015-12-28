require 'rack/utils'
require 'action_dispatch/middleware/exception_wrapper'
require 'active_support/core_ext/object/json'
require 'active_model_serializers'

require_relative 'public_error_serializer'

module Noise
  # Constructs error response (status, body)
  # @!attribute [rw] renderer
  #   @return [Proc<#as_json>] lambda should return any object responding to `#as_json`
  #   e.g. Hash.
  #
  #   @example
  #     Noise::ExceptionResponder.renderer = lambda do |error, status_code|
  #       {
  #         meta: {
  #           code: status_code,
  #           error_id: error.message_id,
  #           error_description: error.message
  #         }
  #       }
  #     end
  #
  class ExceptionResponder
    cattr_accessor :renderer, instance_writer: false
    self.renderer = lambda do |error, status_code|
      ActiveModel::SerializableResource.serialize(
        Array(error),
        each_serializer: PublicErrorSerializer,
        adapter: :json,
        root: 'errors',
        meta: { 'status' => status_code },
        scope: { http_status: status_code }
      )
    end

    class << self
      # @param error [StandardError]
      # @param status [Integer, Symbol] HTTP status to use for response
      # @api private
      #
      def register(error, status:)
        ActionDispatch::ExceptionWrapper.rescue_responses[error.to_s] = status
      end
    end

    # @param error [StandardError]
    def initialize(error)
      @error = error
    end

    # @return [Hash] JSON-serializable body
    def body
      renderer.call(@error, status_code).as_json
    end

    # @return [Integer] HTTP status code
    def status_code
      status_symbol = ActionDispatch::ExceptionWrapper.rescue_responses[@error.class.name]
      # calls `status_code` from Rack::Utils
      Rack::Utils.status_code(status_symbol)
    end
  end
end