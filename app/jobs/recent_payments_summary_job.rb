class RecentPaymentsSummaryJob < TemplateMailerJob

  attr_accessor :recipient, :tournament, :bowlers, :report_time

  def perform(tournament_id, recipient_email = FROM_ADDRESS, range_end = Time.zone.now)
    # For the given tournament, look up their last summary send time.
    self.tournament = Tournament.find(tournament_id)
    self.report_time = range_end
    summary_send = find_summary_send

    # find all bowlers created in the time range
    load_bowlers(summary_send.last_sent_at, range_end)

    # Don't send if there are no bowlers to notify about
    return unless bowlers.any?

    # build template data
    #  -- done in personalization_data

    # Who gets it?
    self.recipient = recipient_email

    # send email
    send

    # update summary_send
    summary_send.update(last_sent_at: range_end, bowler_count: bowlers.count)
  end

  def to_address
    recipient
  end

  def find_summary_send
    summary = PaymentSummarySend.find_or_initialize_by(tournament: tournament)
    summary.last_sent_at = DateTime.new(2022, 3, 18, 8, 0, 0, '-4') unless summary.last_sent_at.present?
    summary
  end

  def load_bowlers(start_time, end_time)
    self.bowlers = tournament.bowlers.joins(:person, :ledger_entries).where(ledger_entries: { created_at: start_time..end_time })
  end

  def sendgrid_template_id
    'd-b4d63e62486942f29915800ed881217c'
  end

  def personalization_data
    timezone = tournament.timezone

    {
      tournament_name: tournament.name,
      report_date: report_time.in_time_zone(timezone).strftime('%F'),
      bowler_count: bowlers.count,
      bowlers: bowlers.collect do |bowler|
        {
          full_name: TournamentRegistration.bowler_full_name(bowler),
          ledger_entries: bowler.ledger_entries.stripe.collect do |entry|
            {
              identifier: entry.identifier,
              amount: entry.credit.to_i,
              paid_at: entry.created_at.strftime('%F %r')
            }
          end
        }
      end
    }
  end
end
