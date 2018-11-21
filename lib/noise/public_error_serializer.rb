# frozen_string_literal: true

module Noise
  # Errors api representation.
  # Serializes api level errors to general errors format.
  #
  class PublicErrorSerializer < ErrorSerializer
    delegate :code, to: :object

    def title
      object.message
    end
  end
end
