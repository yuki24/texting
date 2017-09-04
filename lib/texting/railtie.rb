require "active_job/railtie"
require "rails"

module Texting
  class Railtie < Rails::Railtie # :nodoc:
    config.eager_load_namespaces << Texting

    initializer "texting.logger" do
      ActiveSupport.on_load(:texting) { self.logger ||= Rails.logger }
    end

    initializer "texting.compile_config_methods" do
      ActiveSupport.on_load(:texting) do
        config.compile_methods! if config.respond_to?(:compile_methods!)
      end
    end
  end
end

