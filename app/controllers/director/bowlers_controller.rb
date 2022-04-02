# frozen_string_literal: true

module Director
  class BowlersController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

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

    def index
      load_tournament
      unless tournament.present?
        skip_policy_scope
        render json: nil, status: :not_found
        return
      end
      authorize tournament, :show?
      bowlers = policy_scope(tournament.bowlers).includes(:person, :free_entry, :team).order('people.last_name')
      sleep(3) if Rails.env.development?
      render json: BowlerBlueprint.render(bowlers, view: :director_list), status: :ok
    end

    def show
      load_bowler_and_tournament
      unless bowler.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :show?
      sleep(5) if Rails.env.development?
      render json: BowlerBlueprint.render(bowler, view: :director_detail)
    end

    def update
      load_bowler_and_tournament
      unless bowler.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      try_updating_details
      try_updating_additional_question_responses
      try_reassigning
      # try_linking_free_entry

      if error.present?
        render json: {error: error}, status: :bad_request
        return
      end

      render json: BowlerBlueprint.render(bowler.reload, view: :director_detail)
    end

    def destroy
      load_bowler_and_tournament
      unless bowler.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?
      bowler.destroy
      render json: nil, status: :no_content
    end

    private

    attr_accessor :tournament, :bowler, :error

    def load_tournament
      id = params.require(:tournament_identifier)
      @tournament = Tournament.find_by_identifier(id)
    end

    def load_bowler_and_tournament
      id = params.require(:identifier)
      @bowler = Bowler.includes(:purchases,
                                :ledger_entries,
                                :additional_question_responses,
                                :team,
                                :person,
                                :free_entry,
                                doubles_partner: :person,
                                tournament: [:additional_questions],
      ).find_by(identifier: id)
      @tournament = @bowler.tournament if @bowler.present?
    end

    def bowler_params
      params.require(:bowler).permit(team: %i(identifier),
                                     person_attributes: PERSON_ATTRS,
                                     additional_question_responses: %i(name response),
                                     verified_data: %i(verified_average handicap),
      )
            .to_h.with_indifferent_access
    end

    def try_reassigning
      bowler_data = bowler_params
      return unless bowler_data[:team].present?

      new_team = tournament.teams.find_by(identifier: bowler_data[:team][:identifier])
      unless new_team.present?
        self.error = 'Could not find the specified team.'
        return
      end

      unless new_team.bowlers.count < tournament.team_size
        self.error = 'The specified team is full.'
        return
      end

      DirectorUtilities.reassign_bowler(bowler: bowler, to_team: new_team)
    end

    def try_updating_details
      bowler_data = bowler_params

      # First, update bowler deets
      if bowler_data[:verified_data].present?
        bowler.verified_data.merge!(bowler_data[:verified_data])
        unless bowler.save
          self.error = bowler.errors.full_messages
          return
        end
      end

      # Next, update person deets, if there are any
      return unless bowler_data[:person_attributes].present?

      unless bowler.person.update(bowler_data[:person_attributes])
        self.error = bowler.person.errors.full_messages
      end
    end

    def try_updating_additional_question_responses
      bowler_data = bowler_params
      return false unless bowler_data[:additional_question_responses].present?

      bowler_data[:additional_question_responses].each do |aqr_data|
        next unless aqr_data[:response].present?

        aqr = bowler.additional_question_responses.joins(:extended_form_field).where(extended_form_field: {name: aqr_data[:name]}).first

        unless aqr.present?
          self.error = "Unrecognized additional question: #{aqr_data[:name]}"
          return
        end

        unless aqr.update(response: aqr_data[:response])
          self.error = bowler.person.errors.full_messages
          return
        end
      end
    end
  end
end
