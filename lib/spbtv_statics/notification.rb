require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/hash_with_indifferent_access'

module SpbtvStatics
  # Provides detailed information about exception
  # and request context.
  #
  class Notification
    WARNING = :warning
    INFO = :info
    ERROR = :error
    SEVERITIES = [WARNING, INFO, ERROR]

    cattr_accessor :severities, instance_writer: false
    self.severities = Hash.new(ERROR)
    severities.merge!('ActiveRecord::RecordNotFound' => INFO)

    cattr_accessor :extractors, instance_writer: false
    self.extractors = HashWithIndifferentAccess.new

    class << self
      # @param error_class [Class<StandardError>, String]
      # @param severity [Symbol] severity constant
      def register(error_class, severity:)
        if SEVERITIES.include?(severity)
          severities[error_class.to_s] = severity
        else
          fail ArgumentError, "Wrong severity `#{severity}`, allowed: #{SEVERITIES}"
        end
      end

      # Extract info from request and it to Bugsnag notification
      # @param key [Symbol, String] name of the parameter
      # @param extractor [#call]
      # @return [void]
      #
      #   class UserExtractor
      #     def call(env)
      #       ActionDispatch::Request.new(env).ip_address
      #     end
      #   end
      #   Notification.extract(:user, UserExtractor)
      #
      def extract(key, extractor)
        extractors[key] = extractor
      end
    end

    # @param error [StandardError]
    # @param env [Hash] rack env
    #   @see http://www.rubydoc.info/github/rack/rack/master/file/SPEC
    #
    def initialize(error, env)
      @error = error
      @env = env
    end

    # @return [{String, Any}]
    def to_hash
      extractors.each_with_object({}) do |(key, extractor), metadata|
        metadata[key] = extractor.new.call(@env)
      end
    end

    # @return [Symbol] Error severity
    def severity
      severities[@error.class.name]
    end
  end
end
