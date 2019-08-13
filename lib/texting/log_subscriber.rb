# frozen-string-literal: true

require "active_support/core_ext/string/access"
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
        "  #{colorize("SMS (#{event.duration.round(1)}ms)")}  #{colorize("Text message sent to ***-#{message.to.last(4).strip} from ***-#{message.from.last(4).strip}", style: "0;1")}"
      end

      return unless logger.debug?
      debug do
        "  #{colorize("Message:")}  #{message.body}\n"
      end
    end

    # A text message was generated.
    def process(event)
      return unless logger.debug?

      debug do
        messenger = event.payload[:messenger]
        action = event.payload[:action]

        "#{messenger}##{action}: processed outbound text message in #{event.duration.round(1)}ms"
      end
    end

    # Use the logger configured for Texting::Base.
    def logger
      Texting::Base.logger
    end

    private

    def colorize(message, style: '32;1')
      "\e[#{style}m#{message}\e[0m"
    end
  end
end

Texting::LogSubscriber.attach_to :text_message
