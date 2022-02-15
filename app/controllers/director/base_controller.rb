module Director
  class BaseController < ApplicationController
    respond_to :json

    # before_action :spit_it_out
    before_action :authenticate_user! # , :load_current_user

    # after_action :verify_authorized

    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    # def load_current_user
    #   @current_user = current_user
    # end

    def spit_it_out
      header = request.headers.fetch('HTTP_AUTHORIZATION')
      Rails.logger.info "*** Auth header: #{header}"
    end

    def not_found
      render json: nil, status: :not_found
    end
  end
end
