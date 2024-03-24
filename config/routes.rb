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

  get '/files/blobs/redirect/:signed_id/*filename(.:format)', to: 'redirect#show'

  namespace :director do
    resources :tournament_orgs, only: %i(show index create), param: :identifier
    resources :users, only: %i(show index create update destroy), param: :identifier
    resources :tournaments, only: %i(index show update destroy create), param: :identifier do
      member do
        post 'clear_test_data'
        post 'state_change'
        get 'csv_download'
        get 'financial_csv_download'
        get 'igbots_download'
        post 'email_payment_reminders'
        get 'stripe_refresh'
        get 'stripe_status'
        post 'logo_upload'
      end
      resources :bowlers, only: %i(index show create destroy update), param: :identifier, shallow: true do
        resources :ledger_entries, only: %i(create), shallow: true
        resources :waivers, only: %i(create destroy), param: :identifier, shallow: true
        member do
          post 'resend_email'
        end
      end
      resources :teams, only: %i(index create show update destroy), param: :identifier, shallow: true do
        member do
          post 'confirm_shift'
        end
      end
      resources :free_entries, only: %i(index create destroy update), param: :identifier, shallow: true do
        member do
          post 'confirm'
        end
      end
      resource :testing_environment, only: %i(update)
      resources :config_items, only: %i(update), shallow: true
      resources :purchasable_items, only: %i(index create update destroy), param: :identifier, shallow: true
      resources :contacts, only: %i(create update), param: :identifier, shallow: true
      resources :shifts, only: %i(create update destroy), param: :identifier, shallow: true
      resources :additional_questions, only: %i(create update destroy), param: :identifier, shallow: true
    end
  end

  resources :tournaments, only: %i(index show), param: :identifier do
    resources :free_entries, only: %i(create), shallow: true
    resources :teams, only: %i(create index show), param: :identifier, shallow: true
    resources :bowlers, only: %i(create show index), param: :identifier, shallow: true do
      member do
        # post 'purchase_details'
        post 'stripe_checkout'
        get 'commerce'
      end
      resources :purchases, only: %i(create), param: :identifier, shallow: true
      resources :signups, only: %i(update), param: :identifier, shallow: true
    end
  end
  resources :checkout_sessions, only: %i(show), param: :identifier

  post 'stripe_webhook', to: 'stripe_webhooks#webhook'
end
