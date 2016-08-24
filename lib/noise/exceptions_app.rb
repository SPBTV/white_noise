# frozen_string_literal: true
require_relative 'exception_responder'

module Noise
  # Custom rails exception app to render all API level errors as JSON.
  #
  # Why it needed: in case we use default ActionController's `rescue_from`
  # we will not be able to properly handle and render exceptions raised in middlewares (like Warden),
  # so for processing of all possible exceptions we configure Rails' `config.exceptions_app`
  # to use our own API-specific implementation.
  #
  class ExceptionsApp
    # @param env [Hash] rack env
    def call(env)
      responder = build_responder(env)
      [responder.status_code, responder.headers, [responder.body]]
    end

    private

    def build_responder(env)
      error = env['action_dispatch.exception']
      responder_class = error.respond_to?(:responder_class) ? error.responder_class : ExceptionResponder
      responder_class.new(env)
    end
  end
end
