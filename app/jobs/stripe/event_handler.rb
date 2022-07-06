module Stripe
  class EventHandler
    include Sidekiq::Job

    attr_accessor :event

    def perform(event_id, stripe_account_id)
      self.event = Stripe::Event.retrieve(event_id, {stripe_account: stripe_account_id})
      handle_event
    rescue StripeError => e
      Rails.logger.warn "Failed to retrieve Stripe event! #{event_id}"
      Rails.logger.warn "Why? #{e.inspect}"
    end

    def handle_event
      raise NotImplementedError
    end
  end
end
