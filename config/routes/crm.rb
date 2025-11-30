# frozen_string_literal: true

# CRM routes for Immo CRM MVP
# All routes require authentication and organization scope

# Onboarding wizard (organization setup)
resources :onboarding, only: [:new, :create] do
  collection do
    get :entity_info
    post :entity_info
    get :policies
    post :policies
  end
end

# Dashboard (root for authenticated users)
resource :dashboard, only: [:show], controller: "dashboard"

# Client management (US2)
resources :clients do
  resources :beneficial_owners, shallow: true
end

# Transaction management (US3)
resources :transactions
resources :str_reports

# Settings management (US4)
resources :settings, only: [:index, :update] do
  collection do
    patch :batch_update
  end
end

# Annual submission wizard (US5)
resources :submissions do
  member do
    get :download
  end

  resources :submission_steps, only: [:show, :update], param: :step do
    member do
      post :confirm
    end
  end
end

# Audit log viewing (compliance)
resources :audit_logs, only: [:index, :show]
