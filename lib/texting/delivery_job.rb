require 'active_job'

module Texting
  class DeliveryJob < ActiveJob::Base # :nodoc:
    queue_as { Texting::Base.deliver_later_queue_name }

    if ActiveSupport::VERSION::MAJOR > 4
      rescue_from StandardError, with: :handle_exception_with_texter_class
    end

    def perform(texter, text_method, delivery_method, *args) #:nodoc:
      texter.constantize.public_send(text_method, *args).send(delivery_method)
    end

    private

    def texter_class
      if texter = Array(@serialized_arguments).first || Array(arguments).first
        texter.constantize
      end
    end

    def handle_exception_with_texter_class(exception)
      if klass = texter_class
        klass.handle_exception exception
      else
        raise exception
      end
    end
  end
end

