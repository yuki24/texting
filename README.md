# Texting [![Build Status](https://travis-ci.org/yuki24/texting.svg?branch=master)](https://travis-ci.org/yuki24/texting)

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

Texxting itself doesn't send text messages. Instead, it uses an adapter to actually send them. As of writing, Texting only have support for Twilio and AWS SNS:

```ruby
# Use Twilio:
gem 'twilio-ruby'

# Use AWS SNS:
gem 'aws-sdk-sns'
```

Support for more providers will be added in the future.

### Writing your first messenger:


```ruby
# app/messengers/tweet_messenger.rb
class TweetMessenger < ApplicationMessenger
  def new_direct_message(message_id, user_id)
    message = DirectMessage.find(message_id)
    user    = User.find(user_id)

    text to: user.phone_number, body: <<~BODY.strip
      Your follower #{user.name} juts sent you a direct message:

      #{message.body}
    BODY
  end
end
```

### Deliver the text messages:

```ruby
TweetMessenger.new_direct_message(message_id, user.id).deliver_now!
# => sends a text message immediately

TweetMessenger.new_direct_message(message_id, user.id).deliver_later!
# => enqueues a job that sends a text message later
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).