class TournamentsController < ApplicationController
  def index
    tournaments = Tournament.includes(:config_items).available.order(name: :asc)
    render json: TournamentBlueprint.render(tournaments, view: :list)
  end

  def show
    load_tournament
    unless @tournament.present?
      render json: nil, status: 404
      return
    end
    render json: TournamentBlueprint.render(@tournament, view: :detail)
  end

  private

  def load_tournament
    params.require(:identifier)
    id = params[:identifier]
    @tournament = Tournament.includes(:config_items, :contacts, :testing_environment, additional_questions: [:extended_form_field]).find_by_identifier(id)
  end
end
