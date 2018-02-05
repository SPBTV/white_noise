# frozen_string_literal: true
require_relative 'notification'

module Noise
  # Configures Bugsnag notification with our request-specific information.
  #
  class BugsnagMiddleware
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    # @param report [Bugsnag::Report]
    #
    def call(report)
      env = report.request_data.fetch(:rack_env, {})
      # Bugsnag::Notification unwraps stacked exceptions,
      # top-level exception (which we need) is the first.
      error = report.exceptions.first
      notification = Notification.new(error, env)

      report.severity = notification.severity
      report.user = notification.user_info

      notification.to_hash.each_pair do |tab_name, value|
        report.add_tab(tab_name, value)
      end

      @bugsnag.call(report)
    end
  end
end
