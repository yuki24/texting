# frozen-string-literal: true

module Texting
  module Providers
    extend ActiveSupport::Autoload

    autoload :Test
    autoload :Twilio

    # Hash object that holds referenses to provider instances.
    PROVIDER_INSTANCES = {}

    # Mutex object used to ensure the +instance+ method creates a singleton object.
    MUTEX = Mutex.new

    private_constant :PROVIDER_INSTANCES, :MUTEX

    class << self
      ##
      # Returns the constant for the specified provider name.
      #
      #   Texting::Providers.lookup(:twilio)
      #   # => Texting::Providers::Twilio
      def lookup(name)
        const_get(name.to_s.camelize)
      end

      ##
      # Provides an provider instance specified in the +config+. If the provider is not found in
      # +PROVIDER_INSTANCES+, it'll look up the provider class and create a new instance using the
      # +config+.
      def instance(config)
        PROVIDER_INSTANCES[config.provider] || MUTEX.synchronize do
          PROVIDER_INSTANCES[config.provider] ||= lookup(config.provider).new(config[:"#{config.provider}_settings"])
        end
      end
    end
  end
end

