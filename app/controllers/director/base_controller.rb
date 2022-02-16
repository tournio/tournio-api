module Director
  class BaseController < ApplicationController
    include Pundit::Authorization

    respond_to :json

    before_action :authenticate_user!

    after_action :verify_authorized, except: :index
    after_action :verify_policy_scoped, only: :index

    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    def not_found
      render json: nil, status: :not_found
    end

    def unauthorized
      render json: nil, status: :unauthorized
    end
  end
end
