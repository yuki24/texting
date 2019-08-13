require "test_helper"
require "messengers/base_messenger"
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

  LIGHT_GREEN = "\\e\\[32;1m"
  BOLD_WHITE  = "\\e\\[0;1m"
  NO_COLOR    = "\\e\\[0m"

  def test_deliver_is_notified
    Texting::Base.logger.level = 0
    BaseMessenger.welcome(to: "347-123-4567").deliver_now!
    wait

    assert_equal(1, @logger.logged(:info).size)
    assert_match(/#{LIGHT_GREEN}SMS \(\d+\.\d+ms\)#{NO_COLOR}  #{BOLD_WHITE}Text message sent to \*\*\*-4567 from \*\*\*-0003#{NO_COLOR}/, @logger.logged(:info).first)

    assert_equal(2, @logger.logged(:debug).size)
    assert_match(/BaseMessenger#welcome: processed outbound text message in [\d.]+ms/, @logger.logged(:debug).first)
    assert_equal(<<-DEBUG_LOG.strip_heredoc.strip, @logger.logged(:debug).second)
      \e[32;1mMessage:\e[0m  Welcome!
    DEBUG_LOG
  ensure
    BaseMessenger.deliveries.clear
  end

  def test_deliver_is_notified_in_info
    Texting::Base.logger.level = 1
    BaseMessenger.welcome(to: "347-123-4567").deliver_now!
    wait

    assert_equal(1, @logger.logged(:info).size)
    assert_match(/#{LIGHT_GREEN}SMS \(\d+\.\d+ms\)#{NO_COLOR}  #{BOLD_WHITE}Text message sent to \*\*\*-4567 from \*\*\*-0003#{NO_COLOR}/, @logger.logged(:info).first)

    assert_equal 0, @logger.logged(:debug).size
  ensure
    BaseMessenger.deliveries.clear
  end

  def test_deliver_is_not_notified_in_warn
    Texting::Base.logger.level = 2
    BaseMessenger.welcome.deliver_now!
    wait

    assert_equal 0, @logger.logged(:info).size
    assert_equal 0, @logger.logged(:debug).size
  ensure
    BaseMessenger.deliveries.clear
  end
end

