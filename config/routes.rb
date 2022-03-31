Rails.application.routes.draw do
  devise_for :users,
             path: '',
             path_names: {
               sign_in: 'login',
               sign_out: 'logout'
             },
             controllers: {
               sessions: 'users/sessions',
               passwords: 'users/passwords',
               # registrations: 'users/registrations',
             }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  namespace :director do
    resources :users, only: %i(show index create update destroy), param: :identifier
    resources :tournaments, only: %i(index show update destroy), param: :identifier do
      member do
        post 'clear_test_data'
        post 'state_change'
        get 'csv_download'
        get 'igbots_download'
      end
      resources :bowlers, only: %i(index show destroy update), param: :identifier, shallow: true do
        resources :ledger_entries, only: %i(create), shallow: true
      end
      resources :teams, only: %i(index create show update destroy), param: :identifier, shallow: true
      resources :free_entries, only: %i(index create destroy update), shallow: true do
        member do
          post 'confirm'
        end
      end
      resource :testing_environment, only: %i(update)
      resources :config_items, only: %i(update), shallow: true
      resources :purchasable_items, only: %i(create update), param: :identifier, shallow: true
      resources :contacts, only: %i(create update), shallow: true
    end
  end

  resources :tournaments, only: %i(index show), param: :identifier do
    resources :free_entries, only: %i(create), shallow: true
    resources :teams, only: %i(create index show), param: :identifier, shallow: true do
      resources :bowlers, only: %i(create show), param: :identifier, shallow: true do
        member do
          post 'purchase_details'
        end
        resources :purchases, only: %i(create), param: :identifier, shallow: true
      end
    end
  end
end
