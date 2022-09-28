class DeleteOldStripeEventsJob
  include Sidekiq::Job

  def perform
    StripeEvent.where(created_at: ..7.days.ago).destroy_all
  end
end
