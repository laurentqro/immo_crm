class Api::V1::AuthsController < Api::BaseController
  skip_before_action :require_api_authentication
  before_action :authenticate, only: [:create]

  def create
    if hotwire_native_app?
      user.remember_me = true
      sign_in user
      render json: {}
    else
      render json: {token: user.api_tokens.find_or_create_by(name: ApiToken::DEFAULT_NAME).token}
    end
  end

  # Hotwire Native sign out
  def destroy
    current_user.notification_tokens.find_by(token: params[:notification_token])&.destroy
    sign_out(current_user)
    render json: {}
  end

  private

  # Authenticates email and password
  # Then if OTP require but not present, sends 422 response
  def authenticate
    if !user&.valid_password?(params[:password])
      keys = User.authentication_keys.join(I18n.translate(:"support.array.words_connector"))
      render json: {error: I18n.t("devise.failure.invalid", authentication_keys: keys)}, status: :unauthorized
    elsif !user.otp_required_for_login?
      true
    elsif params[:otp_attempt].blank?
      render json: {error: :otp_attempt_required}, status: :unprocessable_content
    elsif user.verify_and_consume_otp!(params[:otp_attempt])
      true
    else
      render json: {error: t("users.sessions.create.incorrect_verification_code")}, status: :unauthorized
    end
  end

  def user
    @user ||= User.find_by(email: params[:email])
  end
end
