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
    end
  end

  resources :tournaments, only: %i(index show), param: :identifier do
    resources :teams, only: %i(show), param: :identifier
  end
end
