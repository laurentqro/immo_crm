class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  include Accounts::SubscriptionStatus
  include ActiveStorage::SetCurrent
  include Authentication
  include Authorization
  include DeviceFormat
  include Pagination
  include SetCurrentRequestDetails
  include SetLocale
  include Sortable
  include Users::AgreementUpdates
  include Users::NavbarNotifications
  include Users::Sudo

  # CRM: Organization helper available globally
  helper_method :current_organization

  private

  # Returns the organization for the current account, if one exists.
  # Use OrganizationScoped concern in controllers that require organization access.
  def current_organization
    @current_organization ||= current_account&.organization
  end
end
