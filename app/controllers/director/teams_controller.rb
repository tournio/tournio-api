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
      teams = if (params[:available_only])
                policy_scope(tournament.available_to_join)
              else
                policy_scope(tournament.teams).order('created_at asc')
              end
      render json: TeamBlueprint.render(teams, view: :director_list), status: :ok
    end

    # def show
    #   load_team_and_tournament
    #   unless @team.present? && @tournament.present?
    #     render json: nil, status: 404
    #     return
    #   end
    #   render json: TeamBlueprint.render(@team, view: :director_detail)
    # end
    #
    # def create
    #   load_tournament
    #   unless @tournament.present?
    #     render json: nil, status: 404
    #     return
    #   end
    #
    #   new_team_params = { tournament: @tournament }.merge(team_params)
    #   team = Team.new(new_team_params)
    #   unless team.valid?
    #     render json: nil, status: 400
    #     return
    #   end
    #
    #   # authorize team
    #   team.save
    #   render json: TeamBlueprint.render(team, view: :director_list), status: 201
    # end
    #
    # def update
    #   load_team_and_tournament
    #   unless @team.present? && @tournament.present?
    #     render json: nil, status: 404
    #     return
    #   end
    #
    #   # authorize team
    #   unless @team.update(edit_team_params)
    #     render json: nil, status: 400
    #     return
    #   end
    #
    #   render json: TeamBlueprint.render(@team, view: :director_detail), status: 200
    # end
    #
    # def destroy
    #   load_team_and_tournament
    #   unless @team.present? && @tournament.present?
    #     render json: nil, status: 404
    #     return
    #   end
    #
    #   # authorize team
    #   unless @team.destroy
    #     render json: nil, status: 400
    #     return
    #   end
    #
    #   render json: nil, status: 204
    # end

    private

    attr_accessor :tournament, :team

    def load_tournament
      id = params.require(:tournament_identifier)
      @tournament = Tournament.includes(:teams).find_by_identifier(id)
    end

    def load_team_and_tournament
      id = params.require(:identifier)
      @team = Team.includes(:tournament, bowlers: [:person, :free_entry]).find_by(identifier: id)
      @tournament = @team.tournament if @team.present?
    end

    def team_params
      params.require(:team).permit(:name).to_h.symbolize_keys
    end

    def edit_team_params
      params.require(:team).permit(
        :name,
        bowlers_attributes: %i[id position doubles_partner_id]
      ).to_h.with_indifferent_access
    end
  end
end
