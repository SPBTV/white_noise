require 'active_support/core_ext/hash/keys'
require 'spbtv_statics/exception_responder'
require 'support/fixtures'
require 'support/sleanup_notification'

RSpec.describe SpbtvStatics::ExceptionResponder do
  let(:error) { TestError.new(:bad_request, 'unknown error') }

  before do
    TestError.register_as(:bad_request, severity: :info)
  end

  subject(:responder) { described_class.new(error) }

  describe '#status_code' do
    subject(:http_code) { responder.status_code }
    it { is_expected.to eq 400 }
  end

  describe '#body' do
    subject(:body) { responder.body.deep_stringify_keys }

    let(:serialized_error) do
      {
        errors: [
          {
            code: :bad_request,
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

    before do
      SpbtvStatics::PublicErrorSerializer.bugsnag_project = 'spb-tv/rosing-api'
    end

    it 'serializes errors to response body' do
      is_expected.to eq serialized_error.deep_stringify_keys
    end
  end
end
