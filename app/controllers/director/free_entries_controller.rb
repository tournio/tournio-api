# frozen_string_literal: true

module Director
  class FreeEntriesController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def index
      load_tournament
      unless tournament.present?
        skip_policy_scope
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :show?

      free_entries = policy_scope(tournament.free_entries).includes(bowler: :person).order(:unique_code)
      render json: FreeEntryBlueprint.render(free_entries, view: :director_list), status: :ok
    end

    def create
      load_tournament
      unless tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      entry_params = { tournament: tournament }.merge(free_entry_params)
      form_data = normalize_params(entry_params)
      free_entry = FreeEntry.new(form_data)
      unless free_entry.valid?
        render json: nil, status: :bad_request
        return
      end

      free_entry.save
      render json: FreeEntryBlueprint.render(free_entry, view: :director_list), status: :created
    end

    # def destroy
    #   # TODO: ensure that the person deleting this free entry can do things on the associated tournament
    #   FreeEntry.find(params[:id]).destroy
    #   render json: nil, status: 204
    # rescue ActiveRecord::RecordNotFound
    #   render json: nil, status: 404
    #   return
    # end
    #
    # # TODO: ensure that the person updating this free entry can do things on the associated tournament
    # def confirm
    #   free_entry = FreeEntry.find(params[:id])
    #   TournamentRegistration.confirm_free_entry(free_entry, current_user&.email)
    #   render json: FreeEntryBlueprint.render(free_entry.reload, view: :director_list), status: 200
    # rescue ActiveRecord::RecordNotFound
    #   render json: nil, status: 404
    #   return
    # end

    private

    attr_accessor :tournament

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
