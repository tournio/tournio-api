Rails.application.routes.draw do
  devise_for :users,
             path: '',
             path_names: {
               sign_in: 'login',
               sign_out: 'logout'
             },
             controllers: {
               sessions: 'users/sessions',
               # registrations: 'users/registrations',
             }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  namespace :director do
    resources :users, only: %i(show index create update destroy), param: :identifier
    resources :tournaments, only: %i(index show), param: :identifier do
      member do
        post 'clear_test_data'
      end
      member do
        post 'state_change'
      end
      resources :bowlers, only: %i(index show destroy update), param: :identifier, shallow: true
      resources :teams, only: %i(index create show update destroy), param: :identifier, shallow: true
      resources :free_entries, only: %i(index create destroy), shallow: true do
        member do
          post 'confirm'
        end
      end
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
