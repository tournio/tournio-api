class TeamsController < ApplicationController
  before_action :load_tournament, except: %i[show]

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
    :doubles_partner_index,
    :shift_identifier,
    person_attributes: PERSON_ATTRS,
    additional_question_responses: ADDITIONAL_QUESTION_RESPONSES_ATTRS,
  ].freeze
  TEAM_ATTRS = [
    :name,
    :initial_size,
    :shift_identifier,
    bowlers_attributes: BOWLER_ATTRS,
    options: {},
  ].freeze

  #####################
  # Controller actions
  #####################

  def create
    unless tournament.present?
      Rails.logger.warn "========= Tried to create a team with a bad tournament id: #{params[:tournament_identifier]}"
      render json: nil, status: 404
      return
    end

    form_data = clean_up_form_data(team_params)
    team = team_from_params(form_data)

    unless team.valid?
      Rails.logger.warn "======== Invalid team created. Errors: #{team.errors.full_messages}"
      render json: team.errors, status: :unprocessable_entity
      return
    end

    TournamentRegistration.register_team(team)

    team.bowlers.includes(:person, :ledger_entries).order(:position)
    # render json: TeamDetailedSerializer.new(team, within: {bowlers: {doubles_partner: :doubles_partner}}).serialize, status: :created
    render json: TeamBlueprint.render(team, view: :detail), status: :created
  end

  def index
    unless tournament.present?
      render json: nil, status: 404
      return
    end
    teams = tournament.teams.order('LOWER(name)')
    render json: TeamBlueprint.render(teams, view: :list)
  end

  def show
    load_team
    unless team.present?
      render json: nil, status: 404
      return
    end
    # TODO Does this do what I think it does?
    # team.bowlers.includes(:person, :ledger_entries).order(:position)

    # render json: TeamDetailedSerializer.new(team, within: {bowlers: {doubles_partner: :doubles_partner}}).serialize
    render json: TeamBlueprint.render(team, view: :detail)
  end

  private

  attr_reader :tournament, :team

  def load_tournament
    params.require(:tournament_identifier)
    id = params[:tournament_identifier]
    @tournament = Tournament.find_by_identifier(id)
  end

  def load_team
    identifier = params.require(:identifier)
    @team = Team.includes(bowlers: [:person, :ledger_entries]).find_by_identifier(identifier)
  end

  #######################
  # Input processing
  #######################

  def team_params
    params.require(:team).permit(TEAM_ATTRS).to_h.with_indifferent_access
  end

  def team_from_params(info)
    team = Team.new(info)
    team.tournament = tournament
    team.bowlers.map do |b|
      b.tournament = tournament
    end
    team
  end

  def clean_up_form_data(permitted_params)
    cleaned_up = permitted_params.dup
    cleaned_up['bowlers_attributes'].map! { |bowler_attrs| clean_up_bowler_data(bowler_attrs) }

    shift = Shift.find_by(identifier: permitted_params['shift_identifier'])
    cleaned_up['shift_id'] = shift.id unless shift.nil?
    cleaned_up.delete('shift_identifier')

    cleaned_up
  end

  # TODO: This is a good candidate for consolidation, since it's essentially repeated from BowlersController
  def clean_up_bowler_data(permitted_params)
    # Remove any empty person attributes
    permitted_params['person_attributes'].delete_if { |_k, v| v.length.zero? }

    # strip leading and trailing whitespace from email, in case they managed to sneak some in
    permitted_params['person_attributes'][:email].strip! if permitted_params['person_attributes'][:email].present?

    # Person attributes: Convert integer params from string to integer
    %w[birth_month birth_day].each do |attr|
      permitted_params['person_attributes'][attr] = permitted_params['person_attributes'][attr].to_i
    end
    permitted_params['position'] = permitted_params['position'].to_i if permitted_params['position'].present?

    # Remove additional question responses that are empty
    permitted_params['additional_question_responses'].filter! { |r| r['response'].present? }

    # transform the add'l question responses into the shape that we can accept via ActiveRecord
    permitted_params['additional_question_responses_attributes'] =
      additional_question_responses(permitted_params['additional_question_responses'])

    # remove that key from the params...
    permitted_params.delete('additional_question_responses')

    # If there's a shift identifier, insert the corresponding id to take advantage of AR nested attributes
    # TODO: Remove this entirely once we have placeholder teams working fully
    if permitted_params['shift_identifier'].present?
      shift = Shift.find_by(identifier: permitted_params['shift_identifier'])
      permitted_params['bowler_shift_attributes'] = { shift_id: shift.id } unless shift.nil?
      permitted_params.delete('shift_identifier')
    end

    permitted_params
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

