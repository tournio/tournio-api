# frozen_string_literal: true

module Director
  class TeamsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def index
      load_tournament
      unless @tournament.present?
        skip_policy_scope
        render json: nil, status: :not_found
        return
      end
      authorize tournament, :show?
      teams = if (params[:partial])
                policy_scope(tournament.available_to_join)
              else
                policy_scope(tournament.teams).order('created_at asc')
              end
      sleep(1) if Rails.env.development?
      render json: TeamBlueprint.render(teams, view: :director_list), status: :ok
    end

    def show
      load_team_and_tournament
      unless team.present? && tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end
      authorize tournament, :show?
      sleep(1) if Rails.env.development?
      render json: TeamBlueprint.render(team, view: :director_detail)
    end

    def create
      load_tournament
      unless tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      new_team_params = { tournament: tournament }.merge(team_params)
      team = Team.new(new_team_params)
      unless team.valid?
        render json: nil, status: :bad_request
        return
      end

      team.save
      render json: TeamBlueprint.render(team, view: :director_list), status: :created
    end

    def update
      load_team_and_tournament
      unless team.present? && tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament
      new_values = edit_team_params

      unless positions_valid?(new_values)
        render json: { errors: ['Positions must be unique across the team'] }, status: :bad_request
        return
      end

      confirmed_change = 0
      requested_change = 0
      confirmed_at = nil
      previous_shift = nil
      new_shift = nil
      shift_change = false
      if new_values[:shift_team_attributes].present?
        previous_shift = team.shift
        new_shift = Shift.find(new_values[:shift_team_attributes][:shift_id])
        if previous_shift != new_shift
          shift_change = true
          if team.shift_team.confirmed_at.present?
            confirmed_at = team.shift_team.confirmed_at
            confirmed_change = team.bowlers.count
          else
            requested_change = team.bowlers.count
          end
        end
      end
      unless team.update(new_values)
        render json: { errors: team.errors.full_messages }, status: :bad_request
        return
      end

      if shift_change # we've changed shifts
        if confirmed_at.present?
          team.reload.shift_team.update(confirmed_at: confirmed_at, aasm_state: :confirmed)
        end
        previous_shift.update(
          confirmed: previous_shift.confirmed - confirmed_change,
          requested: previous_shift.requested - requested_change
        )
        new_shift.update(
          confirmed: new_shift.confirmed + confirmed_change,
          requested: new_shift.requested + requested_change
        )
      end

      render json: TeamBlueprint.render(team.reload, view: :director_detail), status: :ok
    end

    def confirm_shift
      load_team_and_tournament
      unless team.present? && tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?
      TournamentRegistration.confirm_shift(team)

      render json: TeamBlueprint.render(team.reload, view: :director_detail), status: :ok
    end

    def destroy
      load_team_and_tournament
      unless team.present? && tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      if team.shift.present?
        size = team.bowlers.count
        if team.shift_team.confirmed_at.present?
          team.shift.update(confirmed: team.shift.confirmed - size)
        else
          team.shift.update(requested: team.shift.requested - size)
        end
      end

      unless team.destroy
        render json: nil, status: :bad_request
        return
      end

      render json: nil, status: :no_content
    end

    private

    attr_accessor :tournament, :team

    def load_tournament
      id = params.require(:tournament_identifier)
      @tournament = Tournament.includes(:teams).find_by_identifier(id)
    end

    def load_team_and_tournament
      id = params.require(:identifier)
      @team = Team.includes(:tournament, bowlers: [:person, :free_entry]).find_by(identifier: id)
      @tournament = team.tournament if team.present?
    end

    def team_params
      params.require(:team).permit(:name).to_h.symbolize_keys
    end

    def edit_team_params
      permitted = params.require(:team).permit(
        :name,
        :shift, # this is a shift identifier
        bowlers_attributes: %i[id position doubles_partner_id]
      ).to_h.with_indifferent_access

      desired_shift = tournament.shifts.find_by(identifier: permitted[:shift])
      unless desired_shift.nil?
        permitted[:shift_team_attributes] = { shift_id: desired_shift.id }
      end
      permitted.delete(:shift)
      permitted
    end

    def positions_valid?(proposed_values)
      positions = proposed_values[:bowlers_attributes].collect { |attrs| attrs[:position] }
      positions.count == positions.uniq.count
    end
  end
end
