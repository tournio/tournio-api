class BowlersController < ApplicationController
  ADDITIONAL_QUESTION_RESPONSES_ATTRS = %i[
      name
      response
    ]
  PERSON_ATTRS = %i[
      first_name
      last_name
      usbc_id
      igbo_id
      birth_month
      birth_day
      nickname
      phone
      email
      address1
      address2
      city
      state
      country
      postal_code
    ].freeze
  BOWLER_ATTRS = [
    :position,
    :doubles_partner_num,
    person_attributes: PERSON_ATTRS,
    additional_question_responses: ADDITIONAL_QUESTION_RESPONSES_ATTRS,
  ].freeze

  ####################################

  def create
    load_team

    if team.bowlers.count == tournament.team_size
      render json: { message: 'This team is full.' }, status: :bad_request
      return
    end

    form_data = clean_up_bowler_data(bowler_params)
    bowler = bowler_from_params(form_data)

    unless bowler.valid?
      Rails.logger.info(bowler.errors.inspect)
      render json: bowler.errors, status: :unprocessable_entity
      return
    end

    bowler.save
    TournamentRegistration.register_bowler(bowler)

    render json: { identifier: bowler.identifier }, status: :created
  end

  def show
    load_bowler

    unless @bowler.present?
      render json: nil, status: :not_found
      return
    end

    result = {
      bowler: BowlerBlueprint.render_as_hash(bowler, view: :detail),
      available_items: rendered_purchasable_items_by_identifier,
    }
    sleep(3) if Rails.env.development?
    render json: result, status: :ok
  end

  def purchase_details
    # receive:
    # - bowler ID via params
    # - purchasable item IDs via request body
    # - unpaid purchase IDs via request body (return error if we think they're paid)
    # - expected total via request body (so we can proactively prevent purchase if we reach a different total,
    #  e.g., if they got the early discount upon registration but the date passed before they paid)
    #  ---- is that a thing we should enforce? survey directors to see what they think, add it later if they want it
    #
    # identifier: ... (bowler identifier)
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
    # return:
    #   - client ID (paypal identifier for tournament)
    #   - total to charge

    load_bowler
    unless bowler.present?
      render json: { error: 'Bowler not found' }, status: :not_found
      return
    end

    # permit and parse params (quantities come in as strings)
    params.permit!
    details = params.to_h
    details[:expected_total] = details[:expected_total].to_i
    details[:purchasable_items]&.each_index do |index|
      details[:purchasable_items][index][:quantity] = details[:purchasable_items][index][:quantity].to_i
    end

    # validate required ledger items (entry fee, early discount, late fee)
    purchase_identifiers = details[:purchase_identifiers] || []
    matching_purchases = bowler.purchases.unpaid.where(identifier: purchase_identifiers)
    unless purchase_identifiers.count == matching_purchases.count
      render json: { error: 'Mismatched unpaid purchases count' }, status: :precondition_failed
      return
    end
    purchases_total = matching_purchases.sum(&:amount)

    # gather purchasable items
    items = details[:purchasable_items] || []
    identifiers = items.collect { |i| i[:identifier] }
    purchasable_items = tournament.purchasable_items.where(identifier: identifiers).index_by(&:identifier)

    # does the number of items found match the number of identifiers passed in?
    unless identifiers.count == purchasable_items.count
      render json: { error: 'Mismatched number of purchasable item identifiers' }, status: :not_found
      return
    end

    # are we purchasing any single-use items that have been purchased previously?
    matching_previous_single_item_purchases = PurchasableItem.single_use.joins(:purchases)
                                                             .where(identifier: identifiers)
                                                             .where(purchases: { bowler_id: bowler.id })
                                                             .where.not(purchases: { paid_at: nil })
    unless matching_previous_single_item_purchases.empty?
      render json: { error: 'Attempting to purchase previously-purchased single-use item(s)' }, status: :precondition_failed
      return
    end

    # are we purchasing more than one of anything?
    multiples = items.filter { |i| i[:quantity] > 1 }
    # make sure they're all multi-use
    multiples.filter! do |i|
      identifier = i[:identifier]
      item = purchasable_items[identifier]
      !item.multi_use?
    end
    unless multiples.empty?
      render json: { error: 'Cannot purchase multiple instances of single-use items.'}, status: :unprocessable_entity
      return
    end

    # items_total = purchasable_items.sum(&:value)
    items_total = items.map do |item|
      identifier = item[:identifier]
      quantity = item[:quantity]
      purchasable_items[identifier].value * quantity
    end.sum

    # sum up the total of unpaid purchases and indicated purchasable items
    total_to_charge = purchases_total + items_total

    # Disallow a purchase if there's nothing owed
    if (total_to_charge == 0)
      render json: { error: 'Total to charge is zero' }, status: :precondition_failed
      return
    end

    # build response with client ID and total to charge
    output = {
      total: total_to_charge,
      paypal_client_id: tournament.paypal_client_id,
    }

    render json: output, status: :ok
  end

  private

  attr_reader :tournament, :team, :bowler

  def load_bowler
    identifier = params.require(:identifier)
    @bowler = Bowler.includes(:tournament, :person, :ledger_entries, :team, { purchases: [:purchasable_item] })
                    .where(identifier: identifier)
                    .first
    @tournament = bowler&.tournament
    @team = bowler&.team
  end

  def load_team
    identifier = params.require(:team_identifier)
    @team = Team.find_by_identifier(identifier)
    unless @team.present?
      render json: nil, status: 404
      return
    end
    @tournament = team.tournament
  end

  def rendered_purchasable_items_by_identifier
    excluded_item_names = bowler.purchases.single_use.collect { |p| p.purchasable_item.name }
    items = tournament.purchasable_items.user_selectable.where.not(name: excluded_item_names)
    items.each_with_object({}) { |i, result| result[i.identifier] = PurchasableItemBlueprint.render_as_hash(i) }
  end

  def clean_up_bowler_data(permitted_params)
    # Remove any empty person attributes
    permitted_params['person_attributes'].delete_if { |_k, v| v.length.zero? }

    # Person attributes: Convert integer params from string to integer
    %w[birth_month birth_day].each do |attr|
      permitted_params['person_attributes'][attr] = permitted_params['person_attributes'][attr].to_i
    end

    # Remove additional question responses that are empty
    permitted_params['additional_question_responses'].filter! { |r| r['response'].present? }

    # transform the add'l question responses into the shape that we can accept via ActiveRecord
    permitted_params['additional_question_responses_attributes'] =
      additional_question_responses(permitted_params['additional_question_responses'])

    # remove that key from the params...
    permitted_params.delete('additional_question_responses')

    permitted_params
  end

  # These are used only when adding a bowler to an existing team

  def bowler_from_params(info)
    partner = team.bowlers.without_doubles_partner.first

    bowler = Bowler.new(info.merge(team: team, tournament: tournament))
    bowler.doubles_partner = partner if partner.present?

    bowler
  end

  def bowler_params
    params.require(:bowler).permit(BOWLER_ATTRS).to_h.with_indifferent_access
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
end
