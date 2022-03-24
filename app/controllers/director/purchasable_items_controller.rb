# frozen_string_literal: true

module Director
  class PurchasableItemsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def create
      self.tournament = Tournament.find_by_identifier!(params[:tournament_identifier])

      authorize tournament, :update?

      if tournament.active?
        render json: {error: 'Cannot add purchasable items to an active tournament'}, status: :forbidden
        return
      end

      pi = PurchasableItem.new(purchasable_item_create_params)
      pi.tournament = tournament
      if pi.save
        render json: PurchasableItemBlueprint.render(pi), status: :created
        return
      end

      render json: {error: pi.errors.full_messages}, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    end

    def update
      pi = PurchasableItem.includes(:tournament).find_by!(identifier: params[:identifier])
      self.tournament = pi.tournament

      authorize tournament, :update?

      if tournament.active?
        render json: {error: 'Cannot modify purchasable items of an active tournament'}, status: :forbidden
        return
      end

      pi.update(purchasable_item_update_params)

      render json: PurchasableItemBlueprint.render(pi.reload), status: :ok
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    end

    private

    attr_accessor :tournament

    def purchasable_item_update_params
      params.require(:purchasable_item).permit(:value, configuration: %i(order applies_at valid_until division note denomination)).to_h.symbolize_keys
    end

    def purchasable_item_create_params
      params.require(:purchasable_item).permit(:value, :name, :category, :determination, :refinement, configuration: %i(order applies_at valid_until division note denomination)).to_h.symbolize_keys
    end
  end
end
