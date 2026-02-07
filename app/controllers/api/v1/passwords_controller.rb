class Api::V1::PasswordsController < Api::BaseController
  def update
    if current_user.update_with_password(password_params)
      current_user.remember_me = true
      bypass_sign_in current_user
      render json: {success: true}
    else
      render json: {
        error: current_user.errors.full_messages.to_sentence
      }, status: :unprocessable_content
    end
  end

  private

  def password_params
    params.expect(user: [:current_password, :password, :password_confirmation])
  end
end
