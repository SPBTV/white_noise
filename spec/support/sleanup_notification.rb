# frozen_string_literal: true
require 'noise/notification'

RSpec.configure do |config|
  config.around do |example|
    severities = Noise::Notification.severities.dup
    extractors = Noise::Notification.extractors.dup
    example.run
    Noise::Notification.severities = severities
    Noise::Notification.extractors = extractors
  end
end
