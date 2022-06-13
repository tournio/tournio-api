# frozen_string_literal: true

class PaymentReceiptNotifierJob < TemplateMailerJob
  include ActionView::Helpers::NumberHelper

  attr_accessor :recipient, :paypal_order, :bowler, :tournament, :purchases

  def perform(paypal_order_identifier, recipient_email)
    self.recipient = recipient_email
    return unless recipient.present?

    self.paypal_order = PaypalOrder.includes(purchases: [:purchasable_item, { bowler: [:person, tournament: [:contacts]] }]).find_by(identifier: paypal_order_identifier)
    return unless paypal_order.present?

    self.purchases = paypal_order.purchases

    self.bowler = purchases.first&.bowler
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
      bowler_preferred_name: bowler.nickname || bowler.first_name,
      bowler_full_name: TournamentRegistration.bowler_full_name(bowler),
      receipt_date: paypal_order.created_at.strftime('%Y %b %-d %r'),
      order_identifier: paypal_order.identifier,
      order_total: number_to_currency(purchases.sum(&:amount), precision: 0),
      treasurer_contact: treasurer_contact,
      items: populate_item_list(purchases),
      tournament_url: tournament_page,
    }
    data
  end

  def populate_item_list(purchases)
    purchasable_items = {}
    counts = purchases.each_with_object({}) do |p, c|
      pi_id = p.purchasable_item_id
      if c[pi_id].present?
        c[pi_id] += 1
      else
        c[pi_id] = 1
        purchasable_items[pi_id] = p.purchasable_item
      end
    end

    counts.each_with_object([]) do |(pi_id, count), c|
      pi = purchasable_items[pi_id]
      item = {
        item_name: pi.name,
        item_value: number_to_currency(pi.value, precision: 0),
        item_quantity: count,
        item_total: number_to_currency(pi.value * count, precision: 0),
      }
      item[:item_details] = if pi.division?
                              "Division: #{pi.configuration['division']}"
                            elsif pi.denomination?
                              pi.configuration['denomination']
                            end
      c << item
    end
  end

  def sendgrid_template_id
    'd-45ab8a2fca7b4ccf893d733fff019c47'
  end

  def subject
    'Receipt for tournament payment'
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

  def tournament_page
    if Rails.env.production?
      "https://www.igbo-reg.com/bowlers/#{bowler.identifier}"
    else
      "http://localhost:3000/bowlers/#{bowler.identifier}"
    end
  end
end
