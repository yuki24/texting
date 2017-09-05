# Texting [![Build Status](https://travis-ci.org/yuki24/texting.svg?branch=master)](https://travis-ci.org/yuki24/texting.svg)

Texting is a SMS/MMS framework that implements interfaces similar to ActionMailer.

 * **Convention over Configuration**: Texting brings Convention over Configuration to your app for organizing your SMS/MMS implementations.
 * **Extremely Easy to Learn**: If you know how to use ActionMailer, you already know how to use Texting. Send text messages asynchronously with ActiveJob at no learning cost.
 * **Testability**: First-class support for testing SMS/MMS messages. No more hassle writing custom code or stubs/mocks for your tests.

**While this gem is actively maintained, it is still under heavy development.**

## Getting Started

Add this line to your application's Gemfile:

```ruby
gem 'texting'
```


### Supported Providers

Pushing itself doesn't send text messages. Instead, it uses an adapter to actually send them. As of writing, Texting only have support for Twilio:

```ruby
gem 'twilio-ruby'
```

Support for other providers will be added in the future.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).