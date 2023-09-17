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

      free_entries = if params[:unassigned]
                       policy_scope(tournament.free_entries.unassigned).includes(bowler: :person).order(:unique_code)
                     else
                       policy_scope(tournament.free_entries).includes(bowler: :person).order(:unique_code)
                     end
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

    def destroy
      fe = FreeEntry.find_by!(identifier: params[:identifier])

      authorize fe.tournament, :update?

      if fe.confirmed
        render json: { error: 'Cannot delete a confirmed free entry' }, status: :conflict
        return
      end

      fe.destroy
      render json: nil, status: :no_content
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
      return
    end

    def update
      free_entry = FreeEntry.includes(:tournament).find_by!(identifier: params[:identifier])
      tournament = free_entry.tournament
      authorize free_entry.tournament, :update?

      if free_entry.confirmed?
        render json: nil, status: :conflict
        return
      end

      if params[:bowler_identifier].present?
        bowler = tournament.bowlers.find_by(identifier: params[:bowler_identifier])
        unless bowler.present?
          render json: nil, status: :not_found
          return
        end
      else
        free_entry.update(bowler_id: nil)
        render json: FreeEntryBlueprint.render(free_entry, view: :director_list), status: :ok
        return
      end

      free_entry.update(bowler_id: bowler.id)

      if params[:confirm].present?
        TournamentRegistration.confirm_free_entry(free_entry, current_user&.email)
      end

      render json: FreeEntryBlueprint.render(free_entry, view: :director_list), status: :ok
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    end

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
