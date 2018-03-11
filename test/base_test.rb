require 'test_helper'
require "set"
require "action_dispatch"
require "active_support/time"

require 'messengers/base_messenger'

class BaseTest < ActiveSupport::TestCase
  setup do
    BaseMessenger.deliveries.clear
  end

  test "method call to messenger does not raise error" do
    assert_nothing_raised { BaseMessenger.welcome }
  end

  # Class level API with method missing
  test "should respond to action methods" do
    assert_respond_to BaseMessenger, :welcome
    assert_not BaseMessenger.respond_to?(:text)
  end

  # Basic usage without block
  test "push() should set the device tokens and generate json payload" do
    message = BaseMessenger.welcome

    assert_equal '909-390-0003', message.to
    assert_equal 'Welcome!',     message.body
  end

  test "should be able to render only with a single service" do
    BaseMessenger.welcome.deliver_now!

    assert_equal 1, BaseMessenger.deliveries.length

    message = BaseMessenger.deliveries.last

    assert_equal '909-390-0003', message.to
    assert_equal 'Welcome!',     message.body
  end

  test "Text message is not delivered when the text method was never called" do
    if respond_to?(:assert_no_changes)
      assert_no_changes -> { BaseMessenger.deliveries.size } do
        BaseMessenger.without_text_call.deliver_now!
      end
    else
      assert_no_difference -> { BaseMessenger.deliveries.size } do
        BaseMessenger.without_text_call.deliver_now!
      end
    end
  end

  test "messenger can be anonymous" do
    messenger = Class.new(Texting::Base) do
      def welcome
        text to: '909-390-0003', body: 'I am anonymous'
      end
    end

    assert_equal "anonymous",      messenger.messenger_name
    assert_equal "I am anonymous", messenger.welcome.body
  end

  # Before and After hooks

  class MyObserver
    def self.delivered_message(message, response)
    end
  end

  class MySecondObserver
    def self.delivered_message(message, response)
    end
  end

  test "you can register an observer to the messenger object that gets informed on message delivery" do
    message_side_effects do
      Texting::Base.register_observer(MyObserver)
      message = BaseMessenger.welcome

      assert_called_with(MyObserver, :delivered_message, [message, message]) do
        message.deliver_now!
      end
    end
  end

  def message_side_effects
    old_observers = Texting::Base.class_variable_get(:@@delivery_message_observers)
    old_delivery_interceptors = Texting::Base.class_variable_get(:@@delivery_interceptors)
    yield
  ensure
    Texting::Base.class_variable_set(:@@delivery_message_observers, old_observers)
    Texting::Base.class_variable_set(:@@delivery_interceptors, old_delivery_interceptors)
  end

  test "you can register multiple observers to the message object that both get informed on message delivery" do
    message_side_effects do
      Texting::Base.register_observers(BaseTest::MyObserver, MySecondObserver)
      message = BaseMessenger.welcome

      assert_called_with(MyObserver, :delivered_message, [message, message]) do
        assert_called_with(MySecondObserver, :delivered_message, [message, message]) do
          message.deliver_now!
        end
      end
    end
  end

  class MyInterceptor
    def self.delivering_message(message); end
    def self.previewing_message(message); end
  end

  class MySecondInterceptor
    def self.delivering_message(message); end
    def self.previewing_message(message); end
  end

  test "you can register an interceptor to the message object that gets passed the message object before delivery" do
    message_side_effects do
      Texting::Base.register_interceptor(MyInterceptor)
      message = BaseMessenger.welcome

      assert_called_with(MyInterceptor, :delivering_message, [message]) do
        message.deliver_now!
      end
    end
  end

  test "you can register multiple interceptors to the message object that both get passed the message object before delivery" do
    message_side_effects do
      Texting::Base.register_interceptors(BaseTest::MyInterceptor, MySecondInterceptor)
      message = BaseMessenger.welcome

      assert_called_with(MyInterceptor, :delivering_message, [message]) do
        assert_called_with(MySecondInterceptor, :delivering_message, [message]) do
          message.deliver_now!
        end
      end
    end
  end

  test "modifying the message with a before_action" do
    class BeforeActionMessenger < Texting::Base
      before_action :filter

      def welcome ; message ; end

      cattr_accessor :called
      self.called = false

      private
      def filter
        self.class.called = true
      end
    end

    BeforeActionMessenger.welcome.message

    assert BeforeActionMessenger.called, "Before action didn't get called."
  end

  test "modifying the message with an after_action" do
    class AfterActionMessenger < Texting::Base
      after_action :filter

      def welcome ; message ; end

      cattr_accessor :called
      self.called = false

      private
      def filter
        self.class.called = true
      end
    end

    AfterActionMessenger.welcome.message

    assert AfterActionMessenger.called, "After action didn't get called."
  end

  test "action methods should be refreshed after defining new method" do
    class FooMessenger < Texting::Base
      # This triggers action_methods.
      respond_to?(:foo)

      def notify
      end
    end

    assert_equal Set.new(["notify"]), FooMessenger.action_methods
  end

  test "message for process" do
    begin
      events = []
      ActiveSupport::Notifications.subscribe("process.text_message") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      BaseMessenger.welcome.deliver_now!

      assert_equal 1, events.length
      assert_equal "process.text_message", events[0].name
      assert_equal "BaseMessenger", events[0].payload[:messenger]
      assert_equal :welcome, events[0].payload[:action]
      assert_equal [], events[0].payload[:args]
    ensure
      ActiveSupport::Notifications.unsubscribe "process.text_message"
    end
  end
end
