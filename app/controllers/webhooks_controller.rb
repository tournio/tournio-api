class WebhooksController < ApplicationController
  include ActiveSupport::Inflector

  wrap_parameters false

  STRIPE_ENDPOINT_SECRET = ENV['STRIPE_WEBHOOK_KEY']
  SENDGRID_WEBHOOK_VERIFICATION_KEY = ENV['SENDGRID_WEBHOOK_SIGNATURE_KEY']

  def stripe
    event = build_stripe_event

    # this lets us specify which event types we support
    case event[:type]
    when 'checkout.session.completed',
      'checkout.session.expired',
      'account.updated',
      'charge.refunded'
      # other types here
      event_to_class('stripe', event[:type]).perform_async(event[:id], event[:account])
    else
      Rails.logger.warn "Received a webhook for an unsupported Stripe event type: #{event[:type]}, event_id=#{event[:id]}, account=#{event[:account]}"
    end

    render json: {}, status: :no_content
  rescue JSON::ParserError => e
    Bugsnag.notify(e)
    render json: {}, status: :bad_request
  rescue Stripe::SignatureVerificationError => e
    Bugsnag.notify(e)
    render json: {}, status: :bad_request
  end

  def sendgrid
    verify_sendgrid_signature
    Rails.logger.info "Signature verified, can proceed with event handling"

    events = parse_sendgrid_events

    events.each do |event|
      case event['event']
      when 'bounce'
        # other types here
        event_to_class('send_grid', event['event']).perform_async(
          event['sg_event_id'],
          event['email'],
          event['timestamp']
        )
      else
        Rails.logger.warn "Received a webhook for an unsupported event type: #{event['event']}, event_id=#{event['sg_event_id']}, email=#{event['email']}"
      end
    end
  rescue SendGrid::EventWebhook::Error => e
    render json: { error: 'Failed to verify signature' }, status: :bad_request
  end

  def build_stripe_event
    body = request.body.read
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']

    Stripe::Webhook.construct_event(body, sig_header, STRIPE_ENDPOINT_SECRET)
  end

  def verify_sendgrid_signature
    webhook = SendGrid::EventWebhook.new
    converted_key = webhook.convert_public_key_to_ecdsa(SENDGRID_WEBHOOK_VERIFICATION_KEY)

    raise SendGrid::EventWebhook::Error unless webhook.verify_signature(
      converted_key,
      request.body.read,
      request.headers[SendGrid::EventWebhookHeader::SIGNATURE],
      request.headers[SendGrid::EventWebhookHeader::TIMESTAMP]
    )
  end

  def parse_sendgrid_events
    JSON.parse(request.body.read)
  end

  def event_to_class(namespace, event_name)
    name = namespace + '/' + event_name.gsub('.', '_')
    constantize(camelize(name))
  end
end
