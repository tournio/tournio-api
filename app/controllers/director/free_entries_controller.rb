# frozen_string_literal: true

module Director
  class FreeEntriesController < BaseController
    def index
      load_tournament
      unless @tournament.present?
        render json: nil, status: 404
        return
      end
      free_entries = @tournament.free_entries.includes(bowler: :person).order(:unique_code)
      render json: FreeEntryBlueprint.render(free_entries, view: :director_list)
    end

    def create
      load_tournament
      unless @tournament.present?
        render json: nil, status: 404
        return
      end

      entry_params = { tournament: @tournament }.merge(free_entry_params)
      form_data = normalize_params(entry_params)
      free_entry = FreeEntry.new(form_data)
      unless free_entry.valid?
        render json: nil, status: 400
        return
      end

      # authorize @free_entry
      free_entry.save
      render json: FreeEntryBlueprint.render(free_entry, view: :director_list), status: 201
    end

    def destroy
      # TODO: ensure that the person deleting this free entry can do things on the associated tournament
      FreeEntry.find(params[:id]).destroy
      render json: nil, status: 204
    rescue ActiveRecord::RecordNotFound
      render json: nil, status: 404
      return
    end

    # TODO: ensure that the person updating this free entry can do things on the associated tournament
    def confirm
      free_entry = FreeEntry.find(params[:id])
      TournamentRegistration.confirm_free_entry(free_entry, current_user&.email)
      render json: FreeEntryBlueprint.render(free_entry.reload, view: :director_list), status: 200
    rescue ActiveRecord::RecordNotFound
      render json: nil, status: 404
      return
    end

    private

    def load_tournament
      id = params.require(:tournament_identifier)
      @tournament = Tournament.find_by_identifier(id)
    end

    def free_entry_params
      params.require(:free_entry).permit([:unique_code, :confirmed]).to_h.symbolize_keys
    end

    def normalize_params(permitted)
      permitted[:unique_code] = permitted[:unique_code].upcase
      permitted
    end
  end
end
