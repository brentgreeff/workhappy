Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resources :exports, only: %i[create show] do
    get :download, on: :member
  end
  root "assessments#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
