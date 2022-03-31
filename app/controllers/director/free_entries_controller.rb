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
      sleep(3) if Rails.env.development?
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
      fe = FreeEntry.find(params[:id])

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

    def confirm
      free_entry = FreeEntry.find(params[:id])

      authorize free_entry.tournament, :update?

      TournamentRegistration.confirm_free_entry(free_entry, current_user&.email)
      render json: FreeEntryBlueprint.render(free_entry.reload, view: :director_list), status: 200
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    rescue TournamentRegistration::IncompleteFreeEntry
      render json: { error: 'Cannot confirm a free entry that is not linked with a bowler' }, status: :conflict
    rescue TournamentRegistration::FreeEntryAlreadyConfirmed
      render json: { error: 'That free entry is already confirmed' }, status: :conflict
    end

    def update
      free_entry = FreeEntry.includes(:tournament).find(params[:id])
      tournament = free_entry.tournament
      authorize free_entry.tournament, :update?

      if free_entry.bowler_id.present?
        render json: nil, status: :conflict
        return
      end

      bowler = tournament.bowlers.find_by(identifier: params[:bowler_identifier])
      unless bowler.present?
        render json: nil, status: :not_found
        return
      end

      free_entry.update(bowler_id: bowler.id)
      if params[:confirm].present?
        TournamentRegistration.confirm_free_entry(free_entry, current_user&.email)
      end

      render json: FreeEntryBlueprint.render(free_entry), status: :ok
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
