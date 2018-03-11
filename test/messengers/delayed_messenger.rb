require "active_job/arguments"

class DelayedMessengerError < StandardError; end

class DelayedMessenger < Texting::Base
  cattr_accessor :last_error
  cattr_accessor :last_rescue_from_instance

  if ActiveSupport::VERSION::MAJOR > 4
    rescue_from DelayedMessengerError do |error|
      @@last_error = error
      @@last_rescue_from_instance = self
    end

    rescue_from ActiveJob::DeserializationError do |error|
      @@last_error = error
      @@last_rescue_from_instance = self
    end
  end

  def test_message(*)
    text to: '909-390-0003', body: 'Welcome!'
  end

  def test_raise(klass_name)
    raise klass_name.constantize, "boom"
  end
end

