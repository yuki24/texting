require "test_helper"
require "texters/base_texter"
require "active_support/core_ext/string/strip"
require "active_support/log_subscriber/test_helper"

class LogSubscriberTest < ActiveSupport::TestCase
  include ActiveSupport::LogSubscriber::TestHelper

  def setup
    super
    Texting::LogSubscriber.attach_to :text_message
  end

  def set_logger(logger)
    Texting::Base.logger = logger
  end

  def test_deliver_is_notified
    Texting::Base.logger.level = 0
    BaseTexter.welcome.deliver_now!
    wait

    assert_equal(1, @logger.logged(:info).size)
    assert_match(/SMS: sent text message to 909-390-0003/, @logger.logged(:info).first)

    assert_equal(2, @logger.logged(:debug).size)
    assert_match(/BaseTexter#welcome: processed outbound text message in [\d.]+ms/, @logger.logged(:debug).first)
    assert_equal(<<-DEBUG_LOG.strip_heredoc.strip, @logger.logged(:debug).second)
      message:
        Welcome!
    DEBUG_LOG
  ensure
    BaseTexter.deliveries.clear
  end

  def test_deliver_is_notified_in_info
    Texting::Base.logger.level = 1
    BaseTexter.welcome.deliver_now!
    wait

    assert_equal(1, @logger.logged(:info).size)
    assert_match(/SMS: sent text message to 909-390-0003/, @logger.logged(:info).first)

    assert_equal 0, @logger.logged(:debug).size
  ensure
    BaseTexter.deliveries.clear
  end

  def test_deliver_is_not_notified_in_warn
    Texting::Base.logger.level = 2
    BaseTexter.welcome.deliver_now!
    wait

    assert_equal 0, @logger.logged(:info).size
    assert_equal 0, @logger.logged(:debug).size
  ensure
    BaseTexter.deliveries.clear
  end
end

