# SpbtvStatics

![TV Statics](https://habrastorage.org/files/6ca/008/f52/6ca008f5290043daa94f705da21b6c6a.jpg)

This gem defines middleware which renders exceptions in [standard SPB TV API style format](http://doc.dev.spbtv.com/rosing/client_api_overview.html#errors)
and notifies [Bugsnag](http://bugsnag.com).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'spbtv_statics', require: 'spbtv_statics/railtie'
```

## Usage

Exception subleased from `PublicError` may be registered and rendered as specific HTTP errors:

```ruby
OutdatedApiError = Class.new(PublicError)
OutdatedApiError.register_as :gone, severity: :info
```

Later somewhere in controller you may throw this exception:

```ruby
class V0::MoviesController < ApiController
  # @deprecated
  def index
    fail OutdatedApiError.new(:outdated_api, 'API v0 is no longer active. Please migrate to API v1'
  end
end
```

By default this error would be rendered in [standard SPB TV API style](http://doc.dev.spbtv.com/rosing/client_api_overview.html#errors):


```json
Status: 410 Gone

{
  "errors": [{
    "id": null,
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
fail OutdatedApiError, :outdated_api
```

It is the equivalent of:

```ruby
fail OutdatedApiError.new(:outdated_api, I18n.t('spbtv_statics.outdated_api_error.outdated_api'))
```

If you have to pass attributes some substitution into localized string, provide the second attribute as a hash:

```ruby
fail BadRequestError.new(:unknown_fields, fields: 'nickname, phone')
```

```yaml
spbtv_statics:
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

It is allowed to have subclasses of predefined errors:

```ruby
OutdatedApiError = Class.new(GoneError)
```

## Bugsnag Notification

This gem notifies Bugsnag about all errors. You are free to adjust severity of errors on per class basis:

```ruby
OutdatedApiError.register_as :gone, severity: :info
```

You can customize tabs to be shown on Bugsnag:

![Tab example](https://habrastorage.org/files/bd4/290/75c/bd429075c2604eeaa7ef39ae75fbffe2.png)

```ruby
SpbtvStatics::Notification.extract(:api_client, ApiClientExtractor)

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
SpbtvStatics.config.bugsnag_project = 'spb-tv/rosing-api'
```

To disable Bugsnag integration:

```ruby
SpbtvStatics.config.bugsnag_enabled = false
```

Override error response format:

```ruby
SpbtvStatics::ExceptionResponder.renderer = lambda do |error, status_code|
  {
    meta: {
      code: status_code,
      error_id: error.message_id,
      error_description: error.message
    }
  }
end
```

## Best Practices

It is strongly encouraged to throw public errors only in controllers. Your domain logic should throw domain-specific exceptions
or better be exceptions-free.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/spbtv_exceptions.

