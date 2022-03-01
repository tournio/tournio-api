class PurchasesController < ApplicationController
  def create
    # receive:
    # bowler_identifier ----------- obvious
    # purchase_identifiers: [], --- identifiers of required items (entry fee, etc)
    # purchasable_items: [  ------- optional items + quantities desired
    #   {
    #     identifier: ...,
    #     quantity: X,
    #   },
    #   ...
    # ],
    # paypal_details: -------------- structure returned by PayPal

    load_bowler
    unless bowler.present?
      render json: nil, status: :not_found
      return
    end

    # permit and parse params (quantities come in as strings)
    params.permit!
    details = params.to_h
    details[:purchasable_items]&.each_index do |index|
      details[:purchasable_items][index][:quantity] = details[:purchasable_items][index][:quantity].to_i
    end

    paid_at = Time.zone.now
    ppo = PaypalOrder.create(identifier: details[:paypal_details][:id], details: details[:paypal_details])

    purchase_identifiers = details[:purchase_identifiers] || []
    matching_purchases = bowler.purchases.unpaid.where(identifier: purchase_identifiers)
    total_credit = matching_purchases.sum(&:amount)
    matching_purchases.update_all(paid_at: paid_at, paypal_order_id: ppo.id)

    new_purchases = bowler.purchases.where(identifier: purchase_identifiers).to_a

    # gather purchasable items
    items = details[:purchasable_items] || []
    identifiers = items.collect { |i| i[:identifier] }
    purchasable_items = tournament.purchasable_items.where(identifier: identifiers).index_by(&:identifier)

    items.map do |item|
      identifier = item[:identifier]
      quantity = item[:quantity]
      item = purchasable_items[identifier]

      quantity.times do |i|
        new_purchases << Purchase.create(bowler: bowler,
                                         purchasable_item: item,
                                         amount: item.value,
                                         paid_at: paid_at,
                                         paypal_order: ppo
        )
        bowler.ledger_entries << LedgerEntry.new(debit: item.value, source: :purchase, identifier: item[:name])
        total_credit += item.value
      end
    end

    unless total_credit == 0
      bowler.ledger_entries << LedgerEntry.new(credit: total_credit, source: :paypal, identifier: details[:paypal_details][:id])
    end

    send_payment_notification_email(bowler.id, details[:paypal_details][:id], total_credit)
    send_receipt_email(bowler, ppo.identifier)

    if (new_purchases.empty?)
      render json: nil, status: :no_content
    else
      render json: PurchaseBlueprint.render(new_purchases), status: :created
    end
  end

  ####################################

  private

  attr_reader :tournament, :bowler

  def load_bowler
    identifier = params.require(:bowler_identifier)
    @bowler = Bowler.includes(:tournament, :person, :ledger_entries, { purchases: [:purchasable_item] })
                    .where(identifier: identifier)
                    .first
    @tournament = bowler&.tournament
  end

  def send_payment_notification_email(bowler_id, payment_identifier, amount, received_at = Time.zone.now)
    recipients = if Rails.env.production?
                   payment_notification_recipients
                 else
                   [MailerWorker::FROM]
                 end
    recipients.each { |r| NewPaymentNotifierWorker.perform_async(bowler_id, payment_identifier, amount, received_at, r) }
  end

  def payment_notification_recipients
    tournament.contacts.payment_notifiable.pluck(:email).uniq
  end

  def send_receipt_email(bowler, paypal_order_identifier)
    recipient = if Rails.env.production?
                  tournament.active? ? bowler.email : tournament.contacts.treasurer.first
                else
                  MailerWorker::FROM
                end
    PaymentReceiptNotifierWorker.perform_async(paypal_order_identifier, recipient)
  end
end
