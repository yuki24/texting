require "active_support/dependencies/autoload"

require_relative "texting/version"

module Texting
  extend ::ActiveSupport::Autoload

  autoload :Base
  autoload :DeliveryJob
  autoload :MessageDelivery
  autoload :Providers
  autoload :TextMessage
end

if defined?(Rails)
  # require 'texting/railtie'
end
