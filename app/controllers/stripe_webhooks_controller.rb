class StripeWebhooksController < ApplicationController
  wrap_parameters false

  ENDPOINT_SECRET = ENV['STRIPE_WEBHOOK_KEY']

  def webhook
    body = request.body.read
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']

    event = Stripe::Webhook.construct_event(body, sig_header, ENDPOINT_SECRET)

    case event[:type]
    when 'checkout.session.completed'
      Stripe::EventHandler.perform_async(event[:id])
    end

    render json: {}, status: :no_content
  rescue JSON::ParserError => e
    render json: {}, status: :bad_request
  rescue Stripe::SignatureVerificationError => e
    render json: {}, status: :bad_request
  end
end
