# frozen_string_literal: true
require 'noise/public_error'
require 'active_support/core_ext/hash/slice'

TestError = Class.new(Noise::PublicError)
TestError.register_as(:bad_request, severity: :info)

SomethingNotFoundError = Class.new(StandardError)
ActionDispatch::ExceptionWrapper.rescue_responses['SomethingNotFoundError'] = :bad_request

class ApiClientExtractor
  def call(env)
    env.slice('client_id', 'client_version')
  end
end

class UserExtractor
  def call(env)
    {
      'name' => env['user_name']
    }
  end
end
