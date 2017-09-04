require "active_support/log_subscriber"

module Texting
  # Implements the ActiveSupport::LogSubscriber for logging text messages when
  # a text message is delivered.
  class LogSubscriber < ActiveSupport::LogSubscriber
    # A text message was delivered.
    def deliver(event)
      return unless logger.info?

      message = event.payload[:message]
      info do
        "  SMS: sent text message to #{message.to} (#{event.duration.round(1)}ms)"
      end

      return unless logger.debug?
      debug do
        "  message:\n  #{message.body}\n"
      end
    end

    # A text message was generated.
    def process(event)
      return unless logger.debug?

      debug do
        texter = event.payload[:texter]
        action = event.payload[:action]

        "#{texter}##{action}: processed outbound text message in #{event.duration.round(1)}ms"
      end
    end

    # Use the logger configured for Texting::Base.
    def logger
      Texting::Base.logger
    end
  end
end

Texting::LogSubscriber.attach_to :text_message
