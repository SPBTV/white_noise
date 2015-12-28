require 'rails/railtie'
require 'noise'

module Noise
  # Rails initializers
  class Railtie < Rails::Railtie
    initializer 'noise.exceptions_app' do
      require 'noise/exceptions_app'

      Rails.application.config.exceptions_app = Noise::ExceptionsApp.new
    end

    initializer 'noise.bugsnag' do
      if Noise.config.bugsnag_enabled
        require 'noise/bugsnag_middleware'

        Bugsnag.configure do |config|
          config.middleware.use Noise::BugsnagMiddleware
        end
      end
    end
  end
end
