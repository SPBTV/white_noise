# frozen_string_literal: true
require 'noise/public_error'

RSpec.describe Noise::PublicError do
  before(:all) do
    I18n.backend.store_translations(:en,
                                    noise: {
                                      public_error: {
                                        message_without_options: 'bar',
                                        message_with_options: 'Opts: %{foo}, %{bar}',
                                      },
                                    },
                                   )
  end

  context 'when only code given' do
    subject { described_class.new(:message_without_options).message }

    it 'fetch message from localization' do
      is_expected.to eq('bar')
    end
  end

  context 'when code and message given' do
    subject { described_class.new(:message_without_options, 'baz').message }

    it 'fetch message initializer' do
      is_expected.to eq('baz')
    end
  end

  context 'when code and message options given' do
    subject { described_class.new(:message_with_options, foo: 1, bar: 2).message }

    it 'fetch message from localization' do
      is_expected.to eq('Opts: 1, 2')
    end
  end
end
