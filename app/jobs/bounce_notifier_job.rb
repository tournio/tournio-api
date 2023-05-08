# frozen_string_literal: true

class BounceNotifierJob
  include Sidekiq::Job

  def perform(sendgrid_event_id)
    sg_event = SendGridEvent.find(sendgrid_event_id)

    # now what?
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "Unable to find SendGridEvent with ID=#{sendgrid_event_id}"
  end
end
