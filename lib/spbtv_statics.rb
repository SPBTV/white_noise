require 'spbtv_statics/version'
require 'spbtv_statics/public_error'
require 'active_support/configurable'

#
module SpbtvStatics
  include ActiveSupport::Configurable

  config.bugsnag_enabled = true
  config.bugsnag_project = nil
end
