require 'active_support/core_ext/module/attribute_accessors'

module Texting
  module Providers
    class Test
      cattr_accessor :deliveries
      self.deliveries = []

      def initialize(*)
      end

      def deliver!(message)
        self.class.deliveries << message if message
        message
      end
    end
  end
end
