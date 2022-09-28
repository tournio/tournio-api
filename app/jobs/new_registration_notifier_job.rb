class NewRegistrationNotifierJob < TemplateMailerJob

  attr_accessor :recipient, :tournament, :bowler

  def perform(bowler_id, recipient_email = FROM_ADDRESS)
    # Who gets it?
    self.recipient = recipient_email

    # Load up the bowler's information
    load_bowler(bowler_id)

    # send email
    send

  end

  def to_address
    recipient
  end

  def load_bowler(bowler_id)
    self.bowler = Bowler.includes(:tournament, :person, :team, :doubles_partner).find(bowler_id)
    self.tournament = bowler.tournament
  end

  def sendgrid_template_id
    'd-19e9e69888b64276afa1a4a215e4df61'
  end

  def personalization_data
    timezone = tournament.timezone

    {
      tournament_name: tournament.name,
      bowler: {
        registered_at: bowler.created_at.in_time_zone(timezone).strftime('%b %-d %l:%M%P %Z'),
        full_name: TournamentRegistration.bowler_full_name(bowler),
        email: bowler.email,
        usbc_id: bowler.usbc_id,
        # igbo_id: bowler.igbo_id,
        birthday: "#{bowler.birth_month}/#{bowler.birth_day}",
        team_name: bowler.team&.name || 'n/a',
        team_order: bowler.position || 'n/a',
        doubles_partner: bowler.doubles_partner.present? ? TournamentRegistration.bowler_full_name(bowler.doubles_partner) : 'n/a',
        address1: bowler.address1,
        address2: bowler.address2,
        city: bowler.city,
        state: bowler.state,
        postal_code: bowler.postal_code,
        country: bowler.country,
      }
    }
  end
end
