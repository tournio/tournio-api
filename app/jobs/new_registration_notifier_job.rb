# frozen_string_literal: true

class NewRegistrationNotifierJob < MailerJob
  attr_accessor :recipient, :bowler, :tournament

  def perform(bowler_id, recipient_email)
    self.recipient = recipient_email
    return unless recipient.present?

    self.bowler = Bowler.includes(:tournament, :doubles_partner, :team, :free_entry).find_by(id: bowler_id)
    return unless bowler.present?

    self.tournament = bowler.tournament

    send
  end

  def subject
    'New tournament registration received'
  end

  def to_address
    recipient
  end

  def pre_send
    super
    mail.add_content(Content.new(
      type: 'text/plain',
      value: text_body
    ))
    mail.add_content(Content.new(
      type: 'text/html',
      value: html_body
    ))
  end

  def registered_at
    time_zone = tournament.config[:time_zone]
    @registered_at ||= bowler.created_at.in_time_zone(time_zone).strftime('%b %-d %l:%M%P %Z')
  end

  def team_info
    @team_info ||= {
      name: TournamentRegistration.team_display_name(bowler.team),
      position: bowler.position,
    }
  end

  def doubles_text
    @doubles_text ||= if bowler.doubles_partner.present?
                        "Doubles partner: #{TournamentRegistration.person_display_name(bowler.doubles_partner)}"
                      else
                        ''
                      end
  end

  def text_body
    team_text = <<~HEREDOC
      Team: #{team_info[:name]}
      Team Order: #{team_info[:position]}
    HEREDOC

    <<~HEREDOC
      Your tournament has received a new registration!

      Registration time: #{registered_at}

      Tournament: #{tournament.name}
      Bowler: #{TournamentRegistration.person_display_name(bowler)}
      Preferred Name: #{bowler.nickname || 'n/a'}

      Address: #{bowler.address1} #{bowler.address2}
               #{bowler.city}, #{bowler.state} #{bowler.postal_code}
               #{bowler.country}
      Phone: #{bowler.phone}
      Email: #{bowler.email}
      USBC ID: #{bowler.usbc_id}
      IGBO ID: #{bowler.igbo_id}
      Birth date: #{bowler.birth_month}/#{bowler.birth_day}

      #{team_text}

      #{doubles_text}
    HEREDOC
  end

  def html_body
    team_text = <<~HEREDOC
      <p>
        Team: #{team_info[:name]}
        <br />
        Team Order: #{team_info[:position]}
      </p>
    HEREDOC
    doubles = if doubles_text.empty?
                ''
              else
                <<~HEREDOC
                  <p>
                    #{doubles_text}
                  </p>
                HEREDOC
              end
    <<~HEREDOC
      <h4>
        Your tournament has received a new registration!
      </h4>

      <p>
        Registration time: #{registered_at}
      </p>

      <p>
        Tournament: #{tournament.name}
        <br />
        Bowler: #{TournamentRegistration.person_display_name(bowler)}
        <br />
        Preferred Name: #{bowler.nickname || 'n/a'}
      </p>

      <p>
        Address:
        <address>
          #{bowler.address1} #{bowler.address2}
          <br />
          #{bowler.city}, #{bowler.state} #{bowler.postal_code}
          <br />
          #{bowler.country}
        </address
      </p>
      <p>
        Phone: #{bowler.phone}
        <br />
        Email: #{bowler.email}
        <br />
        USBC ID: #{bowler.usbc_id}
        <br />
        IGBO ID: #{bowler.igbo_id}
        <br />
        Birth date: #{bowler.birth_month}/#{bowler.birth_day}
      </p>

      #{team_text}

      #{doubles}
    HEREDOC
  end
end
