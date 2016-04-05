# frozen_string_literal: true
require 'rack/utils'
require 'uber/inheritable_attr'
require 'action_dispatch'
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
    extend Uber::InheritableAttr

    inheritable_attr :renderer
    self.renderer = lambda do |error, status_code|
      ActiveModel::SerializableResource.new(
        Array(error),
        each_serializer: PublicErrorSerializer,
        adapter: :json,
        root: 'errors',
        meta: { 'status' => status_code },
        scope: { http_status: status_code }
      )
    end
    delegate :renderer, to: :class

    class << self
      # @param error [StandardError]
      # @param status [Integer, Symbol] HTTP status to use for response
      # @api private
      #
      def register(error, status:)
        ActionDispatch::ExceptionWrapper.rescue_responses[error.to_s] = status
      end

      # Return exceptions responder for given error
      # @param error [StandardError]
      # @return [ExceptionResponder]
      #
      def [](error)
        if error.is_a?(PublicError)
          error.responder
        else
          new(error)
        end
      end
    end

    # @param error [StandardError]
    def initialize(error)
      @error = error
    end
    attr_reader :error
    protected :error

    # @return [Hash] JSON-serializable body
    def body
      @body ||= renderer.call(error, status_code).as_json.to_json
    end

    # @return [Hash] headers
    def headers
      {
        'Content-Type' => "#{::Mime::JSON}; charset=#{ActionDispatch::Response.default_charset}",
        'Content-Length' => body.bytesize.to_s
      }
    end

    # @return [Integer] HTTP status code
    def status_code
      status_symbol = ActionDispatch::ExceptionWrapper.rescue_responses[error.class.name]
      # calls `status_code` from Rack::Utils
      Rack::Utils.status_code(status_symbol)
    end

    def ==(other)
      self.class == other.class && error == other.error
    end
  end
end
