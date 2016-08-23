# frozen_string_literal: true
require 'rack/utils'
require 'uber/inheritable_attr'
require 'action_dispatch'
require 'action_dispatch/middleware/exception_wrapper'
require 'active_support/core_ext/object/json'
require 'active_model_serializers'

module Noise
  # Constructs error response (status, body)
  # @!attribute [rw] renderer
  #   @return [Proc<#String>]
  #
  #   @example

  #
  class ExceptionResponder
    class << self
      # @param error [StandardError]
      # @param status [Integer, Symbol] HTTP status to use for response
      # @api private
      #
      def register(error, status:)
        ActionDispatch::ExceptionWrapper.rescue_responses[error.to_s] = status
      end
    end

    # @param env
    # @param exception_renderer_class
    def initialize(env, exception_renderer_class = ExceptionRenderer)
      @env = env
      @exception_renderer = exception_renderer_class.new(env)
    end

    attr_reader :env, :exception_renderer
    protected :env

    # @return [Hash] JSON-serializable body
    def body
      @body ||= exception_renderer.render(self)
    end

    # @return [Hash] headers
    def headers
      {
        'Content-Type' => "#{::Mime::JSON}; charset=#{ActionDispatch::Response.default_charset}",
        'Content-Length' => body.bytesize.to_s,
      }
    end

    # @return [Integer] HTTP status code
    def status_code
      status_symbol = ActionDispatch::ExceptionWrapper.rescue_responses[error.class.name]
      # calls `status_code` from Rack::Utils
      Rack::Utils.status_code(status_symbol)
    end

    def error
      env['action_dispatch.exception']
    end
  end
end
