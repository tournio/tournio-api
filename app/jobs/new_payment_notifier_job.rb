# frozen_string_literal: true

class NewPaymentNotifierJob < MailerJob
  include ActionView::Helpers::NumberHelper

  attr_accessor :recipient, :bowler, :tournament, :payment_identifier, :amount, :received_at

  def perform(bowler_id, payment_identifier, amount, received_at_ts, recipient_email)
    self.recipient = recipient_email
    return unless recipient.present?

    self.payment_identifier = payment_identifier
    self.amount = amount

    self.bowler = Bowler.includes(:tournament, :person).find_by(id: bowler_id)
    return unless bowler.present?

    self.tournament = bowler.tournament

    timezone = tournament.timezone
    self.received_at = Time.at(received_at_ts).in_time_zone(timezone).strftime('%b %-d %l:%M%P %Z')

    send
  end

  def subject
    'New tournament payment received'
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

  def text_body
    <<~HEREDOC
      #{tournament.name} has received a new payment!

      Received at: #{received_at}

      Bowler: #{TournamentRegistration.person_list_name(bowler)}
      Amount: #{number_to_currency(amount, precision: 0)}
      Payment identifier: #{payment_identifier}
    HEREDOC
  end

  def html_body
    <<~HEREDOC
      <h4>
        #{tournament.abbreviation} has received a new payment!
      </h4>

      <p>
        Received at: #{received_at}
      </p>

      <p>
        Bowler: #{TournamentRegistration.person_list_name(bowler)}
        <br />
        Amount: #{number_to_currency(amount, precision: 0)}
        <br />
        Payment identifier: #{payment_identifier}
      </p>
    HEREDOC
  end
end
