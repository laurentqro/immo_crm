namespace :api, defaults: {format: :json} do
  namespace :v1 do
    resource :auth
    resource :me, controller: :me
    resource :password
    resources :accounts
    resources :users
    resources :notification_tokens, param: :token, only: [:create, :destroy]
  end
end

resources :api_tokens
