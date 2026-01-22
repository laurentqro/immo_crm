require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JumpstartApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets generators jumpstart tasks templates])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Use ErrorsController for handling 404s and 500s.
    config.exceptions_app = routes

    # Where the I18n library should search for translation files
    # Search nested folders in config/locales for better organization
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]

    # Permitted locales available for the application
    # Includes :fr for AMSF Survey gem (Monaco regulatory context requires French)
    config.i18n.available_locales = [:en, :fr]

    # Set default locale
    config.i18n.default_locale = :en

    # Use default language as fallback if translation is missing
    config.i18n.fallbacks = true

    # Prevent sassc-rails from setting sass as the compressor
    # Libsass is deprecated and doesn't support modern CSS syntax used by TailwindCSS
    config.assets.css_compressor = nil

    # Rails 7 defaults to libvips as the variant processor
    # libvips is up to 10x faster and consumes 1/10th the memory of imagemagick
    # If you need to use imagemagick, uncomment this to switch
    # config.active_storage.variant_processor = :mini_magick

    # Support older SHA1 digests for ActiveStorage so ActionText attachments don't break
    config.after_initialize do |app|
      app.message_verifier("ActiveStorage").rotate(digest: "SHA1")
    end

    # Support older SHA1 digests for ActiveRecord::Encryption
    config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true

    config.after_initialize do |app|
      Madmin.importmap.draw do
        pin_all_from Rails.root.join("app/javascript/madmin/controllers"), under: "controllers", to: "madmin/controllers"
      end
    end

    # We already authenticate /admin routes
    ::MissionControl::Jobs.http_basic_auth_enabled = false if defined?(::MissionControl::Jobs)
  end
end
