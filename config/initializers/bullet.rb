# frozen_string_literal: true

# Bullet gem configuration for N+1 query detection
# https://github.com/flyerhzm/bullet
if defined?(Bullet)
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true
      Bullet.alert = true          # Browser popup for N+1s
      Bullet.bullet_logger = true  # Log to log/bullet.log
      Bullet.console = true        # Console.log warnings
      Bullet.rails_logger = true   # Add to Rails log

      # Raise errors in test environment to catch N+1s early
      Bullet.raise = Rails.env.test?

      # Optional: Slack/email notifications for production monitoring
      # Bullet.slack = { webhook_url: ENV["BULLET_SLACK_URL"], channel: "#alerts" }
    end
  end
end
