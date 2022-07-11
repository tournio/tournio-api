class CheckoutSessionsController < ApplicationController
  def show
    sc = StripeCheckoutSession.find_by!(identifier: params[:identifier])
    render json: StripeCheckoutSessionBlueprint.render(sc), status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: :not_found
  end
end
