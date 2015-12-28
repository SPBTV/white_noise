require 'noise/notification'
require 'support/fixtures'
require 'support/sleanup_notification'

RSpec.describe Noise::Notification do
  describe '.register' do
    let(:severity) { described_class::ERROR }

    def register_error
      described_class.register(TestError, severity: severity)
    end

    context 'with wrong severity' do
      let(:severity) { 'some' }
      it 'fails' do
        expect { register_error }.to raise_error(ArgumentError, /Wrong severity/)
      end
    end

    context 'with error class' do
      it 'registers error' do
        register_error
        expect(described_class.severities['TestError']).to eq severity
      end
    end

    context 'with error name' do
      let(:error) { error_class.name }
      it 'registers error' do
        register_error
        expect(described_class.severities['TestError']).to eq severity
      end
    end
  end

  describe '.extract' do
    let(:user_extractor) { double('user extractor') }

    subject { described_class.extractors }
    it 'register extractor' do
      described_class.extract(:user, user_extractor)

      is_expected.to include(user: user_extractor)
    end
  end

  let(:ip_address) { '66.66.66.66' }
  let(:env) do
    {
      'HTTP_X_FORWARDED_FOR' => ip_address,
      'client_id' => 'android',
      'client_version' => '1.0.0',
      'user_name' => 'Papadopoulos'
    }
  end

  let(:error_class) { TestError }

  before do
    described_class.register(TestError, severity: Noise::Notification::WARNING)
  end

  let(:notification) { described_class.new(error_class.new(:error), env) }

  describe '#severity' do
    subject { notification.severity }

    context 'for registered error' do
      it { is_expected.to eq('warning') }
    end

    context 'for not registered error' do
      let(:error_class) { ArgumentError }

      it { is_expected.to eq('error') }
    end
  end

  describe '#to_hash' do
    before do
      described_class.extract(:api_client, ApiClientExtractor)
      described_class.extract(:user, UserExtractor)
    end

    subject { notification.to_hash }

    it 'contains extracted data' do
      is_expected.to eq('api_client' => { 'client_id' => 'android', 'client_version' => '1.0.0' })
      is_expected.not_to have_key('user')
    end
  end

  describe '#user_info' do
    before do
      described_class.extract(:user, UserExtractor)
    end

    subject { notification.user_info }

    it 'contains extracted data and id' do
      is_expected.to eq('id' => '66.66.66.66', 'name' => 'Papadopoulos')
    end
  end
end
