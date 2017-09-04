# frozen-string-literal: true

require "abstract_controller"
require 'active_support/core_ext/module/attribute_accessors'

require_relative 'log_subscriber'
require_relative 'rescuable'

module Texting
  class Base < AbstractController::Base
    include Rescuable

    abstract!

    include AbstractController::Logger
    include AbstractController::Helpers
    include AbstractController::Translation
    include AbstractController::Callbacks
    begin
      include AbstractController::Caching
    rescue NameError
      # AbstractController::Caching does not exist in rails 4.2. No-op.
    end

    PROTECTED_IVARS = AbstractController::Rendering::DEFAULT_PROTECTED_INSTANCE_VARIABLES + [:@_action_has_layout]

    def _protected_ivars # :nodoc:
      PROTECTED_IVARS
    end

    cattr_accessor :deliver_later_queue_name
    self.deliver_later_queue_name = :texters

    cattr_reader :delivery_message_observers
    @@delivery_message_observers = []

    cattr_reader :delivery_interceptors
    @@delivery_interceptors = []

    class << self
      delegate :deliveries, :deliveries=, to: Texting::Providers::Test

      # Register one or more Observers which will be notified when a text message is delivered.
      def register_observers(*observers)
        observers.flatten.compact.each { |observer| register_observer(observer) }
      end

      # Register one or more Interceptors which will be called before a text message is sent.
      def register_interceptors(*interceptors)
        interceptors.flatten.compact.each { |interceptor| register_interceptor(interceptor) }
      end

      # Register an Observer which will be notified when a text message is delivered.
      # Either a class, string or symbol can be passed in as the Observer.
      # If a string or symbol is passed in it will be camelized and constantized.
      def register_observer(observer)
        unless delivery_message_observers.include?(observer)
          delivery_message_observers << observer
        end
      end

      # Register an Interceptor which will be called before a text message is sent.
      # Either a class, string or symbol can be passed in as the Interceptor.
      # If a string or symbol is passed in it will be camelized and constantized.
      def register_interceptor(interceptor)
        unless delivery_interceptors.include?(interceptor)
          delivery_interceptors << interceptor
        end
      end

      def inform_observers(message, response)
        delivery_message_observers.each do |observer|
          observer.delivered_message(message, response)
        end
      end

      def inform_interceptors(message)
        delivery_interceptors.each do |interceptor|
          interceptor.delivering_message(message)
        end
      end

      def texter_name
        @texter_name ||= anonymous? ? "anonymous" : name.underscore
      end
      # Allows to set the name of current texter.
      attr_writer :texter_name
      alias :controller_path :texter_name

      # Wraps a text message delivery inside of <tt>ActiveSupport::Notifications</tt> instrumentation.
      def deliver_message(message) #:nodoc:
        ActiveSupport::Notifications.instrument("deliver.text_message") do |payload|
          set_payload_for_message(payload, message)
          yield # Let MessageDelivery do the delivery actions
        end
      end

      private

      def set_payload_for_message(payload, message)
        payload[:texter]  = name
        payload[:message] = message
      end

      def method_missing(method_name, *args)
        if action_methods.include?(method_name.to_s)
          MessageDelivery.new(self, method_name, *args)
        else
          super
        end
      end

      def respond_to_missing?(method, include_all = false)
        action_methods.include?(method.to_s) || super
      end
    end

    def process(method_name, *args) #:nodoc:
      payload = {
        texter: self.class.name,
        action: method_name,
        args: args
      }

      ActiveSupport::Notifications.instrument("process.text_message", payload) do
        super
        @_message ||= NullMessage.new
      end
    end

    class NullMessage #:nodoc:
      def respond_to?(string, include_all = false)
        true
      end

      def method_missing(*args)
        nil
      end
    end

    attr_internal :message

    def text(to: nil, body: nil)
      return message if message && to.nil && body.nil?

      @_message = TextMessage.new(to: to, body: body)
    end

    ActiveSupport.run_load_hooks(:texting, self)
  end
end

