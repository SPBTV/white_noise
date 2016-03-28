require 'noise/notification'
require 'noise/exception_responder'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'
require 'i18n'

#
module Noise
  # Base class for all api level errors
  #
  class PublicError < StandardError
    attr_reader :message_id
    attr_reader :options

    # @overload new(message_id, message)
    #   Instantiate error with given message_id and message
    #   @param message_id [Symbol]
    #   @param message_or_options [String]
    # @overload new(message_id, options)
    #   Instantiate error with given message_id and options.
    #   Options would be passed to I18n key
    #   @param message_id [Symbol]
    #   @param message_or_options [Hash{Symbol => any}]
    #   @example
    #     Given the following I18n key exists:
    #       noise:
    #         public_error:
    #           unknown_fields: "Server does not know how to recognize these fields: %{fields}"
    #
    #     To render error with this message:
    #       PublicError.new(:unknown_fields, fields: 'nickname, phone')
    #
    def initialize(message_id, message_or_options = nil)
      @message_id = message_id.to_sym
      case message_or_options
      when Hash
        @options = message_or_options
        @message = nil
      else
        @options = {}
        @message = message_or_options
      end
    end

    # @return [String]
    def message
      @message.presence || I18n.t("noise.#{self.class.name.demodulize.underscore}.#{@message_id}", @options)
    end

    # @return [String]
    def inspect
      "#<#{self.class}: #{message}>"
    end

    # @return [ExceptionResponder]
    def responder
      ExceptionResponder.new(self)
    end

    class << self
      # @param status [Symbol, Integer]
      #   @see http://apidock.com/rails/ActionController/Base/render#254-List-of-status-codes-and-their-symbols
      # @param severity [Symbol, Integer]
      #   @see `Noise::Notification::SEVERITIES`
      #
      # @example
      #   GoneError.register_as(:gone, :info)
      #
      def register_as(status, severity:)
        Noise::ExceptionResponder.register(name, status: status)
        Noise::Notification.register(name, severity: severity)
      end
    end
  end

  # 400
  BadRequestError = Class.new(PublicError)
  BadRequestError.register_as :bad_request, severity: :info

  # 401
  UnauthorizedError = Class.new(PublicError)
  UnauthorizedError.register_as :unauthorized, severity: :warning

  # 403
  ForbiddenError = Class.new(PublicError)
  ForbiddenError.register_as :forbidden, severity: :warning

  # 404
  class NotFoundError < PublicError
    def initialize(message_id = 'not_found', message = nil)
      super
    end
  end
  NotFoundError.register_as :not_found, severity: :info

  # 410
  GoneError = Class.new(PublicError)
  GoneError.register_as :gone, severity: :info

  # 415
  class UnsupportedMediaTypeError < PublicError
    def initialize(message_id = 'unsupported_media_type', message = nil)
      super
    end
  end
  UnsupportedMediaTypeError.register_as :unsupported_media_type, severity: :info

  # 422
  class UnprocessableEntityError < PublicError
    def initialize(message_id = :unprocessable_entity, message = nil)
      super
    end
  end
  UnprocessableEntityError.register_as :unprocessable_entity, severity: :info
end
