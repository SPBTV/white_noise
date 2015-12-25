require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'
require 'i18n'

module SpbtvStatics
  # Base class for all api level errors
  #
  class PublicError < StandardError
    attr_reader :message_id
    attr_reader :message_options

    # @overload new(message_id, message)
    #   Instantiate error with given message_id and message
    #   @param message_id [Symbol]
    #   @param message [String]
    # @overload new(message_id, options)
    #   Instantiate error with given message_id and options.
    #   Options would be passed to I18n key
    #   @param message_id [Symbol]
    #   @param message [Hash{Symbol => any}]
    #   @example
    #     Given the following I18n key exists:
    #       spbtv_statics:
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
        @message_options = message_or_options
        @message = nil
      else
        @message_options = {}
        @message = message_or_options
      end
    end

    # @return [String]
    def message
      @message.presence || I18n.t("spbtv_statics.#{self.class.name.demodulize.underscore}.#{@message_id}", message_options)
    end

    # @return [String]
    def inspect
      "#<#{self.class}: #{message}>"
    end

    class << self
      # @param status [Symbol, Integer]
      #   @see http://apidock.com/rails/ActionController/Base/render#254-List-of-status-codes-and-their-symbols
      # @param severity [Symbol, Integer]
      #   @see `SpbtvStatics::Notification::SEVERITIES`
      #
      # @example
      #   GoneError.register_as(:gone, :info)
      #
      def register_as(status, severity:)
        ExceptionResponder.register(name, status: status)
        SpbtvStatics::Notification.register(name, severity: severity)
      end
    end
  end
end
