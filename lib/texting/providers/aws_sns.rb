require 'aws-sdk-sns'

module Texting
  module Providers
    class AwsSns
      attr_reader :client

      def initialize(*)
        @client = Aws::SNS::Client.new
      end

      def deliver!(message)
        client.publish(phone_number: message.to, message: message.body)
      end
    end
  end
end
