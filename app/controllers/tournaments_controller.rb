class TournamentsController < ApplicationController

  attr_accessor :tournament

  def index
    tournaments = Rails.env.development? ? Tournament.all.order(start_date: :asc)
                    :  Tournament.includes(:config_items).available.order(start_date: :asc)
    render json: TournamentSerializer.new(tournaments, params: url_options)
  end

  def show
    load_tournament
    unless tournament.present?
      render json: nil, status: 404
      return
    end
    set_time_zone
    if params[:serializer] == 'modern'
      render json: TournamentDetailSerializer.new(tournament, params: url_options)
    else
      render json: TournamentBlueprint.render(tournament, view: :detail, **url_options)
    end
  end

  private

  def load_tournament
    params.require(:identifier)
    id = params[:identifier]
    self.tournament = Tournament.includes(:config_items, :contacts, :testing_environment, :shifts, additional_questions: [:extended_form_field]).find_by_identifier(id)
  end
end
