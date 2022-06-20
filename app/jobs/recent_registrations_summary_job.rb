class RecentRegistrationsSummaryJob < TemplateMailerJob

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
    summary = RegistrationSummarySend.find_or_initialize_by(tournament: tournament)
    summary.last_sent_at = DateTime.new(2022, 3, 18, 8, 0, 0, '-4') unless summary.last_sent_at.present?
    summary
  end

  def load_bowlers(start_time, end_time)
    self.bowlers = tournament.bowlers.includes(:person, :team, :doubles_partner).where(created_at: start_time..end_time).order(:team_id, :created_at)
  end

  def sendgrid_template_id
    'd-4c5c841085074da5abefee9ba7c54670'
  end

  def personalization_data
    time_zone = tournament.config[:time_zone]

    {
      tournament_name: tournament.name,
      report_date: report_time.in_time_zone(time_zone).strftime('%F'),
      bowler_count: bowlers.count,
      bowlers: bowlers.collect do |bowler|
        {
          registered_at: bowler.created_at.in_time_zone(time_zone).strftime('%b %-d %l:%M%P %Z'),
          full_name: TournamentRegistration.bowler_full_name(bowler),
          email: bowler.email,
          usbc_id: bowler.usbc_id,
          # igbo_id: bowler.igbo_id,
          birthday: "#{bowler.birth_month}/#{bowler.birth_day}",
          team_name: bowler.team.present? ? bowler.team.name : 'n/a',
          team_order: bowler.position,
          doubles_partner: bowler.doubles_partner.present? ? TournamentRegistration.bowler_full_name(bowler.doubles_partner) : 'n/a',
          address1: bowler.address1,
          address2: bowler.address2,
          city: bowler.city,
          state: bowler.state,
          postal_code: bowler.postal_code,
          country: bowler.country
        }
      end
    }
  end
end
