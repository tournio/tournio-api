# frozen_string_literal: true

module SendGrid
  class Bounce < EventHandler
    def handle_event
      # All we're going to do is hand the dirty work off to another job.
      BounceNotifierJob.perform_async(sendgrid_event.sg_event_id)
    end
  end
end
