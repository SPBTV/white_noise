require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/hash/except'
require 'active_support/hash_with_indifferent_access'
require 'active_support/concern'
require 'action_dispatch/http/request'

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
      #   class ApiClientExtractor
      #     def call(env)
      #       env.slice(:client_version, :client_id)
      #     end
      #   end
      #   Notification.extract(:api_client, ApiClientExtractor)
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
      extractors.except('user').each_with_object({}) do |(key, extractor), metadata|
        metadata[key] = extractor.new.call(@env)
      end
    end

    # @return [String] Error severity
    def severity
      severities[@error.class.name].to_s
    end

    # @return [Hash] User info
    def user_info
      user = {
        'id' => ActionDispatch::Request.new(@env).remote_ip
      }

      if extractors.key?('user')
        user.merge!(extractors['user'].new.call(@env))
      end
      user
    end
  end
end
