# frozen_string_literal: true
require 'noise'
require 'noise/exceptions_app'
require 'support/fixtures'
require 'support/sleanup_notification'

RSpec.describe Noise::ExceptionsApp do
  let(:content_type) { Mime::JSON }
  let(:env) { { 'action_dispatch.exception' => exception } }
  let(:error_message) { 'unknown_error' }
  let(:serialized_error) do
    {
      errors: [
        {
          code: 'bad_request',
          links: {
            about: {
              href: "https://bugsnag.com/spb-tv%2Frosing-api/errors?filters[event.since][]=30d&filters[error.status][]=open&filters[event.message][]=#{error_message}&filters[event.class][]=#{exception.class.name}"
            }
          },
          object: 'error',
          title: error_message,
          fallback_message: nil
        }
      ],
      meta: {
        status: 400
      }
    }
  end

  before do
    Noise.config.bugsnag_project = 'spb-tv/rosing-api'
  end

  subject(:response) { described_class.new.call(env) }

  context 'PublicError' do
    let(:exception) { TestError.new(:bad_request, error_message) }

    describe 'http status code' do
      subject(:http_code) { response[0] }
      it { is_expected.to eq 400 }
    end

    describe 'body' do
      subject(:body) { JSON.parse(response[2][0], symbolize_names: true) }

      it { is_expected.to eq serialized_error }
    end
  end

  context 'exception manually registered at ActionDispatch::ExceptionWrapper' do
    let(:exception) { SomethingNotFoundError.new(error_message) }

    describe 'http status code' do
      subject(:http_code) { response[0] }
      it { is_expected.to eq 400 }
    end

    describe 'body' do
      subject(:body) { JSON.parse(response[2][0], symbolize_names: true) }

      it { is_expected.to eq serialized_error }
    end
  end
end
