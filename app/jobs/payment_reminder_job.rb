# frozen_string_literal: true

class PaymentReminderJob < TemplateMailerJob
  include ActionView::Helpers::NumberHelper

  attr_accessor :recipient, :bowler, :tournament

  def perform(bowler_id, recipient_email = MailerJob::FROM_ADDRESS)
    self.recipient = recipient_email
    return unless recipient.present?

    self.bowler = load_bowler_details(bowler_id)
    return unless bowler.present?

    self.tournament = bowler.tournament

    send
  end

  def load_bowler_details(bowler_id)
    Bowler.includes(:tournament, :purchases, :ledger_entries).find(bowler_id)
  rescue ActiveRecord::RecordNotFound
  end

  def to_address
    recipient
  end

  def personalization_data
    data = {
      tournament_name: tournament.name,
      bowler_name: bowler.nickname || bowler.first_name,
      amount_due: TournamentRegistration.amount_due(bowler),
      payment_url: payment_page,
      entry_deadline: tournament.entry_deadline.strftime('%B %-d')
    }
    data
  end

  def sendgrid_template_id
    'd-9dcb36f188ca4ec1959d2bedea75ca8c'
  end

  def subject
    'Tournament fee reminder'
  end

  def reply_to
    treasurer_contact
  end

  def treasurer_contact
    if Rails.env.production?
      tournament.contacts.treasurer.first&.email || tournament.contacts.payment_notifiable.first&.email || tournament.contacts.registration_notifiable.first&.email
    else
      FROM_ADDRESS
    end
  end

  def payment_page
    "#{link_hostname}/bowlers/#{bowler.identifier}"
  end
end
