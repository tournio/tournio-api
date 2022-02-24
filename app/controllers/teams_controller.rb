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
  TEAM_ATTRS = [
    :name,
    bowlers_attributes: BOWLER_ATTRS,
  ].freeze

  #####################
  # Controller actions
  #####################

  def create
    unless tournament.present?
      render json: nil, status: 404
      return
    end

    form_data = clean_up_form_data(team_params)
    team = team_from_params(form_data)

    unless team.valid?
      render json: team.errors, status: :unprocessable_entity
      return
    end

    TournamentRegistration.register_team(team)

    render json: TeamBlueprint.render(team.reload, view: :detail), status: :created
  end

  private

  attr_reader :tournament, :team

  def load_tournament
    params.require(:tournament_identifier)
    id = params[:tournament_identifier]
    @tournament = Tournament.find_by_identifier(id)
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

  # Remove keys whose values are blank
  # Remove associations whose values are blank
  def clean_up_form_data(permitted_params)
    cleaned_up = permitted_params.dup
    # cleaned_up['bowlers_attributes'].transform_keys!(&:to_i)
    cleaned_up['bowlers_attributes'].map! { |bowler_attrs| clean_up_bowler_data(bowler_attrs) }
    cleaned_up
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
