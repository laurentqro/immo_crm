class Users::AgreementsController < ApplicationController
  skip_before_action :require_accepted_latest_agreements!
  before_action :authenticate_user!
  before_action :set_agreement

  layout "minimal"

  def show
    respond_to do |format|
      format.html
      format.json { render json: {error: t(".description", agreement: @agreement.title)} }
    end
  end

  def update
    current_user.update!(@agreement.column => Time.current)
    redirect_to after_accepted_path, status: :see_other
  end

  def destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(current_user)
    redirect_to after_sign_out_path_for(:user), status: :see_other, alert: t(".declined", agreement: @agreement.title)
  end

  private

  def set_agreement
    @agreement = Rails.application.config.agreements.find { it.id.to_s == params[:id] }

    if @agreement.nil?
      redirect_to root_path
    elsif @agreement.accepted_by?(current_user)
      redirect_to after_accepted_path
    end
  end

  def after_accepted_path
    stored_location_for(:user) || root_path
  end
end
