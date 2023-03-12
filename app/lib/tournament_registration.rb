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
    },
    determination: {
      entry_fee: 1,
      early_discount: 2,
      late_fee: 3,
      bundle_discount: 4,
      discount_expiration: 5,
      igbo: 9,
      event: 10,
      single_use: 11,
      multi_use: 12,
    },
    refinement: {
      division: -1,
      denomination: 1,
      input: 2,
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
    return team.name unless team.name.blank?

    team.bowlers.collect(&:last_name).join(' / ')
  end

  def self.display_status(tournament)
    DISPLAY_STATES[tournament.aasm_state.to_sym]
  end

  def self.person_display_name(person)
    preferred_name = person.nickname.present? ? person.nickname : person.first_name
    "#{person.last_name}, #{preferred_name}"
  end

  def self.bowler_full_name(bowler)
    nickname = bowler.nickname
    display_nickname = nickname.present? ? "'#{nickname}'" : ''
    "#{bowler.first_name} #{display_nickname} #{bowler.last_name}".squish
  end

  def self.bowler_paid?(bowler)
    TournamentRegistration.amount_due(bowler).zero?
  end

  def self.register_team(team)
    team.save

    team.bowlers.each { |b| register_bowler(b) }

    link_doubles_partners(team.bowlers)
  end

  def self.register_bowler(bowler, registration_type='new_team')
    purchase_entry_fee(bowler)
    add_early_discount_to_ledger(bowler)
    add_late_fees_to_ledger(bowler)
    complete_doubles_link(bowler) if bowler.doubles_partner_id.present?

    DataPoint.create(key: :registration_type, value: registration_type, tournament_id: bowler.tournament_id)

    send_confirmation_email(bowler)
    notify_registration_contacts(bowler)
  end

  def self.purchase_entry_fee(bowler)
    entry_fee_item = bowler.tournament.purchasable_items.entry_fee.first
    return unless entry_fee_item.present?

    entry_fee = entry_fee_item.value
    bowler.ledger_entries << LedgerEntry.new(debit: entry_fee, identifier: 'entry fee') if entry_fee.positive?

    bowler.purchases << Purchase.new(purchasable_item: entry_fee_item)
  end

  def self.add_early_discount_to_ledger(bowler, current_time = Time.zone.now)
    tournament = bowler.tournament
    return unless tournament.in_early_registration?(current_time)

    early_discount_item = tournament.purchasable_items.early_discount&.first
    return unless early_discount_item.present?

    early_discount = early_discount_item.value
    bowler.ledger_entries << LedgerEntry.new(credit: early_discount, identifier: 'early registration')
    bowler.purchases << Purchase.new(purchasable_item: early_discount_item)
  end

  def self.add_late_fees_to_ledger(bowler)
    tournament = bowler.tournament
    return unless tournament.in_late_registration?

    # tournament late fee
    late_fee_item = tournament.purchasable_items.late_fee.where(refinement: nil).first
    return unless late_fee_item.present?

    late_fee = late_fee_item.value
    bowler.ledger_entries << LedgerEntry.new(debit: late_fee, identifier: 'late registration')
    bowler.purchases << Purchase.new(purchasable_item: late_fee_item)
  end

  def self.add_discount_expiration_to_ledger(bowler, purchasable_item)
    bowler.ledger_entries << LedgerEntry.new(debit: purchasable_item.value, identifier: 'discount expiration')
    bowler.purchases << Purchase.new(purchasable_item: purchasable_item)
  end

  def self.amount_billed(bowler)
    bowler.ledger_entries.sum(&:debit).to_i - (bowler.ledger_entries.registration + bowler.ledger_entries.purchase).sum(&:credit).to_i
  end

  def self.amount_paid(bowler)
    (bowler.ledger_entries.stripe + bowler.ledger_entries.manual).sum(&:credit).to_i
  end

  def self.amount_due(bowler)
    (bowler.ledger_entries.sum(&:debit) - bowler.ledger_entries.sum(&:credit)).to_i
  end

  def self.link_doubles_partners(bowlers)
    bowlers.each do |bowler|
      partner_num = bowler.doubles_partner_num.to_i
      next unless partner_num.present? && partner_num.positive?

      target_index = bowlers.index { |b| b.position == partner_num }
      next if target_index.nil?

      bowler.doubles_partner = bowlers[target_index]
      bowler.save
    end
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

    # affected_purchases = bowler.purchases.ledger
    # total_credit = affected_purchases.sum(&:value)

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

  def self.purchasable_item_sort(purchase_or_item)
    PURCHASABLE_ITEM_SORTING[:category][purchase_or_item&.category&.to_sym] +
      PURCHASABLE_ITEM_SORTING[:determination][purchase_or_item&.determination&.to_sym] +
      (PURCHASABLE_ITEM_SORTING[:refinement][purchase_or_item&.refinement&.to_sym] || 0) +
      (purchase_or_item&.configuration['order']&.to_i || 0)
  end

  def self.try_confirming_bowler_shift(bowler)
    return unless bowler.shift.present?
    return if bowler.bowler_shift.confirmed?
    unpaid_fees = bowler.purchases.ledger.unpaid.any? || bowler.purchases.event.unpaid.any?
    return if unpaid_fees
    return if bowler.shift.confirmed >= bowler.shift.capacity

    confirm_shift(bowler)
  end

  def self.confirm_shift(bowler)
    bowler.bowler_shift.confirm!
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
