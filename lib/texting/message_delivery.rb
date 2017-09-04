require "delegate"

module Texting
  class MessageDelivery < Delegator
    def initialize(texter_class, action, *args) #:nodoc:
      @texter_class, @action, @args = texter_class, action, args

      # The text message is only processed if we try to call any methods on it.
      # Typical usage will leave it unloaded and call deliver_later.
      @processed_texter = nil
      @text_message = nil
    end

    def __getobj__ #:nodoc:
      @text_message ||= processed_texter.message
    end

    # Unused except for delegator internals (dup, marshaling).
    def __setobj__(text_message) #:nodoc:
      @text_message = text_message
    end

    def message
      __getobj__
    end

    def processed?
      @processed_texter || @text_message
    end

    def deliver_later!(options = {})
      enqueue_delivery :deliver_now!, options
    end

    def deliver_now!
      processed_texter.handle_exceptions { do_deliver }
    end

    private

    def do_deliver
      @texter_class.inform_interceptors(self)

      response = nil
      @texter_class.deliver_message(self) do
        response = Adapters.instance(@texter_class.config).text!(message)
      end

      @texter_class.inform_observers(self, response)
      response
    end

    def processed_texter
      @processed_texter ||= begin
                                texter = @texter_class.new
                                texter.process @action, *@args
                                texter
                              end
    end

    def enqueue_delivery(delivery_method, options = {})
      if processed?
        ::Kernel.raise "You've accessed the message before asking to " \
                       "deliver it later, so you may have made local changes that would " \
                       "be silently lost if we enqueued a job to deliver it. Why? Only " \
                       "the texter method *arguments* are passed with the delivery job! " \
                       "Do not access the message in any way if you mean to deliver it " \
                       "later. Workarounds: 1. don't touch the message before calling " \
                       "#deliver_later, 2. only touch the message *within your texter " \
                       "method*, or 3. use a custom Active Job instead of #deliver_later."
      else
        args = @texter_class.name, @action.to_s, delivery_method.to_s, *@args
        ::Texting::DeliveryJob.set(options).perform_later(*args)
      end
    end
  end
end
