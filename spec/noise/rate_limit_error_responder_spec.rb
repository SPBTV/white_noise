# frozen_string_literal: true
require 'active_support/core_ext/hash/keys'
require 'noise'
require 'noise/rate_limit_error'
require 'noise/rate_limit_error_responder'

RSpec.describe Noise::RateLimitErrorResponder do
  let(:error) { Noise::RateLimitError.new(:too_many_requests, retry_after: 10) }
  let(:env) do
    {
      'action_dispatch.exception' => error,
    }
  end
  subject(:responder) { described_class.new(env) }

  describe '#status_code' do
    subject(:http_code) { responder.status_code }
    it { is_expected.to eq 429 }
  end

  describe '#headers' do
    subject(:headers) { responder.headers.deep_stringify_keys }

    it 'default headers' do
      expect(headers).to include(
        'Retry-After' => '10',
      )
    end
  end
end
