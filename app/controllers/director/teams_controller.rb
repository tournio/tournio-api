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
                policy_scope(tournament.partial)
              else
                policy_scope(tournament.teams).order('created_at asc')
              end

      hashed_teams = teams.map { |b| TeamBlueprint.render_as_hash(b, view: :director_list, **url_options) }
      hashed_teams.sort_by! { |h| h[:name] }

      render json: hashed_teams, status: :ok
    end

    def show
      load_team_and_tournament
      unless team.present? && tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end
      authorize tournament, :show?
      # render json: TeamBlueprint.render(team, view: :director_detail)
      render json: TeamDetailedSerializer.new(team)
    end

    def create
      load_tournament
      unless tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      team = Team.new({ tournament: tournament }.merge(new_team_params))
      unless team.valid?
        render json: nil, status: :bad_request
        return
      end

      team.save
      render json: TeamBlueprint.render(team, view: :director_list), status: :created
    end

    class InsufficientCapacityError < ::StandardError
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

      unless team.update(new_values)
        render json: { errors: team.errors.full_messages }, status: :bad_request
        return
      end

      render json: TeamBlueprint.render(team.reload, view: :director_detail), status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: nil, status: :not_found
    rescue InsufficientCapacityError => e
      render json: { error: 'Insufficient space remaining' }, status: :conflict
    end

    def destroy
      load_team_and_tournament
      unless team.present? && tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

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

    def new_team_params
      parameters = params.require(:team).permit(
        :name,
        shift_identifiers: [],
      ).to_h.symbolize_keys

      parameters[:shifts] = Shift.where(identifier: parameters[:shift_identifiers])
      parameters.delete(:shift_identifiers)

      parameters
    end

    def edit_team_params
      parameters = params.require(:team).permit(
        :name,
        shift_identifiers: [],
        bowlers_attributes: %i[id position doubles_partner_id],
      ).to_h.with_indifferent_access

      parameters[:shifts] = Shift.where(identifier: parameters[:shift_identifiers])
      raise ActiveRecord::RecordNotFound unless parameters[:shift_identifiers].blank? || parameters[:shifts].count == parameters[:shift_identifiers].count
      parameters.delete(:shift_identifiers)

      parameters
    end

    def positions_valid?(proposed_values)
      positions = proposed_values[:bowlers_attributes]&.collect { |attrs| attrs[:position] }
      positions.nil? || positions.count == positions.uniq.count
    end
  end
end
