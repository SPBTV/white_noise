require_relative 'exception_responder'
require 'action_dispatch'

module Noise
  # Custom rails exception app to render all API level errors as JSON.
  #
  # Why it needed: in case we use default ActionController's `rescue_from`
  # we will not be able to properly handle and render exceptions raised in middlewares (like Warden),
  # so for processing of all possible exceptions we configure Rails' `config.exceptions_app`
  # to use our own API-specific implementation.
  #
  class ExceptionsApp
    def call(env)
      error = env['action_dispatch.exception']
      responder = ExceptionResponder.new(error)

      [responder.status_code, responder.headers, [responder.body]]
    end
  end
end
