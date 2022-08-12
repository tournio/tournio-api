class TournamentsController < ApplicationController

  attr_accessor :tournament

  def index
    tournaments = Tournament.includes(:config_items).available.order(start_date: :asc)
    render json: TournamentBlueprint.render(tournaments, view: :list, **url_options)
  end

  def show
    load_tournament
    unless tournament.present?
      render json: nil, status: 404
      return
    end
    set_time_zone
    render json: TournamentBlueprint.render(tournament, view: :detail, **url_options)
  end

  private

  def load_tournament
    params.require(:identifier)
    id = params[:identifier]
    self.tournament = Tournament.includes(:config_items, :contacts, :testing_environment, :shifts, additional_questions: [:extended_form_field]).find_by_identifier(id)
  end
end
