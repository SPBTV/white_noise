require 'rack/utils'
require 'active_model_serializers'

module SpbtvStatics
  # Errors api representation.
  # Serializes api level errors to general errors format.
  #
  class PublicErrorSerializer < ActiveModel::Serializer
    BUGSNAG_URL = 'https://bugsnag.com/{project}/errors?filters[event.since][]=30d&filters[error.status][]=open&filters[event.message][]={message}&filters[event.class][]={class}' # rubocop:disable Metrics/LineLength
    cattr_accessor :bugsnag_project, instance_writer: false

    attributes :code,
               :links,
               :title,
               :fallback_message

    def attributes(*)
      data = super
      data['object'] = 'error'
      data
    end

    def code
      if object.respond_to?(:message_id)
        object.message_id
      else
        code_from_http_status
      end
    end

    def title
      object.message
    end

    def links
      {
        'about' => {
          'href' => bugsnag_search_url.to_s
        }
      }
    end

    def fallback_message
      nil
    end

    private

    def code_from_http_status
      http_status = scope.try(:[], :http_status).to_i
      default_message = Rack::Utils::HTTP_STATUS_CODES[500]
      status_code = Rack::Utils::HTTP_STATUS_CODES.fetch(http_status, default_message)
      status_code.parameterize.underscore.to_sym
    end

    def bugsnag_search_url
      return unless bugsnag_project
      require 'addressable/template'

      template = Addressable::Template.new(BUGSNAG_URL)
      template.expand(class: object.class.to_s, message: object.message, project: bugsnag_project)
    end
  end
end
