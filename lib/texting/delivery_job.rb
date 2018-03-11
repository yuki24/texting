require 'active_job'

module Texting
  class DeliveryJob < ActiveJob::Base # :nodoc:
    queue_as { Texting::Base.deliver_later_queue_name }

    if ActiveSupport::VERSION::MAJOR > 4
      rescue_from StandardError, with: :handle_exception_with_messenger_class
    end

    def perform(messenger, text_method, delivery_method, *args) #:nodoc:
      messenger.constantize.public_send(text_method, *args).send(delivery_method)
    end

    private

    def messenger_class
      if messenger = Array(@serialized_arguments).first || Array(arguments).first
        messenger.constantize
      end
    end

    def handle_exception_with_messenger_class(exception)
      if klass = messenger_class
        klass.handle_exception exception
      else
        raise exception
      end
    end
  end
end

