# frozen_string_literal: true
require 'active_support/core_ext/string'
require 'noise/version'
require 'noise/public_error'
require 'noise/rate_limit_error'
require 'active_support/configurable'

#
module Noise
  include ActiveSupport::Configurable
  extend ActiveSupport::Autoload

  autoload :ErrorSerializer
  autoload :ExceptionRenderer
  autoload :PublicErrorSerializer

  config.bugsnag_enabled = true
  config.bugsnag_organization = nil
  config.bugsnag_project = nil
  config.exception_renderer = ExceptionRenderer
end
