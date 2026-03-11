module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :configure_permitted_parameters, if: :devise_controller?

    before_action if: -> { devise_controller? && hotwire_native_app? } do
      request.env["warden"].params["hotwire_native_form"] = true
    end

    layout :set_layout if respond_to?(:layout)

    delegate :account, to: Current, prefix: :current
    helper_method :current_account

    impersonates :user
    set_referral_cookie if defined?(::Refer)
  end

  protected

  # Use minimal layout for all devise views except registrations#edit
  def set_layout
    if turbo_frame_request?
      "turbo_rails/frame"
    elsif devise_controller? && !user_signed_in?
      "auth"
    end
  end

  # To add extra fields to Devise registration, add the attribute names to `extra_keys`
  def configure_permitted_parameters
    extra_keys = [:avatar, :name, :preferred_language, :theme]
    devise_parameter_sanitizer.permit(:sign_up, keys: extra_keys + [:terms_of_service, :invite, owned_accounts_attributes: [:name]])
    devise_parameter_sanitizer.permit(:account_update, keys: extra_keys)
    devise_parameter_sanitizer.permit(:accept_invitation, keys: extra_keys)
  end

  def after_sign_in_path_for(resource_or_scope)
    return "/reset_app" if hotwire_native_app?
    stored_location_for(resource_or_scope) || super
  end

  # Helper method for verifying authentication in a before_action, but redirecting to sign up instead of login
  def authenticate_user_with_sign_up!
    unless user_signed_in?
      store_location_for(:user, request.fullpath)
      redirect_to new_user_registration_path, alert: t("create_an_account_first")
    end
  end

  def require_current_account_admin
    redirect_to root_path, alert: t("must_be_an_admin") unless Current.account_admin?
  end

  private

  def require_account
    redirect_to new_user_registration_path unless Current.account
  end
end
