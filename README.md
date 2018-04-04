# White Noise

[![Build Status](https://travis-ci.org/SPBTV/white_noise.svg?branch=master)](https://travis-ci.org/SPBTV/white_noise)
[![Gem Version](https://badge.fury.io/rb/white_noise.svg)](https://badge.fury.io/rb/white_noise)

![TV Statics](https://habrastorage.org/files/6ca/008/f52/6ca008f5290043daa94f705da21b6c6a.jpg)

This gem defines middleware which renders exceptions in JSON format and notifies [Bugsnag](http://bugsnag.com).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'white_noise', require: 'noise/railtie'
```

## Usage

Exception subclasses from `PublicError` may be registered and rendered as specific HTTP errors:

```ruby
GoneError = Class.new(PublicError)
GoneError.register_as :gone, severity: :info
```

Later somewhere in controller you may throw this exception:

```ruby
class V0::MoviesController < ApiController
  # @deprecated
  def index
    fail GoneError.new(:outdated_api, 'API v0 is no longer active. Please migrate to API v1')
  end
end
```

By default this error would be rendered in JSON-API like format internally used in SPB TV, but you can always define your own renderer:


```json
Status: 410 Gone

{
  "errors": [{
    "id": "b55eacaf-c3db-4c5c-80c6-214149eb14c2",
    "code": "outdated_api",
    "title": "API v0 is no longer active. Please migrate to API v1",
    "status": 410,
     links: {
       about: {
         href: 'https://bugsnag.com/spb-tv%2Frosing-api/errors?filters[event.since][]=30d&filters[error.status][]=open&filters[event.message][]=unknown%20error&filters[event.class][]=OutdatedApiError'
       }
     },
    "
  }],
  "meta": {
    "status": 410
  }
}
```

Thus, the first parameter of the `PublicError` constructor is rendered as `code` and the second as `title`.

You may omit second argument to pick message from localization:

```ruby
fail GoneError, :outdated_api
```

It is the equivalent of:

```ruby
fail GoneError.new(:outdated_api, I18n.t('noise.outdated_api_error.outdated_api'))
```

If you have to pass attributes some substitution into localized string, provide the second attribute as a hash:

```ruby
fail BadRequestError.new(:unknown_fields, fields: 'nickname, phone')
```

```yaml
noise:
  bad_request_error:
    unknown_fields: "Server does not know how to recognize these fields: %{fields}"
```

There are number of predefined public errors you can use in your application:

Class                      | HTTP status code
---------------------------|------------------------------
`BadRequestError`          | 400 Bad Request
`UnauthorizedError`        | 401 Unauthorized
`ForbiddenError`           | 403 Forbidden
`NotFoundError`            | 404 Not Found
`GoneError`                | 410 Gone
`UnsupportedMediaTypeError`| 415 Unsupported Media Type
`UnprocessableEntityError` | 422 Unprocessable Entity

## Bugsnag Notification

This gem notifies Bugsnag about all errors. You are free to adjust severity of errors on per class basis:

```ruby
GoneError.register_as :gone, severity: :info
```

You can customize tabs to be shown on Bugsnag:

![Tab example](https://habrastorage.org/files/bd4/290/75c/bd429075c2604eeaa7ef39ae75fbffe2.png)

```ruby
Noise::Notification.extract(:api_client, ApiClientExtractor)

class ApiClientExtractor
  # @param env [Hash]
  # @return [Hash] of values to be shown on the tab
  #
  def call(env)
    api_client = env['warden'].user(:api_client)
    if api_client
      {
        id: api_client.id,
        name: api_client.name,
        version: api_client.version.to_s
      }
    else
      {}
    end
  end
end
```

If you want to show link to Bugsnag error page on the error response, you have to configure Bugsnag project:

```ruby
Noise.config.bugsnag_organization = 'spb-tv'
Noise.config.bugsnag_project = 'rosing-api'
```

To disable Bugsnag integration:

```ruby
Noise.config.bugsnag_enabled = false
```

Override error response format:

```ruby
class ApplicationRenderer < ExceptionRenderer
  def render(responder)
    {
      meta: {
        code: responder.status_code,
        error_id: error_id,
        error_description: error.message
      }
    }
  end
end
Rails.application.config.exceptions_app = Noise::ExceptionsApp.new(->(env) { ApplicationRenderer.new(env) })
```

## Best Practices

It is strongly encouraged to throw public errors only in controllers. Your domain logic should throw domain-specific exceptions
or better be exceptions-free.

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version,
update the version number in `lib/noise/version.rb`, and then run `bundle exec rake release`, which will create a git
tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SPBTV/white_noise.

## License

Copyright 2018 SPB TV AG

Licensed under the Apache License, Version 2.0 (the ["License"](LICENSE)); you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.

