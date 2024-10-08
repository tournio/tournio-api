source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.5"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.5"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.3"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem "rack-cors"

# Added by me

gem 'aasm'                       # state machine behavior
gem 'alba'                       # JSON serialization
gem 'amazing_print'              # human-friendly printing of things on the console
gem 'aws-sdk-s3', '~> 1.166'   # For using Backblaze's S3-compatible API for asset storage
gem 'blueprinter'                # JSON serialization, but not JSON:API style
gem 'bugsnag'                    # Error reporting
gem 'csv'                        # CSV export for data
gem 'data_migrate'               # Perform data migrations just like schema migrations
gem 'devise', '~> 4.9'           # Authentication
# gem 'devise-async'               # Background delivery of password-reset emails
gem 'devise-jwt'                 # for JWT-based login
gem 'factory_bot_rails'           # factory objects for testing!
# gem "image_processing", "~> 1.2" # image analysis and transformations
# gem 'ruby-vips'                  # image analysis
gem 'oj', '~> 3.16'            # Fast backend for Alba JSON serialization
gem 'pundit'                     # Authorization
gem 'sendgrid-ruby'              # For sending emails using SendGrid
gem 'sidekiq'                    # The queueing system to use with ActiveJob
gem 'slugify'                    # Slugification support
gem 'stripe'                     # Stripe integration

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "get_process_mem"

  #############################
  # Gems added by me
  #############################

  # gem 'factory_bot_rails'           # factory objects for testing!
  gem 'rspec-rails'                 # let's use rspec for unit tests
  gem 'shoulda-matchers'            # extra one-liner expectation syntax
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  #############################
  # Gems added by me
  #############################

  # adds model schema definition annotations to each model file
  gem 'annotate'
  gem 'rubocop'
end

group :test do
  #############################
  # Gems added by me
  #############################

  gem 'database_cleaner-active_record' # Wipe the DB before each test
end
