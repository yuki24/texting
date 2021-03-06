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
    include AbstractController::AssetPaths
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
    self.deliver_later_queue_name = :messengers

    cattr_reader :delivery_message_observers
    @@delivery_message_observers = []

    cattr_reader :delivery_interceptors
    @@delivery_interceptors = []

    class_attribute :default_params
    self.default_params = {}.freeze

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

      class AfterDeliveryObserver
        attr_reader :block

        def initialize(block)
          @block = block
        end

        def delivered_message(message, response)
          block.call(message, response)
        end
      end

      class BeforeDeliveryInterceptor
        attr_reader :block

        def initialize(block)
          @block = block
        end

        def delivering_message(message)
          block.call(message)
        end
      end

      def after_delivery(&block)
        register_observer AfterDeliveryObserver.new(block)
      end

      def before_delivery(&block)
        register_interceptor BeforeDeliveryInterceptor.new(block)
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

      def messenger_name
        @messenger_name ||= anonymous? ? "anonymous" : name.underscore
      end
      # Allows to set the name of current messenger.
      attr_writer :messenger_name
      alias :controller_path :messenger_name

      # Sets the defaults through app configuration:
      #
      #     config.action_mailer.default from: "909-390-0003"
      #
      # Aliased by ::default_options=
      def default(value = nil)
        self.default_params = default_params.merge(value).freeze if value
        default_params
      end
      # Allows to set defaults through app configuration:
      #
      #    config.action_mailer.default_options = { from: "909-390-0003" }
      alias :default_options= :default

      # Wraps a text message delivery inside of <tt>ActiveSupport::Notifications</tt> instrumentation.
      def deliver_message(message) #:nodoc:
        ActiveSupport::Notifications.instrument("deliver.text_message") do |payload|
          set_payload_for_message(payload, message)
          yield # Let MessageDelivery do the delivery actions
        end
      end

      # Push notifications do not support relative path links.
      def supports_path? # :doc:
        false
      end

      private

      def set_payload_for_message(payload, message)
        payload[:messenger]  = name
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
        messenger: self.class.name,
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

      @_message = TextMessage.new(to: to, body: body.strip, **self.class.default)
    end

    ActiveSupport.run_load_hooks(:texting, self)
  end
end
