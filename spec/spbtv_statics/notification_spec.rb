require 'spbtv_statics/notification'
require 'spbtv_statics/public_error'
require 'support/fixtures'

RSpec.describe SpbtvStatics::Notification do
  around do |example|
    severities = described_class.severities.dup
    example.run
    described_class.severities = severities
  end

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

  let(:env) do
    {
      'HTTP_X_FORWARDED_FOR' => '66.66.66.66'
    }
  end
  let(:error_class) { TestError }

  before do
    described_class.register(TestError, severity: SpbtvStatics::Notification::WARNING)
  end

  let(:notification) { described_class.new(error_class.new, env) }

  describe '#severity' do
    subject { notification.severity }

    context 'for registered error' do
      it { is_expected.to eq(SpbtvStatics::Notification::WARNING) }
    end

    context 'for not registered error' do
      let(:error_class) { ArgumentError }

      it { is_expected.to eq(SpbtvStatics::Notification::ERROR) }
    end
  end

  describe '#to_hash' do
    let(:extractor_class) do
      Class.new do
        def call(env)
          env['HTTP_X_FORWARDED_FOR']
        end
      end
    end

    before do
      described_class.extract(:user, extractor_class)
    end

    subject { notification.to_hash }

    it 'contains extracted data' do
      is_expected.to eq('user' => '66.66.66.66')
    end
  end
end
