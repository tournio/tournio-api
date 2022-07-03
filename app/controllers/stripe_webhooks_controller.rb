class StripeWebhooksController < ApplicationController
  include ActiveSupport::Inflector

  wrap_parameters false

  ENDPOINT_SECRET = ENV['STRIPE_WEBHOOK_KEY']

  def webhook
    body = request.body.read
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']

    event = Stripe::Webhook.construct_event(body, sig_header, ENDPOINT_SECRET)

    # this lets us specify which event types we support
    case event[:type]
    when 'checkout.session.completed'
    # other types here
      event_to_class(event[:type]).perform_async(event[:id], event[:account])
    else
      Rails.logger.warn "Received a webhook for an unsupported event type: #{event[:type]}, event_id=#{event[:id]}, account=#{event[:account]}"
    end

    render json: {}, status: :no_content
  rescue JSON::ParserError => e
    render json: {}, status: :bad_request
  rescue Stripe::SignatureVerificationError => e
    render json: {}, status: :bad_request
  end

  def event_to_class(event_name)
    name = 'stripe/' + event_name.gsub('.', '_')
    constantize(camelize(name))
  end
end
