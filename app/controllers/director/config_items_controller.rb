# frozen_string_literal: true

module Director
  class ConfigItemsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def update
      ci = ConfigItem.includes(:tournament).find(params[:id])
      self.tournament = ci.tournament

      authorize tournament, :update?

      if tournament.active? && ci.key != 'display_capacity'
        render json: {error: 'Cannot modify configuration of an active tournament'}, status: :forbidden
        return
      end

      ci.update(config_item_params)

      render json: ConfigItemBlueprint.render(ci.reload), status: :ok
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    end

    private

    attr_accessor :tournament

    def config_item_params
      params.require(:config_item).permit(%i(value)).to_h.symbolize_keys
    end

  end
end
