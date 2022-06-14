# frozen_string_literal: true

class RegistrationConfirmationNotifierJob < TemplateMailerJob
  include ActionView::Helpers::NumberHelper

  attr_accessor :recipient, :bowler, :tournament

  def perform(bowler_id, recipient_email)
    self.recipient = recipient_email
    return unless recipient.present?

    self.bowler = Bowler.includes(:tournament, :doubles_partner, :team, :additional_question_responses).find_by(id: bowler_id)
    return unless bowler.present?

    self.tournament = bowler.tournament

    send
  end

  def to_address
    recipient
  end

  def personalization_data
    data = {
      tournament_name: tournament.name,
      tournament_year: tournament.year,
      preferred_name: bowler.nickname || bowler.first_name,
      secretary_email: secretary_contact,
      bowler_full_name: TournamentRegistration.bowler_full_name(bowler),
      usbc_id: bowler.usbc_id,
      # igbo_id: bowler.igbo_id,
      birth_month: bowler.birth_month,
      birth_day: bowler.birth_day,
      address1: bowler.address1,
      address2: bowler.address2,
      city: bowler.city,
      state: bowler.state,
      postal_code: bowler.postal_code,
      country: bowler.country,
      phone: bowler.phone,
      email: bowler.email,
      amount_due: amount_due_text,
      payment_url: payment_page,
      additional_questions: [],
      event_selection: tournament.config['event_selection'],
    }
    if team_info.any?
      data.merge!({
        team_name: team_info[:name],
        team_order: team_info[:position],
      })
    end
    if bowler.doubles_partner.present?
      data[:doubles_partner] = TournamentRegistration.bowler_full_name(bowler.doubles_partner)
    end
    if bowler.additional_question_responses.any?
      data[:additional_questions] = bowler.additional_question_responses.collect { |r| { question: r.label, response: r.response } }
    end
    data
  end

  def sendgrid_template_id
    'd-30d25c83a97647dd9e7a563962f1d9b5'
  end

  def subject
    'Your tournament registration was received'
  end

  def reply_to
    secretary_contact
  end

  def secretary_contact
    if Rails.env.production?
      (tournament.contacts.secretary.first || tournament.contacts.registration_notifiable.first).email
    else
      FROM_ADDRESS
    end
  end

  def payment_page
    if Rails.env.production?
      "https://www.igbo-reg.com/bowlers/#{bowler.identifier}"
    else
      "http://localhost:3000/bowlers/#{bowler.identifier}"
    end
  end

  def team_info
    @team_info ||= if bowler.team.present?
                     {
                       name: TournamentRegistration.team_display_name(bowler.team),
                       position: bowler.position,
                     }
                   else
                     {}
                   end
  end

  def amount_due_text
    @amount_due_text ||= number_to_currency(TournamentRegistration.amount_due(bowler).to_i, precision: 0)
  end
end
