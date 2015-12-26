require 'rails/railtie'
require 'spbtv_statics'

module SpbtvStatics
  # Rails initializers
  class Railtie < Rails::Railtie
    initializer 'spbtv_statics.exceptions_app' do
      require 'spbtv_statics/exceptions_app'

      Rails.application.config.exceptions_app = SpbtvStatics::ExceptionsApp.new
    end

    initializer 'spbtv_statics.bugsnag' do
      if SpbtvStatics.config.bugsnag_enabled
        require 'spbtv_statics/bugsnag_middleware'

        Bugsnag.configure do |config|
          config.middleware.use SpbtvStatics::BugsnagMiddleware
        end
      end
    end
  end
end
