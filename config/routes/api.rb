namespace :api, defaults: {format: :json} do
  namespace :v1 do
    resource :auth
    resource :me, controller: :me
    resource :password
    resources :accounts
    resources :users
    resources :notification_tokens, param: :token, only: [:create, :destroy]

    # CRM resources
    resources :clients do
      collection do
        post :onboard
      end
      member do
        get :assess_risk
      end
      resources :beneficial_owners, only: [:index, :create]
    end
    resources :beneficial_owners, only: [:show, :update, :destroy]

    resources :transactions do
      member do
        get :screen
      end
    end

    resources :str_reports
    resources :managed_properties
    resources :trainings

    resources :submissions do
      member do
        post :complete
        post :validate
        get :download
      end
      collection do
        get :preview
      end
    end

    # Compliance endpoints
    get "compliance/gaps", to: "compliance#gaps"
    get "compliance/risk_assessment", to: "compliance#risk_assessment"
  end
end

resources :api_tokens
