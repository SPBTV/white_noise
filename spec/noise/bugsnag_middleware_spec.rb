# frozen_string_literal: true
require 'bugsnag'
require 'noise/bugsnag_middleware'
require 'support/fixtures'
require 'support/sleanup_notification'

RSpec.describe Noise::BugsnagMiddleware do
  subject(:middleware) { ->(bugsnag) { described_class.new(bugsnag.to_proc).call(bugsnag_notification) } }
  let(:bugsnag_notification) { Bugsnag::Notification.new(error, Bugsnag::Configuration.new) }
  let(:error) { RuntimeError.new('oops') }

  before do
    Noise::Notification.extract(:user, UserExtractor)
    Noise::Notification.extract(:api_client, ApiClientExtractor)
  end

  context 'rack env is present' do
    around do |e|
      Bugsnag.configuration.set_request_data(:rack_env, env)
      e.run
      Bugsnag.configuration.clear_request_data
    end
    let(:env) do
      {
        'HTTP_X_FORWARDED_FOR' => ip_address,
        'client_id' => 'android',
        'client_version' => '1.0.0',
        'user_email' => 'papadopoulos@example.com',
        'action_dispatch.request_id' => request_id,
      }
    end
    let(:ip_address) { '66.66.66.66' }
    let(:request_id) { SecureRandom.uuid }

    it 'adds information to bugsnag notification' do
      is_expected.to yield_with_args(
        have_attributes(
          user: {
            'email' => 'papadopoulos@example.com',
            'name' => request_id,
          },
          meta_data: include(api_client: { 'client_id' => 'android', 'client_version' => '1.0.0' }),
          severity: 'error',
        ),
      )
    end
  end

  context 'rack env is not present' do
    it do
      is_expected.to yield_with_args(
        have_attributes(
          user: {},
          meta_data: include(api_client: {}),
          severity: 'error',
        ),
      )
    end
  end
end
