# frozen_string_literal: true

module Director
  class PurchasableItemsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    wrap_parameters false

    def create
      self.tournament = Tournament.find_by_identifier!(params[:tournament_identifier])

      authorize tournament, :update?

      if tournament.active?
        render json: {error: 'Cannot add purchasable items to an active tournament'}, status: :forbidden
        return
      end

      PurchasableItem.transaction do
        self.items = PurchasableItem.create!(purchasable_item_create_params)

        items.each { |i| Stripe::ProductCreator.perform_async(i.id) }

        render json: PurchasableItemBlueprint.render(items), status: :created
      end

    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    rescue ActiveRecord::RecordInvalid => exception
      if exception.message.include? 'Determination'
        render json: {error: 'Determination already present'}, status: :conflict
        return
      end

      render json: {error: 'Invalid item configuration'}, status: :unprocessable_entity
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
      if pi.errors
        Rails.logger.info pi.errors.inspect
      else
        # TODO: update Stripe product information
      end

      render json: PurchasableItemBlueprint.render(pi.reload), status: :ok
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    end

    def destroy
      pi = PurchasableItem.includes(:tournament).find_by!(identifier: params[:identifier])
      self.tournament = pi.tournament

      authorize tournament, :update?

      unless tournament.active? || tournament.demo?
        pi.destroy

        # TODO: delete Stripe Product and Price info

        render json: {}, status: :no_content
        return
      end

      render json: { error: 'Cannot delete purchasable item from an active tournament' }, status: :forbidden
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    end

    private

    attr_accessor :tournament, :items

    def purchasable_item_update_params
      params.require(:purchasable_item).permit(
        :value,
        configuration: [
          :order,
          :applies_at,
          :valid_until,
          :division,
          :note,
          :denomination,
          events: [],
        ],
      ).to_h.symbolize_keys
    end

    def purchasable_item_create_params
      params.permit(:tournament_identifier,
        purchasable_items: [
          :value,
          :name,
          :category,
          :determination,
          :refinement,
          configuration: [
            :order,
            :applies_at,
            :valid_until,
            :division,
            :note,
            :denomination,
            :event,
            events: [],
          ]
        ]
      ).require(:purchasable_items)
            .map! { |pi_hash| pi_hash.merge(tournament_id: tournament.id) }
    end
  end
end
