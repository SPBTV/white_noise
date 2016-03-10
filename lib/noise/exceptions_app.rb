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
      render(responder.status_code, Mime::JSON, responder.body.to_json)
    end

    private

    def render(status, content_type, body)
      [
        status,
        {
          'Content-Type' => "#{content_type}; charset=#{ActionDispatch::Response.default_charset}",
          'Content-Length' => body.bytesize.to_s
        },
        [body]
      ]
    end
  end
end
