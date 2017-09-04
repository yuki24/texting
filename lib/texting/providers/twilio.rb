require 'twilio-ruby'

module Texting
  module Providers
    class Twilio
      attr_reader :account_sid, :auth_token

      def initialize(account_sid: , auth_token: )
        @account_sid = account_sid
        @auth_token  = auth_token
      end

      def deliver!(message)
        client.api.account.messages.create(from: message.from, to: message.to, body: message.body)
      end

      private

      def client
        @client ||= ::Twilio::REST::Client.new(account_sid, auth_token)
      end
    end
  end
end
