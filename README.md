# igbo-registration-api

This is the code for the API backend of my registration system for IGBO bowling tournaments. The repository for the frontend is at `igbo-registration-client`.

This was built using a fresh instance of a Rails API-only application.

## Ruby version

3.1.1.

I endeavor to be on the latest versions of the language and framework. As such, you can expect to see frequent updates for Ruby, Rails, and gem version updates.

## Dependencies

The main libraries used in this system are:
- Rails
- Devise (user authentication)
- Devise-JWT (authentication using JWT, helpful for using Devise in an API context)
- Sidekiq (background job processing)
- Pundit (authorization)
- Blueprinter (object serialization)
- SendGrid (emails)
- RSpec-Rails (test suite)

## Getting going

There's nothing special about the database; you'd get it going like you would in any standard Rails application.

There are two seed files, neither of which is strictly necessary for getting things going.

## Testing

Tests are all RSpec files.

## More to come

As I flesh this out...
