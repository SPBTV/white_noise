require 'spbtv_statics/exceptions_app'
require 'support/fixtures'
require 'support/sleanup_notification'

RSpec.describe SpbtvStatics::ExceptionsApp do
  let(:content_type) { Mime::JSON }
  let(:exception) { TestError.new(:bad_request, 'unknown error') }
  let(:env) { { 'action_dispatch.exception' => exception } }

  before do
    SpbtvStatics.config.bugsnag_project = 'spb-tv/rosing-api'
  end

  subject(:response) { described_class.new.call(env) }

  describe 'http status code' do
    subject(:http_code) { response[0] }
    it { is_expected.to eq 400 }
  end

  describe 'body' do
    subject(:body) { JSON.parse(response[2][0], symbolize_names: true) }

    let(:serialized_error) do
      {
        errors: [
          {
            code: 'bad_request',
            links: {
              about: {
                href: 'https://bugsnag.com/spb-tv%2Frosing-api/errors?filters[event.since][]=30d&filters[error.status][]=open&filters[event.message][]=unknown%20error&filters[event.class][]=TestError'
              }
            },
            object: 'error',
            title: 'unknown error',
            fallback_message: nil
          }
        ],
        meta: {
          status: 400
        }
      }
    end

    it { is_expected.to eq serialized_error }
  end
end
