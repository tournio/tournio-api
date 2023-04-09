# frozen_string_literal: true

module Director
  class PurchasableItemsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    wrap_parameters false

    before_action :load_tournament, only: %i(index create)

    def index
      authorize tournament, :update?

      self.items = policy_scope(tournament.purchasable_items)
      render json: PurchasableItemBlueprint.render(items), status: :ok
    rescue ActiveRecord::RecordNotFound
      skip_policy_scope
      skip_authorization
      render json: nil, status: :not_found
    end

    def create
      authorize tournament, :update?

      if tournament.active?
        render json: { error: 'Cannot add purchasable items to an active tournament' }, status: :forbidden
        return
      end

      PurchasableItem.transaction do
        self.items = PurchasableItem.create!(purchasable_item_create_params)

        # If we're dealing with sized apparel, create PIs for each
        # size and link them to the parent
        handle_sized_apparel_items_creation

        # Create Stripe coupons and/or products
        items.each do |i|
          # But not for a sized item; its children will have StripeProducts
          next if i.sized?

          if i.bundle_discount? || i.early_discount?
            Stripe::CouponCreator.perform_in(Rails.configuration.sidekiq_async_delay, i.id)
          else
            Stripe::ProductCreator.perform_in(Rails.configuration.sidekiq_async_delay, i.id)
          end
        end unless tournament.config['skip_stripe']

        render json: PurchasableItemBlueprint.render(items), status: :created
      end

    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    rescue ActiveRecord::RecordInvalid => exception
      if exception.message.include? 'Determination'
        render json: { error: 'Determination already present' }, status: :conflict
        return
      end

      render json: { error: 'Invalid item configuration' }, status: :unprocessable_entity
    end

    def update
      self.item = PurchasableItem.includes(:tournament).find_by!(identifier: params[:identifier])
      self.tournament = item.tournament

      authorize tournament, :update?

      if tournament.active?
        render json: { error: 'Cannot modify purchasable items of an active tournament' }, status: :forbidden
        return
      end

      previous_amount = item.value
      item.update!(purchasable_item_update_params)
      new_amount = item.value

      # Deal with the item's Stripe products. (Parent of children won't have one.)
      if item.bundle_discount? || item.early_discount?
        if item.stripe_coupon.present?
          Stripe::CouponDestroyer.perform_async(item.stripe_coupon.coupon_id, tournament.stripe_account.identifier)
          item.stripe_coupon.destroy
        end
        Stripe::CouponCreator.perform_async(item.id) unless tournament.config['skip_stripe']
      else
        unless item.sized? || previous_amount == new_amount || tournament.config['skip_stripe']
          Stripe::ProductUpdater.perform_in(Rails.configuration.sidekiq_async_delay, item.id)
        end
      end

      handle_sized_apparel_item_update

      # Stripe creation for each child
      unless tournament.config['skip_stripe']
        item.reload.children.each do |i|
          Stripe::ProductCreator.perform_in(Rails.configuration.sidekiq_async_delay, i.id)
        end
      end

      if items&.count
        render json: PurchasableItemBlueprint.render(items), status: :ok
      else
        render json: PurchasableItemBlueprint.render(item.reload), status: :ok
      end
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      Bugsnag.notify(e)
    end

    def destroy
      pi = PurchasableItem.includes(:tournament, :stripe_product, :stripe_coupon).find_by!(identifier: params[:identifier])
      self.tournament = pi.tournament

      authorize tournament, :update?

      unless tournament.active? || tournament.demo?
        if pi.bundle_discount? || pi.early_discount?
          if pi.stripe_coupon.present?
            Stripe::CouponDestroyer.perform_in(Rails.configuration.sidekiq_async_delay, pi.stripe_coupon.coupon_id, tournament.stripe_account.identifier)
            pi.stripe_coupon.destroy
          end
        else
          if pi.stripe_product.present?
            Stripe::ProductDeactivator.perform_in(Rails.configuration.sidekiq_async_delay, pi.stripe_product.id, tournament.stripe_account.identifier)
          end
        end

        pi.destroy

        render json: {}, status: :no_content
        return
      end

      render json: { error: 'Cannot delete purchasable item from an active tournament' }, status: :forbidden
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    end

    private

    attr_accessor :tournament, :items, :item

    def load_tournament
      self.tournament = Tournament.find_by_identifier!(params[:tournament_identifier])
    end

    def purchasable_item_update_params
      params.require(:purchasable_item).permit(
        :name,
        :value,
        configuration: [
          :order,
          :applies_at,
          :valid_until,
          :division,
          :note,
          :denomination,
          :size,
          events: [],
          sizes: [
            unisex: ApparelDetails::SIZES_ADULT,
            women: ApparelDetails::SIZES_ADULT,
            men: ApparelDetails::SIZES_ADULT,
            infant: ApparelDetails::SIZES_INFANT,
          ],
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
            :size,
            events: [],
            sizes: [
              unisex: ApparelDetails::SIZES_ADULT,
              women: ApparelDetails::SIZES_ADULT,
              men: ApparelDetails::SIZES_ADULT,
              infant: ApparelDetails::SIZES_INFANT,
            ],
          ]
        ]
      ).require(:purchasable_items)
            .map! { |pi_hash| pi_hash.merge(tournament_id: tournament.id) }
    end

    def handle_sized_apparel_items_creation
      children = []
      items.select { |i| i.refinement == 'sized' }.each do |pi|
        pi.configuration['sizes'].each_pair do |group, size_keys|
          size_keys.each_pair do |size_key, include_it|
            next unless include_it
            child_pi = pi.deep_dup

            child_pi.parent = pi
            child_pi.configuration['size'] = ApparelDetails.serialize_size(group, size_key)
            child_pi.configuration.delete('sizes')
            child_pi.configuration['parent_identifier'] = pi.identifier
            child_pi.refinement = nil

            child_pi.save
            children << child_pi
          end
        end
        pi.configuration.delete('sizes')
        pi.save
      end
      items.concat(children)
    end

    def handle_sized_apparel_item_update
      # The idea here is to update the one we have, and then delete its children (if any)
      # Then, if it's now sized, create child instances, with this one as the parent.
      # If it's not sized, we're good.
      # If it was sized, but isn't now, then we're still good, because we destroyed its children
      # If it wasn't sized, but is now, there were no children to destroy, it's updated, and now we can create its children
      # Set it in @items, and put all the children in there, too
      # Controller can now return the list of items

      # delete children (and clean up Stripe products)
      item.children.each do |pi|
        if pi.stripe_product.present?
          Stripe::ProductDeactivator.perform_in(Rails.configuration.sidekiq_async_delay, pi.stripe_product.id, tournament.stripe_account.identifier)
        end
      end
      item.children.destroy_all
      item.reload

      # create new children
      if item.sized?
        self.items = [item]
        item.configuration['sizes'].each_pair do |group, sizes|
          sizes.each_pair do |size_key, included|
            if included
              child = item.deep_dup

              child.parent = item
              child.configuration['size'] = ApparelDetails.serialize_size(group, size_key)
              child.configuration.delete('sizes')
              child.configuration['parent_identifier'] = item.identifier
              child.refinement = nil

              child.save
              item.children << child
            end
          end
        end
        item.configuration.delete('sizes')
        self.items += item.children
      end
    end
  end
end
