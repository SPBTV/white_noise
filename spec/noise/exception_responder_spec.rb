# frozen_string_literal: true
require 'active_support/core_ext/hash/keys'
require 'noise'
require 'noise/exception_responder'
require 'support/fixtures'
require 'support/sleanup_notification'

RSpec.describe Noise::ExceptionResponder do
  let(:error) { TestError.new(:bad_request, 'unknown error') }

  subject(:responder) { described_class.new(error) }

  describe '.[]' do
    let(:error) { error_class.new('something went wrong') }
    subject { described_class[error] }

    context 'for PublicError' do
      let(:error_responder) { double('Responder') }

      let(:error_class) do
        stubbed_responder = error_responder
        Class.new(Noise::PublicError) do
          define_method :responder do
            stubbed_responder
          end
        end
      end

      it 'takes responder from PublicError#responder' do
        is_expected.to eq(error_responder)
      end
    end

    context 'not PublicError' do
      let(:error_class) { StandardError }

      it 'wrap in ExceptionResponder' do
        is_expected.to eq(described_class.new(error))
      end
    end
  end

  describe '#status_code' do
    subject(:http_code) { responder.status_code }
    it { is_expected.to eq 400 }
  end

  describe '#body' do
    subject(:body) { JSON.parse(responder.body).deep_stringify_keys }

    let(:serialized_error) do
      {
        errors: [
          {
            id: nil,
            code: 'bad_request',
            links: {
              about: {
                href: '',
              },
            },
            object: 'error',
            title: 'unknown error',
            fallback_message: nil,
          },
        ],
        meta: {
          status: 400,
        },
      }
    end

    before do
      Noise.config.bugsnag_project = 'spb-tv/rosing-api'
    end

    it 'serializes errors to response body' do
      is_expected.to eq serialized_error.deep_stringify_keys
    end
  end

  describe '#headers' do
    subject(:headers) { responder.headers.deep_stringify_keys }

    it 'default headers' do
      expect(headers).to include(
        'Content-Type' => 'application/json; charset=utf-8',
        'Content-Length' => '162',
      )
    end
  end
end
