# frozen_string_literal: true

module Director
  class BowlersController < BaseController
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
      unless @tournament.present?
        render json: nil, status: 404
        return
      end
      bowlers = @tournament.bowlers.includes(:person, :free_entry, :team).order('people.last_name')
      render json: BowlerBlueprint.render(bowlers, view: :director_list)
    end

    def show
      load_bowler_and_tournament
      unless @bowler.present?
        render json: nil, status: 404
        return
      end

      render json: BowlerBlueprint.render(@bowler, view: :director_detail)
    end

    def update
      load_bowler_and_tournament
      unless @bowler.present?
        render json: nil, status: 404
        return
      end

      try_updating_details
      try_reassigning
      # try_linking_free_entry

      render json: BowlerBlueprint.render(@bowler.reload, view: :director_detail)
    end

    def destroy
      load_bowler_and_tournament
      unless @bowler.present?
        render json: nil, status: 404
        return
      end

      @bowler.destroy
      render json: nil, status: 204
    end

    private

    def load_tournament
      id = params.require(:tournament_identifier)
      @tournament = Tournament.find_by_identifier(id)
      render json: nil, status: 404 unless @tournament.present?
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
      params.require(:bowler).permit(team: :identifier,
                                     person_attributes: PERSON_ATTRS)
            .to_h.with_indifferent_access
    end

    # def new_team_params
    def try_reassigning
      new_team = bowler_params
      return false if new_team.empty?

      new_team = @tournament.teams.find_by(identifier: new_team[:identifier])
      return false unless new_team.present?

      DirectorUtilities.reassign_bowler(bowler: @bowler, to_team: new_team)
    end

    def try_updating_details
      bowler_data = bowler_params
      return if bowler_data.empty?
      @bowler.person.update(bowler_data[:person_attributes])
    end
  end
end
