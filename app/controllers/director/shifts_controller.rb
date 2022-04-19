# frozen_string_literal: true

module Director
  class ShiftsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    wrap_parameters false

    def create
      self.tournament = Tournament.find_by_identifier!(params[:tournament_identifier])

      authorize tournament, :update?

      shift = Shift.new(shift_params)
      tournament.shifts << shift

      render json: ShiftBlueprint.render(shift), status: :created
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    rescue ActiveRecord::RecordInvalid => exception
      render json: {error: 'Invalid shift'}, status: :unprocessable_entity
    end

    private

    attr_accessor :tournament, :shift

    def shift_params
      params.permit(:tournament_identifier, shift: %i(capacity description name display_order)).require(:shift)
    end
  end
end
