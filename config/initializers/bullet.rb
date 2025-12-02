# frozen_string_literal: true

# Bullet gem configuration for N+1 query detection
# https://github.com/flyerhzm/bullet
if defined?(Bullet)
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true
      Bullet.alert = false         # Disable browser popups
      Bullet.bullet_logger = true  # Log to log/bullet.log
      Bullet.console = false       # Disable console.log warnings
      Bullet.rails_logger = true   # Add to Rails log

      # Raise errors in test environment to catch N+1s early
      Bullet.raise = Rails.env.test?

      # Whitelist Jumpstart Pro eager loading (used across many pages)
      Bullet.add_safelist type: :unused_eager_loading, class_name: "Account", association: :payment_processor
      Bullet.add_safelist type: :unused_eager_loading, class_name: "Account", association: :users
      Bullet.add_safelist type: :unused_eager_loading, class_name: "Account", association: :account_users
    end
  end
end
