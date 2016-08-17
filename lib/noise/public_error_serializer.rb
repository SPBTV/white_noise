# frozen_string_literal: true

module Noise
  # Errors api representation.
  # Serializes api level errors to general errors format.
  #
  class PublicErrorSerializer < ErrorSerializer
    def code
      object.message_id
    end

    def title
      object.message
    end
  end
end
