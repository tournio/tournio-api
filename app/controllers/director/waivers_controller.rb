# frozen_string_literal: true

module Director
  class WaiversController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    wrap_parameters false

    def create
      load_bowler

      authorize bowler.tournament, :update?

      load_purchasable_item

      waiver = Waiver.create(
        bowler: bowler,
        purchasable_item: purchasable_item,
        created_by: current_user.email
      )

      render json: WaiverSerializer.new(waiver), status: :created
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    def destroy
      params.permit(:identifier)

      waiver = Waiver.includes(bowler: :tournament).find_by_identifier! params[:identifier]

      authorize waiver.bowler, :update?

      waiver.destroy

      render json: nil, status: :no_content
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    private

    attr_accessor :bowler, :purchasable_item, :waiver_params

    def load_bowler
      identifier = params.require(:bowler_identifier)
      self.bowler = Bowler.find_by_identifier! identifier
    end

    def load_purchasable_item
      self.purchasable_item = bowler.tournament.purchasable_items.late_fee.first
      raise ActiveRecord::RecordNotFound unless purchasable_item.present?
    end
  end
end
