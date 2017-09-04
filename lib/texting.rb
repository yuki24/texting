require "active_support/dependencies/autoload"

require_relative "texting/version"

module Texting
  extend ::ActiveSupport::Autoload

  autoload :Base
  # autoload :DeliveryJob
  autoload :Providers
  autoload :TextMessage
  autoload :MessageDelivery
end

if defined?(Rails)
  # require 'texting/railtie'
end
