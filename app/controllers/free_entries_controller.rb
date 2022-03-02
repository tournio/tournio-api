class FreeEntriesController < ApplicationController
  def create
    load_bowler
    load_tournament

    unless bowler.present? && tournament.present?
      render json: nil, status: :not_found
      return
    end

    unless tournament.id == bowler.tournament_id
      render json: nil, status: :not_found
      return
    end

    if bowler.free_entry.present?
      render json: { error: "You already have a free entry." }, status: :conflict
      return
    end

    load_free_entry

    if free_entry.bowler_id.present?
      render json: { error: "The code provided has already been claimed." }, status: :conflict
      return
    end

    free_entry.bowler = bowler
    free_entry.save

    body = {
      message: "We've received your free entry code, pending confirmation by the tournament directors.",
      unique_code: free_entry.unique_code,
    }
    render json: body, status: :created
  end

  private

  attr_reader :tournament, :bowler, :free_entry

  def load_bowler
    identifier = params.require(:bowler_identifier)
    @bowler = Bowler.includes(:tournament, :free_entry)
                    .where(identifier: identifier)
                    .first
  end

  def load_tournament
    tournament_identifier = params.require(:tournament_identifier)
    @tournament = Tournament.find_by(identifier: tournament_identifier)
  end

  def load_free_entry
    code = params.require(:unique_code).upcase
    @free_entry = FreeEntry.find_or_create_by(unique_code: code, tournament: tournament)
  end
end
