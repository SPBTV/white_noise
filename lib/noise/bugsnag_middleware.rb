require_relative 'notification'

module Noise
  # Configures Bugsnag notification with our request-specific information.
  #
  class BugsnagMiddleware
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    # @param bugsnag_notification [Bugsnag::Notification]
    #
    def call(bugsnag_notification)
      env = bugsnag_notification.request_data.fetch(:rack_env, {})
      # Bugsnag::Notification unwraps stacked exceptions,
      # top-level exception (which we need) is the first.
      error = bugsnag_notification.exceptions.first
      notification = Notification.new(error, env)

      bugsnag_notification.severity = notification.severity
      bugsnag_notification.user = notification.user_info

      notification.to_hash.each_pair do |tab_name, value|
        bugsnag_notification.add_tab(tab_name, value)
      end

      @bugsnag.call(bugsnag_notification)
    end
  end
end
