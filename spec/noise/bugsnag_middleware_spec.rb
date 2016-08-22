# frozen_string_literal: true
require 'bugsnag'
require 'noise/bugsnag_middleware'
require 'support/fixtures'
require 'support/sleanup_notification'

RSpec.describe Noise::BugsnagMiddleware do
  let(:bugsnag) { double('bugsnag') }
  let(:ip_address) { '66.66.66.66' }
  let(:request_id) { SecureRandom.uuid }
  let(:env) do
    {
      'HTTP_X_FORWARDED_FOR' => ip_address,
      'client_id' => 'android',
      'client_version' => '1.0.0',
      'user_email' => 'papadopoulos@example.com',
      'action_dispatch.request_id' => request_id,
    }
  end
  let(:error) { RuntimeError.new('oops') }
  let(:bugsnag_notification) { Bugsnag::Notification.new(error, Bugsnag::Configuration.new) }
  before { bugsnag_notification.request_data[:rack_env] = env }

  subject(:middleware) { described_class.new(bugsnag) }

  before do
    Noise::Notification.extract(:user, UserExtractor)
    Noise::Notification.extract(:api_client, ApiClientExtractor)
  end

  it 'adds information to bugsnag notification' do
    expect(bugsnag).to receive(:call) do |notification|
      expect(notification.user).to eq(
        'id' => '66.66.66.66',
        'email' => 'papadopoulos@example.com',
        'name' => request_id,
      )
      expect(notification.meta_data[:api_client]).to eq('client_id' => 'android', 'client_version' => '1.0.0')
      expect(notification.severity).to eq('error')
    end
    middleware.call(bugsnag_notification)
  end
end
