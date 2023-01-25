module Director
  class LedgerEntriesController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def create
      self.bowler = Bowler.includes(:tournament).find_by_identifier!(params[:bowler_identifier])

      authorize bowler, :update?

      entry = LedgerEntry.new(new_entry_params)
      entry.bowler = bowler
      entry.source = :manual
      entry.notes = "Created by #{current_user.email}"
      entry.save

      extp = ExternalPayment.create(
        payment_type: :manual,
        identifier: SecureRandom.uuid,
        details: entry.identifier,
        tournament: bowler.tournament
      )

      (bowler.purchases.unpaid.entry_fee + bowler.purchases.unpaid.early_discount).map do |p|
        p.update(
          paid_at: Time.zone.now,
          external_payment_id: extp.id
        )
      end

      TournamentRegistration.try_confirming_bowler_shift(bowler)

      render json: LedgerEntryBlueprint.render(entry), status: :created
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
