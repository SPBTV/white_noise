# frozen_string_literal: true
require 'active_support/core_ext/hash/keys'
require 'noise'
require 'noise/exception_responder'
require 'support/fixtures'
require 'support/sleanup_notification'

RSpec.describe Noise::ExceptionResponder do
  let(:error_id) { SecureRandom.uuid }
  subject(:responder) { described_class.new(env) }

  before do
    Noise.config.bugsnag_project = 'spb-tv/rosing-api'
  end

  context 'PublicError' do
    let(:env) do
      {
        'action_dispatch.exception' => TestError.new(:bad_request, 'unknown error'),
        'action_dispatch.request_id' => error_id,
      }
    end

    describe '#status_code' do
      subject(:http_code) { responder.status_code }
      it { is_expected.to eq 400 }
    end

    describe '#headers' do
      subject(:headers) { responder.headers.deep_stringify_keys }

      it 'default headers' do
        expect(headers).to include(
          'Content-Type' => 'application/json; charset=utf-8',
          'Content-Length' => '336',
        )
      end
    end

    describe '#body' do
      subject(:body) { JSON.parse(responder.body).deep_stringify_keys }

      it 'serializes errors to response body' do
        is_expected.to eq(
          'errors' => [
            {
              'id' => error_id,
              'code' => 'bad_request',
              'links' => {
                'about' => {
                  'href' => "https://app.bugsnag.com/spb-tv%2Frosing-api/errors?filters[event.since][]=30d&filters[user.name][]=#{error_id}", # rubocop:disable Metrics/LineLength
                },
              },
              'object' => 'error',
              'title' => 'unknown error',
              'fallback_message' => nil,
            },
          ],
          'meta' => {
            'status' => 400,
          },
        )
      end
    end
  end

  context 'not PublicError' do
    let(:env) do
      {
        'action_dispatch.exception' => StandardError.new('unknown error'),
        'action_dispatch.request_id' => error_id,
      }
    end

    describe '#status_code' do
      subject(:http_code) { responder.status_code }
      it { is_expected.to eq 500 }
    end

    describe '#headers' do
      subject(:headers) { responder.headers.deep_stringify_keys }

      it 'default headers' do
        expect(headers).to include(
          'Content-Type' => 'application/json; charset=utf-8',
          'Content-Length' => '354',
         )
      end
    end

    describe '#body' do
      subject(:body) { JSON.parse(responder.body).deep_stringify_keys }

      it 'serializes errors to response body' do
        is_expected.to eq(
          'errors' => [
            {
              'id' => error_id,
              'code' => 'internal_server_error',
              'links' => {
                'about' => {
                  'href' => "https://app.bugsnag.com/spb-tv%2Frosing-api/errors?filters[event.since][]=30d&filters[user.name][]=#{error_id}", # rubocop:disable Metrics/LineLength
                },
              },
              'object' => 'error',
              'title' => 'Internal Server Error',
              'fallback_message' => nil,
            },
          ],
          'meta' => {
            'status' => 500,
          },
       )
      end
    end
  end
end
