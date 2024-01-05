# frozen_string_literal: true

module TournamentRegistration
  ENTRY_FEE_CONFIG_ITEM = :entry_fee
  LATE_FEE_CONFIG_ITEM = :late_fee
  DISPLAY_STATES = {
    setup: 'In setup',
    testing: 'Testing',
    active: 'Open for registration',
    closed: 'Closed',
    demo: 'Demonstration',
  }.freeze
  PURCHASABLE_ITEM_SORTING = {
    category: {
      ledger: 1,
      bowling: 100,
      sanction: 150,
      banquet: 200,
      product: 300,
      raffle: 400,
      bracket: 500,
    },
    determination: {
      entry_fee: 1,
      early_discount: 2,
      late_fee: 3,
      bundle_discount: 5,
      igbo: 9,
      event: 10,
      single_use: 11,
      multi_use: 12,
      apparel: 13,
      general: 14,
      handicap: 15,
      scratch: 16,
      usbc: 17,
    },
    refinement: {
      division: -1,
      event_linked: 1,
      single: 3,
      double: 4,
      trio: 5,
      team: 6,
      sized: 10,
    },
  }

  class IncompleteFreeEntry < StandardError
  end

  class FreeEntryAlreadyConfirmed < StandardError
  end

  class DeterminationAlreadyPresentException < Exception
  end

  def self.display_date(date)
    date.present? ? date.strftime('%Y %b %-d') : 'n/a'
  end

  def self.display_time(datetime:, tournament: nil)
    return 'n/a' unless datetime.present?

    timezone = tournament.present? ? tournament.timezone : 'America/New_York'
    datetime.in_time_zone(timezone).strftime('%b %-d %l:%M%P %Z')
  end

  def self.early_offset_time(datetime)
    datetime - 2.hours
  end

  def self.max_bowlers(tournament)
    tournament.team_size
  end

  def self.team_display_name(team)
    return 'n/a' if team.nil? || team.name.nil?
    return team.name unless team.name.blank?

    return 'n/a' if team.bowlers.empty?
    team.bowlers.collect(&:last_name).join(' / ')
  end

  def self.display_status(tournament)
    DISPLAY_STATES[tournament.aasm_state.to_sym]
  end

  def self.person_list_name(person)
    preferred_name = person.nickname.present? ? person.nickname : person.first_name
    "#{person.last_name}, #{preferred_name}"
  end

  def self.bowler_full_name(bowler)
    nickname = bowler.nickname
    display_nickname = nickname.present? ? "'#{nickname}'" : ''
    "#{bowler.first_name} #{display_nickname} #{bowler.last_name}".squish
  end

  def self.person_display_name(person)
    preferred_name = person.nickname.present? ? person.nickname : person.first_name
    "#{preferred_name} #{person.last_name}"
  end

  def self.bowler_paid?(bowler)
    TournamentRegistration.amount_due(bowler).zero?
  end

  def self.register_team(team)
    team.save

    team.bowlers.each { |b| register_bowler(b) }
  end

  def self.register_bowler(bowler, registration_type='new_team')
    complete_doubles_link(bowler) if bowler.doubles_partner_id.present?
    try_assigning_automatic_partners(bowler.team) if bowler.team.present?

    DataPoint.create(key: :registration_type, value: registration_type, tournament_id: bowler.tournament_id)

    send_confirmation_email(bowler)
    notify_registration_contacts(bowler)
  end

  def self.try_assigning_automatic_partners(team)
    unpartnered = team.bowlers.without_doubles_partner
    remaining_spots = team.tournament.team_size - team.bowlers.count
    return unless remaining_spots == 0 && unpartnered.count == 2

    unpartnered[0].doubles_partner = unpartnered[1]
    unpartnered[1].doubles_partner = unpartnered[0]
    unpartnered.map(&:save)
  end

  def self.amount_paid(bowler)
    (bowler.ledger_entries.stripe + bowler.ledger_entries.manual).sum(&:credit).to_i
  end

  def self.amount_due(bowler)
    tournament = bowler.tournament

    discount = tournament.in_early_registration? ? tournament.purchasable_items.early_discount.first.value : 0
    late_fee = tournament.in_late_registration? ? tournament.purchasable_items.late_fee.first.value : 0
    entry_fee = tournament.purchasable_items.entry_fee.first&.value.to_i

    ledger_amount_owed = 0
    unless bowler.free_entry&.confirmed?
      # This is what they'll owe having made no payments
      ledger_amount_owed = entry_fee + late_fee - discount

      # Minus any payments & discounts
      ledger_amount_owed -= (bowler.purchases.entry_fee + bowler.purchases.late_fee).sum(&:amount)
      ledger_amount_owed += bowler.purchases.early_discount.sum(&:amount)
    end

    # Here's where we can add unpaid optional items to the amount due

    ledger_amount_owed
  end

  def self.complete_doubles_link(bowler)
    return if bowler.doubles_partner.nil?

    partner = bowler.doubles_partner
    partner.update(doubles_partner_id: bowler.id) unless partner.doubles_partner_id.present?
  end

  def self.confirm_free_entry(free_entry, confirmed_by = nil)
    raise IncompleteFreeEntry unless free_entry.bowler.present?
    raise FreeEntryAlreadyConfirmed if free_entry.confirmed?

    # Later enhancement: do this in a transaction

    bowler = free_entry.bowler
    # This includes all mandatory items: entry fee, early-registration discount, late-registration fee
    affected_purchases = bowler.purchases.entry_fee + bowler.purchases.late_fee
    affected_discounts = bowler.purchases.early_discount + bowler.purchases.bundle_discount
    total_credit = affected_purchases.sum(&:value) - affected_discounts.sum(&:value)

    identifier = confirmed_by.present? ? "Free entry confirmed by #{confirmed_by}" : 'Free entry confirmed by no one'
    free_entry.update(confirmed: true)
    bowler.ledger_entries << LedgerEntry.new(credit: total_credit, identifier: identifier, source: :free_entry)

    affected_purchases.map { |p| p.update(paid_at: Time.zone.now) }
    affected_discounts.map { |p| p.update(paid_at: Time.zone.now) }

    free_entry.update(confirmed: true)
  end

  def self.send_confirmation_email(bowler)
    tournament = bowler.tournament
    if Rails.env.development? && !tournament.config[:email_in_dev]
      Rails.logger.info "========= Not sending confirmation email, dev config says not to."
      return
    end
    recipients = if notify_bowler?(tournament)
                   [bowler.email]
                 else
                   Rails.env.production? ? test_mode_notification_recipients(tournament) : [MailerJob::FROM]
                 end
    recipients.each { |r| RegistrationConfirmationNotifierJob.perform_async(bowler.id, r) }
  end

  def self.send_receipt_email(bowler, external_order_id)
    tournament = bowler.tournament
    if Rails.env.development? && !tournament.config[:email_in_dev]
      Rails.logger.info "========= Not sending receipt email, dev config says not to."
      return
    end
    recipient = if Rails.env.production?
                  tournament.active? || tournament.closed? ? bowler.email : tournament.contacts.treasurer.first&.email || tournament.contacts.payment_notifiable.first&.email
                elsif Rails.env.test?
                  MailerJob::FROM
                elsif tournament.config[:email_in_dev]
                  MailerJob::FROM
                end

    if recipient.present?
      PaymentReceiptNotifierJob.perform_async(external_order_id, recipient)
    end
  end

  def self.notify_registration_contacts(bowler)
    tournament = bowler.tournament
    if Rails.env.development? && !tournament.config[:email_in_dev]
      Rails.logger.info "========= Not sending new-registration email, dev config says not to."
      return
    end
    contacts = tournament.contacts.registration_notifiable.individually
    contacts.each do |c|
      email = Rails.env.production? ? c.email : MailerJob::FROM
      NewRegistrationNotifierJob.perform_async(bowler.id, email)
    end
  end

  def self.notify_payment_contacts(bowler, payment_identifier, amount, received_at)
    tournament = bowler.tournament
    if Rails.env.development? && !tournament.config[:email_in_dev]
      Rails.logger.info "========= Not sending new-payment email, dev config says not to."
      return
    end
    contacts = tournament.contacts.payment_notifiable.individually
    contacts.each do |c|
      recipient_email = Rails.env.production? ? c.email : MailerJob::FROM
      NewPaymentNotifierJob.perform_in(
        Rails.configuration.sidekiq_async_delay,
        bowler.id,
        payment_identifier,
        amount,
        received_at,
        recipient_email
      )
    end
  end

  def self.purchasable_item_sort(purchase_or_item)
    category = purchase_or_item.category
    determination = purchase_or_item.determination
    refinement = purchase_or_item.refinement
    [
      PURCHASABLE_ITEM_SORTING[:category][category.to_sym],
      determination.present? ? PURCHASABLE_ITEM_SORTING[:determination][determination.to_sym] : 0,
      refinement.present? ? PURCHASABLE_ITEM_SORTING[:refinement][refinement.to_sym] : 0,
      purchase_or_item&.configuration['order']&.to_i || 0,
    ].sum
  end

  def self.try_confirming_bowler_shift(bowler)
  end

  # Private methods

  def self.test_mode_notification_recipients(tournament)
    tournament.contacts.registration_notifiable.pluck(:email).uniq
  end

  def self.notify_bowler?(tournament)
    Rails.env.production? && tournament.active?
  end

  private_class_method :notify_bowler?
end
