class BowlersController < ApplicationController
  wrap_parameters false

  before_action :load_bowler, only: %i(commerce stripe_checkout)

  # gives us attributes: tournament, stripe_account
  include StripeUtilities

  ADDITIONAL_QUESTION_RESPONSES_ATTRS = %i[
      name
      response
    ]
  PERSON_ATTRS = %i[
      first_name
      last_name
      usbc_id
      birth_month
      birth_day
      birth_year
      nickname
      phone
      email
      address1
      address2
      city
      state
      country
      postal_code
      payment_app
    ].freeze
  BOWLER_ATTRS = [
    :position,
    :doubles_partner_num,
    :doubles_partner_identifier,
    shift_identifiers: [],
    person_attributes: PERSON_ATTRS,
    additional_question_responses: ADDITIONAL_QUESTION_RESPONSES_ATTRS,
  ].freeze

  ####################################
  def show
    redirect_to action: "commerce", identifier: params[:identifier], status: :moved_permanently
  end

  def index
    permit_params

    identifier = parameters[:tournament_identifier]
    if identifier.present?
      @tournament = Tournament.includes(bowlers: [:person, :team, doubles_partner: [:person]]).find_by_identifier(identifier)
    end

    unless tournament.present?
      render json: nil, status: :not_found
      return
    end

    list = parameters[:unpartnered].present? ? tournament.bowlers.without_doubles_partner : tournament.bowlers
    render json: ListBowlerSerializer.new(list, within: {
      doubles_partner: :doubles_partner,
      team: :team,
    }), status: :ok
  end

  def create
    permit_params
    load_team

    identifier = parameters[:tournament_identifier]
    if identifier.present?
      @tournament = Tournament.includes(:config_items).find_by_identifier(identifier)
    end

    # the tournament should be loaded either by association with the team, or finding by its identifier
    unless tournament.present?
      render json: nil, status: :not_found
      return
    end

    form_data = clean_up_bowler_data(parameters.require(:bowlers))
    bowlers = []
    form_data.each do |data|
      a_bowler = bowler_from_params(data)
      unless a_bowler.valid?
        Rails.logger.info(a_bowler.errors.inspect)
        render json: a_bowler.errors, status: :unprocessable_entity
        return
      end
      bowlers << a_bowler
    end

    registration_type = 'solo'

    # adding a bowler to a team (standard) or doing a doubles pair registration
    if bowlers.count == 2
      registration_type = 'new_pair'
    elsif team.present?
      registration_type = 'standard'
      bowlers.each do |b|
        b.team = team
      end
    end

    bowlers.each do |b|
      b.save
      TournamentRegistration.register_bowler(b, registration_type)
      b.reload
    end

    # When creating a doubles pair only
    if bowlers.count == 2
      bowlers[0].doubles_partner = bowlers[1]
      bowlers[1].doubles_partner = bowlers[0]
      bowlers.map(&:save)
    elsif team.present? && team.bowlers.count == tournament.team_size
      # automatically pair up the last two bowlers
      # TODO: only if there's a team event (which we don't handle separately yet)
      unpartnered = team.bowlers.without_doubles_partner
      if unpartnered.count == 2
        unpartnered[0].doubles_partner = unpartnered[1]
        unpartnered[1].doubles_partner = unpartnered[0]
        unpartnered.map(&:save)
      end
    end

    render json: BowlerBlueprint.render(bowlers, view: :detail), status: :created
    # render json: BowlerSerializer.new(bowlers), status: :created
  end

  def commerce
    unless bowler.present?
      render json: nil, status: :not_found
      return
    end

    signupables = bowler.signups.map { |s| SignupableSerializer.new(s.purchasable_item, params: { signup: s }).as_json }

    available_item_categories = %i(banquet product sanction raffle)
    available_item_determinations = %i(event_linked bundle_discount)
    available_items = tournament.purchasable_items.
      where(category: available_item_categories).or(
      tournament.purchasable_items.where(category: :ledger, determination: available_item_determinations)
    )

    result = {
      bowler: ListBowlerSerializer.new(bowler, within: {doubles_partner: :doubles_partner}).as_json,
      freeEntry: bowler.free_entry.present? ? FreeEntrySerializer.new(bowler.free_entry).as_json : nil,
      team: bowler.team.present? ? TeamSerializer.new(bowler.team).as_json : nil,
      tournament: TournamentSerializer.new(tournament, params: url_options).as_json,
      purchases: PurchaseSerializer.new(bowler.purchases.paid).as_json,
      availableItems: PurchasableItemSerializer.new(available_items).as_json,
      automaticItems: PurchasableItemSerializer.new(automatic_items).as_json,
      signupables: signupables,
    }
    render json: result, status: :ok
  end

  class PurchaseError < RuntimeError
    attr_reader :http_status

    def initialize(msg, status)
      super(msg)
      @http_status = status
    end
  end

  def stripe_checkout
    unless bowler.present?
      render json: { error: 'Bowler not found' }, status: :not_found
      return
    end

    unless tournament.config[ConfigItem::Keys::ACCEPT_PAYMENTS]
      render json: { error: 'The tournament is no longer accepting online payments.' }, status: :bad_request
      return
    end

    load_stripe_account

    # permit and parse params (quantities come in as strings)
    params.permit!
    details = params.to_h

    process_purchase_details(details)

    session = {}
    if Rails.env.development? && tournament.config[ConfigItem::Keys::SKIP_STRIPE] || tournament.testing? || tournament.demo?
      finish_checkout_without_stripe
      session[:id] = "pretend_checkout_session_#{bowler.id}_#{Time.zone.now.strftime('%FT%T')}"
      session[:url] = "/bowlers/#{bowler.identifier}/finish_checkout"
      bowler.stripe_checkout_sessions << StripeCheckoutSession.new(identifier: session[:id], status: :completed)
    else
      # Now, we can build out the line items for the Stripe checkout session
      # matching_purchases -- all the unpaid purchases (entry fee, late fee, and early discount)
      # item_quantities -- an array of hashes, with identifier and quantity as keys
      # purchasable_items -- all the additional items being bought, indexed by identifier
      # applicable_fees -- Any event-linked fees that apply, e.g., late fees
      # applicable_discounts -- Any event-linked or bundle discounts that apply

      session = stripe_checkout_session
      bowler.stripe_checkout_sessions << StripeCheckoutSession.new(identifier: session[:id])
    end

    output = {
      redirect_to: session[:url],
      checkout_session_id: session[:id],
    }
    render json: output, status: :ok
  rescue PurchaseError => e
    render json: { error: e.message }, status: e.http_status
  end

  private

  attr_reader :team,
    :bowler,
    :parameters,

    :applicable_discounts, # An array of PurchasableItems representing event-linked discounts (early-registration, bundle)
    :applicable_fees, # An array of PurchasableItems representing late fees (currently, only event-linked late fees)
    :purchasable_items,
    :item_quantities,
    :total_to_charge

  def permit_params
    @parameters = params.permit(
      :identifier, # this is the tournament identifier for #bowlers.create
      :team_identifier,
      :tournament_identifier,
      :unpartnered,
      bowlers: BOWLER_ATTRS
    )
  end

  def load_bowler
    identifier = params.require(:identifier)
    @bowler = Bowler.includes(:tournament, :person, :ledger_entries, :team, {
      purchases: [:purchasable_item],
      signups: [:purchasable_item],
    })
                    .find_by(identifier: identifier)
    unless bowler.blank?
      @tournament = bowler.tournament
      @team = bowler&.team
    end
  end

  def load_team
    identifier = parameters[:team_identifier]
    if identifier.present?
      @team = Team.find_by_identifier(identifier)
      @tournament = team&.tournament
    end
  end

  def automatic_items
    # Free entry means no automatic items
    return [] if bowler.free_entry.present? || bowler.purchases.paid.entry_fee.any?

    # Start with all ledger items the bowler hasn't already paid for
    purchased_item_ids = bowler.purchases.collect(&:purchasable_item_id)
    items = tournament.purchasable_items.ledger.where.not(id: purchased_item_ids)

    # Remove early discounts if they don't apply
    unless tournament.in_early_registration?
      # remove any early discounts
      items -= tournament.purchasable_items.early_discount
    end

    # Remove late fees if they don't apply
    if !tournament.in_late_registration? || bowler.purchases.paid.entry_fee.any?
      # remove any late fees
      items -= tournament.purchasable_items.late_fee
    end

    # Remove any waived items
    waived_items = bowler.waivers.collect(&:purchasable_item)
    items -= waived_items

    # event-linked fees and discounts will be here, if applicable, but that's ok. We want them
    # there, and will handle their addition appropriately. This implies that "automatic" means
    # "every time" only for standard tournaments.

    # ready to go
    items
  end

  def clean_up_bowler_data(permitted_params)
    permitted_params.each do |p|
      # Remove any empty person attributes
      p['person_attributes'].delete_if { |_k, v| v.to_s.length.zero? }

      # strip leading and trailing whitespace from email, in case they managed to sneak some in
      p['person_attributes'][:email].strip! if p['person_attributes'][:email].present?

      # Person attributes: Convert integer params from string to integer
      %w[birth_month birth_day birth_year].each do |attr|
        p['person_attributes'][attr] = p['person_attributes'][attr].to_i
      end
      p['position'] = p['position'].to_i if p['position'].present?

      # Remove additional question responses that are empty
      p['additional_question_responses'].filter! { |r| r['response'].present? }

      # transform the add'l question responses into the shape that we can accept via ActiveRecord
      p['additional_question_responses_attributes'] =
        additional_question_responses(p['additional_question_responses'])

      # remove that key from the params...
      p.delete('additional_question_responses')

      # If we've specified a doubles partner, then look them up by identifier and put their id in the params
      if p['doubles_partner_identifier'].present?
        partner = Bowler.where(identifier: p['doubles_partner_identifier'], doubles_partner_id: nil).first
        p['doubles_partner_id'] = partner.id unless partner.nil?
        p.delete('doubles_partner_identifier')
      end

      # We allow solo bowlers to specify their preferred shift, when applicable
      if p['shift_identifiers']
        p['shifts'] = Shift.where(identifier: p['shift_identifiers'])
        p.delete('shift_identifiers')
      end
    end

    permitted_params
  end

  # These are used only when adding a bowler to an existing team

  def bowler_from_params(info)
    Bowler.new(info.merge(team: team, tournament: tournament))
  end

  def additional_question_responses(params)
    params.each_with_object([]) do |response_param, collected|
      collected << {
        response: response_param['response'],
        extended_form_field_id: extended_form_fields[response_param['name']].id,
      }
    end
  end

  def extended_form_fields
    @extended_form_fields ||= ExtendedFormField.all.index_by(&:name)
  end

  # in details:
  #
  # purchase_identifiers: [],
  # purchasable_items: [
  #   {
  #     identifier: ...,
  #     quantity: X,
  #   },
  #   ...
  # ],
  # expected_total:
  #
  # this method sets and populates the following class attributes:
  # - matching_purchases -- the unpaid purchases that have matching identifiers in details[purchase_identifiers]
  # - item_quantities -- an array of hashes, containing purchasable item identifiers and the quantity of each
  # - purchasable_items -- a collection of purchasable items, indexed by their identifiers
  #
  # Just a heads-up: discounts are included in these collections
  def process_purchase_details(details)
    details[:expected_total] = details[:expected_total].to_i
    details[:purchasable_items]&.each_index do |index|
      details[:purchasable_items][index][:quantity] = details[:purchasable_items][index][:quantity].to_i
    end

    # Separate out any automatic things
    automatic_item_identifiers = details[:automatic_items] || []
    applicable_automatic_items = automatic_items.filter { |ai| automatic_item_identifiers.include? ai.identifier }
    @applicable_discounts = applicable_automatic_items.filter { |ai| ai.early_discount? || ai.bundle_discount? }
    @applicable_fees = applicable_automatic_items.filter { |ai| ai.entry_fee? || ai.late_fee? }

    # gather purchasable items
    @item_quantities = details[:purchasable_items] || []
    identifiers = item_quantities.collect { |i| i[:identifier] }
    @purchasable_items = tournament.purchasable_items.where(identifier: identifiers).index_by(&:identifier)

    # does the number of items found match the number of identifiers passed in?
    unless identifiers.count == purchasable_items.count
      raise PurchaseError.new('Mismatched number of purchasable item identifiers', :not_found)
    end

    # are we attempting to purchase any single-use item_quantities that have been purchased previously?
    # ... because we shouldn't.
    matching_previous_single_item_purchases = PurchasableItem.single_use.joins(:purchases)
                                                             .where(identifier: identifiers)
                                                             .where(purchases: { bowler_id: bowler.id })
                                                             .where.not(purchases: { paid_at: nil })
    unless matching_previous_single_item_purchases.empty?
      raise PurchaseError.new('Attempting to purchase previously-purchased single-use item(s)', :precondition_failed)
    end

    # are we purchasing more than one of anything?
    multiples = item_quantities.filter { |i| i[:quantity] > 1 }
    # make sure none of them is one-time
    multiples.filter! do |i|
      identifier = i[:identifier]
      item = purchasable_items[identifier]
      item.one_time?
    end
    unless multiples.empty?
      raise PurchaseError.new('Cannot purchase multiple instances of one-time items.', :unprocessable_entity)
    end

    # @bundle-discounts Restore this here
    # apply any relevant event bundle discounts
    # bundle_discount_items = tournament.purchasable_items.bundle_discount
    # previous_paid_event_item_identifiers = bowler.purchases.event.paid.map { |p| p.purchasable_item.identifier }
    # @applicable_discounts += bundle_discount_items.select do |discount|
    #   (identifiers + previous_paid_event_item_identifiers).intersection(discount.configuration['events']).length == discount.configuration['events'].length
    # end

    total_discount = applicable_discounts.sum(&:value)

    # apply any relevant event-linked late fees
    # late_fee_items = tournament.purchasable_items.late_fee.event_linked
    # @applicable_fees = late_fee_items.select do |fee|
    #   identifiers.include?(fee.configuration['event']) && tournament.in_late_registration?(event_linked_late_fee: fee)
    # end
    total_fees = applicable_fees.sum(&:value)

    # items_total = purchasable_items.sum(&:value)
    items_total = item_quantities.map do |item|
      identifier = item[:identifier]
      quantity = item[:quantity]
      purchasable_items[identifier].value * quantity
    end.sum

    # sum up the total of unpaid purchases and indicated purchasable items
    @total_to_charge = items_total + total_discount + total_fees

    # Disallow a purchase if there's nothing owed
    if total_to_charge == 0
      raise PurchaseError.new('Total to charge is zero', :precondition_failed)
    end
  end

  def stripe_checkout_session
    session_params = {
      success_url: "#{client_host}/bowlers/#{bowler.identifier}/finish_checkout",
      cancel_url: "#{client_host}/bowlers/#{bowler.identifier}",
      mode: 'payment',
      submit_type: 'pay',
    }.merge(build_checkout_session_items(
      applicable_fees,
      applicable_discounts,
      purchasable_items,
      item_quantities
    ))

    create_stripe_checkout_session(session_params)
  end

  def create_stripe_checkout_session(session_params)
    Stripe::Checkout::Session.create(
      session_params,
      {
        stripe_account: stripe_account.identifier,
      },
    )
  rescue Stripe::StripeError => e
    Rails.logger.warn "Stripe error: #{e}"
    Bugsnag.notify(e)
  end

  def finish_checkout_without_stripe
    total_credit = 0
    extp = ExternalPayment.create(
      details: {},
      identifier: "pretend_stripe_payment_#{Time.zone.now.strftime('%FT%T')}",
      payment_type: :stripe,
      tournament_id: tournament.id
    )

    # new purchases, items, events, etc.
    #  -- create purchases and ledger entries, and mark them as paid
    item_quantities.each do |iq|
      pi = purchasable_items[iq[:identifier]]
      iq[:quantity].times do |_|
        bowler.purchases << Purchase.create(
          purchasable_item: pi,
          amount: pi.value,
          paid_at: Time.zone.now,
          external_payment_id: extp.id
        )

        bowler.ledger_entries << LedgerEntry.new(
          debit: pi.value,
          source: :purchase,
          identifier: pi.name
        )
        total_credit += pi.value
      end

      # mark any related Signups as paid
      signup = bowler.signups.find_by(purchasable_item_id: pi.id)
      if signup.present?
        signup.pay!

        # if it's a division item, disable the rest
        if pi.division?
          tournament.purchasable_items.division.where(name: pi.name).map do |div_pi|
            unless div_pi.id == pi.id
              bowler.signups.find_by_purchasable_item_id(div_pi.id).deactivate!
            end
          end
        end
      end
    end

    # applicable fees
    applicable_fees.each do |pi|
      bowler.purchases << Purchase.create(
        purchasable_item: pi,
        amount: pi.value,
        paid_at: Time.zone.now,
        external_payment_id: extp.id
      )

      bowler.ledger_entries << LedgerEntry.new(
        debit: pi.value,
        source: :purchase,
        identifier: pi.name
      )
      total_credit += pi.value
    end

    applicable_discounts.each do |pi|
      bowler.purchases << Purchase.create(
        purchasable_item: pi,
        amount: pi.value,
        paid_at: Time.zone.now,
        external_payment_id: extp.id
      )

      bowler.ledger_entries << LedgerEntry.new(
        credit: pi.value,
        source: :purchase,
        identifier: pi.name
      )
      total_credit -= pi.value
    end

    bowler.ledger_entries << LedgerEntry.new(
      credit: total_credit,
      source: :stripe,
      identifier: 'pretend_stripe_payment',
    )
  end
end
