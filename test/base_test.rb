require 'test_helper'
require "set"
require "action_dispatch"
require "active_support/time"

require 'texters/base_texter'

class BaseTest < ActiveSupport::TestCase
  setup do
    BaseTexter.deliveries.clear
  end

  test "method call to texter does not raise error" do
    assert_nothing_raised { BaseTexter.welcome }
  end

  # Class level API with method missing
  test "should respond to action methods" do
    assert_respond_to BaseTexter, :welcome
    assert_not BaseTexter.respond_to?(:text)
  end

  # Basic usage without block
  test "push() should set the device tokens and generate json payload" do
    message = BaseTexter.welcome

    assert_equal '909-390-0003', message.to
    assert_equal 'Welcome!',     message.body
  end

  test "should be able to render only with a single service" do
    BaseTexter.welcome.deliver_now!

    assert_equal 1, BaseTexter.deliveries.length

    message = BaseTexter.deliveries.last

    assert_equal '909-390-0003', message.to
    assert_equal 'Welcome!',     message.body
  end

  test "Text message is not delivered when the text method was never called" do
    assert_no_changes -> { BaseTexter.deliveries.size } do
      BaseTexter.without_text_call.deliver_now!
    end
  end

  test "texter can be anonymous" do
    texter = Class.new(Texting::Base) do
      def welcome
        text to: '909-390-0003', body: 'I am anonymous'
      end
    end

    assert_equal "anonymous",      texter.texter_name
    assert_equal "I am anonymous", texter.welcome.body
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

  test "you can register an observer to the texter object that gets informed on message delivery" do
    message_side_effects do
      Texting::Base.register_observer(MyObserver)
      message = BaseTexter.welcome

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
      message = BaseTexter.welcome

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
      message = BaseTexter.welcome

      assert_called_with(MyInterceptor, :delivering_message, [message]) do
        message.deliver_now!
      end
    end
  end

  test "you can register multiple interceptors to the message object that both get passed the message object before delivery" do
    message_side_effects do
      Texting::Base.register_interceptors(BaseTest::MyInterceptor, MySecondInterceptor)
      message = BaseTexter.welcome

      assert_called_with(MyInterceptor, :delivering_message, [message]) do
        assert_called_with(MySecondInterceptor, :delivering_message, [message]) do
          message.deliver_now!
        end
      end
    end
  end

  test "modifying the message with a before_action" do
    class BeforeActionTexter < Texting::Base
      before_action :filter

      def welcome ; message ; end

      cattr_accessor :called
      self.called = false

      private
      def filter
        self.class.called = true
      end
    end

    BeforeActionTexter.welcome.message

    assert BeforeActionTexter.called, "Before action didn't get called."
  end

  test "modifying the message with an after_action" do
    class AfterActionTexter < Texting::Base
      after_action :filter

      def welcome ; message ; end

      cattr_accessor :called
      self.called = false

      private
      def filter
        self.class.called = true
      end
    end

    AfterActionTexter.welcome.message

    assert AfterActionTexter.called, "After action didn't get called."
  end

  test "action methods should be refreshed after defining new method" do
    class FooTexter < Texting::Base
      # This triggers action_methods.
      respond_to?(:foo)

      def notify
      end
    end

    assert_equal Set.new(["notify"]), FooTexter.action_methods
  end

  test "message for process" do
    begin
      events = []
      ActiveSupport::Notifications.subscribe("process.text_message") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      BaseTexter.welcome.deliver_now!

      assert_equal 1, events.length
      assert_equal "process.text_message", events[0].name
      assert_equal "BaseTexter", events[0].payload[:texter]
      assert_equal :welcome, events[0].payload[:action]
      assert_equal [], events[0].payload[:args]
    ensure
      ActiveSupport::Notifications.unsubscribe "process.text_message"
    end
  end
end
