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

  private

  attr_reader :tournament, :team, :bowler

  def load_team
    identifier = params.require(:team_identifier)
    @team = Team.find_by_identifier(identifier)
    unless @team.present?
      render json: nil, status: 404
      return
    end
    @tournament = team.tournament
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
