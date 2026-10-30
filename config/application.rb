require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module Workhappy
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    # No image variants anywhere in this app, and the default :vips processor needs the
    # ruby-vips gem at boot. Disabling it keeps image_processing out of the bundle.
    config.active_storage.variant_processor = :disabled

    config.generators do |g|
      g.template_engine :slim
      g.test_framework :rspec,
        fixtures: false, view_specs: false, helper_specs: false, routing_specs: false
      g.factory_bot suffix: "factory"
    end
  end
end
