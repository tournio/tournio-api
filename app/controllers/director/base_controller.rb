module Director
  class BaseController < ApplicationController
    respond_to :json

    before_action :authenticate_user!

    # after_action :verify_authorized

    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    def not_found
      render json: nil, status: :not_found
    end
  end
end
