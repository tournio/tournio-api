Stripe.api_key = ENV['STRIPE_API_KEY']

# Stripe.log_level = Rails.env.production? ? Stripe::LEVEL_INFO : Stripe::LEVEL_DEBUG
Stripe.log_level = Stripe::LEVEL_INFO
