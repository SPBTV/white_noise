# frozen_string_literal: true
require 'rack/utils'
require 'active_model_serializers'

module Noise
  # Generic error serializer
  class ErrorSerializer < ActiveModel::Serializer
    BUGSNAG_URL =
      'https://app.bugsnag.com/{organization}/{project}/errors?filters[event.since][]=30d&filters[user.name][]={id}'

    attributes(
      :id,
      :code,
      :links,
      :title,
      :fallback_message,
    )

    def attributes(*)
      data = super
      data['object'] = 'error'
      data
    end

    def id
      scope.try(:[], :id)
    end

    def code
      code_from_http_status
    end

    def title
      'Internal Server Error'
    end

    def links
      {
        'about' => {
          'href' => bugsnag_search_url.to_s,
        },
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
      return unless Noise.config.bugsnag_project
      return unless id
      require 'addressable/template'

      template = Addressable::Template.new(BUGSNAG_URL)
      template.expand(id: id, organization: Noise.config.bugsnag_organization, project: Noise.config.bugsnag_project)
    end
  end
end
