class ApplicationNotifier < Noticed::Event
  # Renders a notification for broadcasting to the browser
  def to_websocket(notification)
    {
      account_id: account_id,
      html: ApplicationController.render(partial: "notifications/notification", locals: {notification: notification})
    }
  end

  # Used for sending notifications to a recipients iOS devices
  def ios_device_tokens(user)
    user.notification_tokens.ios.pluck(:token)
  end

  # Used for sending notifications to a recipients Android devices
  def android_device_tokens(user)
    user.notification_tokens.android.pluck(:token)
  end

  # Remove notification token when a user removes the app from their device
  def cleanup_device_token(token:, platform:)
    NotificationToken.where(token: token, platform: platform).destroy_all
  end
end
