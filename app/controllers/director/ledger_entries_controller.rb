module Director
  class LedgerEntriesController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def create
      self.bowler = Bowler.find_by_identifier!(params[:bowler_identifier])

      authorize bowler, :update?

      entry = LedgerEntry.new(new_entry_params)
      entry.bowler = bowler
      entry.source = :manual
      entry.notes = "Created by #{current_user.email}"
      if (entry.save)
        render json: LedgerEntryBlueprint.render(entry), status: :created
      end
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    private

    attr_accessor :bowler, :ledger_entry

    def new_entry_params
      params.permit(:bowler_identifier, ledger_entry: [:credit, :identifier]).require(:ledger_entry)
    end
  end
end
