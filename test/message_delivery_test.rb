require 'test_helper'
require 'active_job'
require 'messengers/delayed_messenger'

class MessageDeliveryTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @previous_logger = ActiveJob::Base.logger
    @previous_deliver_later_queue_name = Texting::Base.deliver_later_queue_name
    Texting::Base.deliver_later_queue_name = :test_queue
    ActiveJob::Base.logger = Logger.new(nil)
    Texting::Base.deliveries.clear
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true

    DelayedMessenger.last_error = nil
    DelayedMessenger.last_rescue_from_instance = nil

    @message = Texting::MessageDelivery.new(BaseMessenger, :welcome, args: "value")
  end

  teardown do
    ActiveJob::Base.logger = @previous_logger
    Texting::Base.deliver_later_queue_name = @previous_deliver_later_queue_name

    DelayedMessenger.last_error = nil
    DelayedMessenger.last_rescue_from_instance = nil
  end

  def test_should_enqueue_and_run_correctly_in_activejob
    @message.deliver_later!
    assert_equal 1, Texting::Base.deliveries.size
  ensure
    Texting::Base.deliveries.clear
  end

  test "should enqueue the message with :deliver_now! delivery method" do
    args = [
      "BaseMessenger",
      "welcome",
      "deliver_now!",
      { args: "value" }
    ]

    assert_performed_with job: Texting::DeliveryJob, args: args, queue: "test_queue" do
      @message.deliver_later!
    end
  end

  test "should enqueue a delivery with a delay" do
    args = [
      "BaseMessenger",
      "welcome",
      "deliver_now!",
      { args: "value" }
    ]

    travel_to Time.new(2004, 11, 24, 01, 04, 44) do
      assert_performed_with job: Texting::DeliveryJob, at: Time.current.to_f + 600, args: args do
        @message.deliver_later!(wait: 600.seconds)
      end
    end
  end

  test "should enqueue a delivery at a specific time" do
    args = [
      "BaseMessenger",
      "welcome",
      "deliver_now!",
      { args: "value" }
    ]

    later_time = Time.now.to_f + 3600
    assert_performed_with job: Texting::DeliveryJob, at: later_time, args: args do
      @message.deliver_later!(wait_until: later_time)
    end
  end

  test "can override the queue when enqueuing message" do
    args = [
      "BaseMessenger",
      "welcome",
      "deliver_now!",
      { args: "value" }
    ]

    assert_performed_with job: Texting::DeliveryJob, args: args, queue: "another_queue" do
      @message.deliver_later!(queue: :another_queue)
    end
  end

  test "deliver_later! after accessing the message is disallowed" do
    @message.message # Load the message, which calls the notifier method.

    assert_raise RuntimeError do
      @message.deliver_later!
    end
  end

  class DeserializationErrorFixture
    include GlobalID::Identification

    def self.find(id)
      raise "boom, missing find"
    end

    attr_reader :id
    def initialize(id = 1)
      @id = id
    end

    def to_global_id(options = {})
      super app: "foo"
    end
  end

  if ActiveSupport::VERSION::MAJOR > 4
    test "job delegates error handling to notifier" do
      # Superclass not rescued by notifier's rescue_from RuntimeError
      message = DelayedMessenger.test_raise("StandardError")
      assert_raise(StandardError) { message.deliver_later! }
      assert_nil DelayedMessenger.last_error
      assert_nil DelayedMessenger.last_rescue_from_instance

      # Rescued by notifier's rescue_from RuntimeError
      message = DelayedMessenger.test_raise("DelayedMessengerError")
      assert_nothing_raised { message.deliver_later! }
      assert_equal "boom", DelayedMessenger.last_error.message
      assert_kind_of DelayedMessenger, DelayedMessenger.last_rescue_from_instance
    end

    test "job delegates deserialization errors to notifier class" do
      # Inject an argument that can't be deserialized.
      message = DelayedMessenger.test_message(arg: DeserializationErrorFixture.new)

      # DeserializationError is raised, rescued, and delegated to the handler
      # on the notifier class.
      assert_nothing_raised { message.deliver_later! }
      assert_equal DelayedMessenger, DelayedMessenger.last_rescue_from_instance
      assert_equal "Error while trying to deserialize arguments: boom, missing find", DelayedMessenger.last_error.message
    end
  else
    test "job does not delegate error handling to notifier" do
      message = DelayedMessenger.test_raise("StandardError")
      assert_raise(StandardError) { message.deliver_later! }
      assert_nil DelayedMessenger.last_error
      assert_nil DelayedMessenger.last_rescue_from_instance

      message = DelayedMessenger.test_raise("DelayedMessengerError")
      assert_raise(DelayedMessengerError, /boom/) { message.deliver_later! }
    end

    test "job does not delegate deserialization errors to notifier class" do
      # Inject an argument that can't be deserialized.
      message = DelayedMessenger.test_message(arg: DeserializationErrorFixture.new)

      assert_raise(ActiveJob::DeserializationError) { message.deliver_later! }
    end
  end
end

