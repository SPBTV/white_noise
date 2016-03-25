require 'noise/version'
require 'noise/public_error'
require 'noise/rate_limit_error'
require 'active_support/configurable'

#
module Noise
  include ActiveSupport::Configurable

  config.bugsnag_enabled = true
  config.bugsnag_project = nil
end
