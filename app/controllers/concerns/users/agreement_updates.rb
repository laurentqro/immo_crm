module Users::AgreementUpdates
  # Enforces users to accept the latest terms of service & privacy policy changes
  extend ActiveSupport::Concern

  included do
    before_action :require_accepted_latest_agreements!, if: -> { request.get? && user_signed_in? && !devise_controller? }
  end

  def require_accepted_latest_agreements!
    agreements = Rails.application.config.agreements.select(&:prompt_when_updated)
    agreements.each do |agreement|
      if agreement.not_accepted_by?(current_user)
        respond_to do |format|
          format.html {
            store_location_for(:user, request.fullpath) unless request.fullpath.start_with?("/agreements/")
            redirect_to agreement_path(agreement)
          }
          format.json { render json: {error: t("users.agreements.show.description", agreement: agreement.title)} }
        end

        break
      end
    end
  end
end
