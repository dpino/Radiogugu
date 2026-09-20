require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Radiogugu
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.action_mailer.default_url_options = { host: "localhost:3000" }

    # When deployed behind a reverse proxy at a sub-path (e.g. /radiogugu),
    # RAILS_RELATIVE_URL_ROOT alone only affects asset URLs and out-of-request
    # url_for calls. Controller-driven path/url helpers read SCRIPT_NAME off
    # the live request instead, which is empty because the proxy strips the
    # prefix before forwarding - so it has to be set explicitly here.
    if ENV["RAILS_RELATIVE_URL_ROOT"].present?
      script_name = ENV["RAILS_RELATIVE_URL_ROOT"]
      config.middleware.use(Class.new do
        define_method(:initialize) { |app| @app = app }
        define_method(:call) { |env| @app.call(env.merge("SCRIPT_NAME" => script_name)) }
      end)
    end
  end
end
