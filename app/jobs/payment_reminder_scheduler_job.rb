class PaymentReminderSchedulerJob
  include Sidekiq::Job

  attr_accessor :tournament, :bowlers

  def perform(tournament_id)
    self.tournament = Tournament.includes(bowlers: [:ledger_entries]).find(tournament_id)
    find_relevant_bowlers
    bowlers.each do |b|
      email = Rails.env.production? ? b.email : MailerJob::FROM_ADDRESS
      PaymentReminderJob.perform_async(b.id, email)
    end
  rescue ActiveRecord::RecordNotFound
  end

  def find_relevant_bowlers
    self.bowlers = tournament.bowlers.filter { |b| TournamentRegistration.amount_due(b) > 0 }
  end
end
