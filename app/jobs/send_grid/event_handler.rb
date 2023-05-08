# frozen_string_literal: true

module SendGrid
  class EventHandler
    include Sidekiq::Job

    attr_accessor :sendgrid_event

    def perform(sg_event_id, email_address, timestamp)
      # ensure idempotency; we may receive this webhook event multiple times
      unless SendGridEvent.exists?(sg_event_id)
        self.sendgrid_event = SendGridEvent.create(
          sg_event_id: sg_event_id,
          email: email_address,
          event_timestamp: timestamp
        )
        handle_event
      end
    end

    def handle_event
      raise NotImplementedError
    end
  end
end
