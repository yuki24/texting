require "active_job/railtie"
require "rails"

module Texting
  class Railtie < Rails::Railtie # :nodoc:
    config.eager_load_namespaces << Texting

    initializer "texting.logger" do
      ActiveSupport.on_load(:texting) { self.logger ||= Rails.logger }
    end

    initializer "texting.set_configs" do |app|
      paths   = app.config.paths
      options = ActiveSupport::OrderedOptions.new

      if app.config.force_ssl
        options.default_url_options ||= {}
        options.default_url_options[:protocol] ||= "https"
      end

      options.assets_dir ||= paths["public"].first

      # make sure readers methods get compiled
      options.asset_host        ||= app.config.asset_host
      options.relative_url_root ||= app.config.relative_url_root

      ActiveSupport.on_load(:texting) do
        include AbstractController::UrlFor
        extend ::AbstractController::Railties::RoutesHelpers.with(app.routes, false)
        include app.routes.mounted_helpers

        options.each { |k, v| send("#{k}=", v) }
      end
    end

    initializer "texting.compile_config_methods" do
      ActiveSupport.on_load(:texting) do
        config.compile_methods! if config.respond_to?(:compile_methods!)
      end
    end
  end
end

