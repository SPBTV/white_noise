require 'spbtv_statics/notification'

RSpec.configure do |config|
  config.around do |example|
    severities = SpbtvStatics::Notification.severities.dup
    extractors = SpbtvStatics::Notification.extractors.dup
    example.run
    SpbtvStatics::Notification.severities = severities
    SpbtvStatics::Notification.extractors = extractors
  end
end
