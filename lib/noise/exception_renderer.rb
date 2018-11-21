# frozen_string_literal: true
module Noise
  # Determines how to render exception
  #
  # @example
  #   class ApplicationExceptionRenderer < ExceptionRenderer
  #     def render(responder)
  #       if env[Rack::PATH_INFO] =~ %r{\A/partners}
  #         {
  #           id: error_id,
  #           error: message,
  #           code: code
  #         }
  #       else
  #         super
  #       end
  #     end
  #
  #     def message
  #       if error.is_a?(PublicError)
  #         error.message
  #       else
  #         'Internal Server Error'
  #       end
  #     end
  #
  #     def code
  #       if error.is_a?(PublicError)
  #         error.code
  #       else
  #         :internal_server_error
  #       end
  #     end
  #   end
  #
  ExceptionRenderer = Struct.new(:env) do
    # @param responder [ExceptionResponder]
    # @return [String] error representation
    def render(responder)
      ActiveModelSerializers::SerializableResource.new(
        Array(error),
        each_serializer: error_serializer,
        adapter: :json,
        root: 'errors',
        meta: { 'status' => responder.status_code },
        scope: { http_status: responder.status_code, id: error_id },
      ).as_json.to_json
    end

    def error_serializer
      error.is_a?(PublicError) ? PublicErrorSerializer : ErrorSerializer
    end

    # @return [StandardError]
    def error
      env['action_dispatch.exception']
    end

    # @return [String] error identifier, UUID
    def error_id
      env['action_dispatch.request_id']
    end
  end
end
