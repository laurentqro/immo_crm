# frozen_string_literal: true

# CRM routes for Immo CRM MVP
# All routes require authentication via Devise's authenticate block
#
# NOTE: Routes are defined for the full MVP scope. Controllers will be
# implemented incrementally across phases:
# - Phase 1: Routes defined (this file), no controllers yet
# - Phase 2: Onboarding, Dashboard, Clients controllers
# - Phase 3: Transactions, STR Reports, Settings controllers
# - Phase 4: Submissions, Audit Logs controllers
#
# Accessing undefined controller routes will return Rails' default error.

authenticate :user do
  # Onboarding wizard (organization setup) - Phase 2
  # Two-step wizard: entity_info → policies → dashboard
  resources :onboarding, only: [:new, :create] do
    collection do
      get :entity_info
      post :entity_info, action: :entity_info_submit
      get :policies
      post :policies, action: :policies_submit
    end
  end

  # Dashboard (root for authenticated users) - Phase 2
  resource :dashboard, only: [:show], controller: "dashboard"

  # Client management (US2) - Phase 2
  resources :clients do
    resources :beneficial_owners, shallow: true
  end

  # Managed Properties (US3 - AMSF Data Capture)
  resources :managed_properties

  # Trainings (US4 - AMSF Data Capture)
  resources :trainings

  # Transaction management (US3) - Phase 3
  resources :transactions
  resources :str_reports

  # Settings management (US4) - Phase 3
  # Singular resource: one settings page per organization (GET/PATCH /settings)
  resource :settings, only: [:show, :update], controller: "settings"

  # Annual submission (US5) - Phase 4
  resources :submissions do
    member do
      get :download
      get :review
      post :complete
    end
  end

  # Audit log viewing (compliance) - Phase 4
  resources :audit_logs, only: [:index, :show]
end
