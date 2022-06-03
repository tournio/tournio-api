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

    def destroy
      self.shift = Shift.includes(:tournament).find_by!(identifier: params[:identifier])
      self.tournament = shift.tournament

      authorize tournament, :update?

      unless tournament.active? || tournament.demo?
        shift.destroy
        render json: nil, status: :no_content
        return
      end

      render json: { error: 'Cannot delete a shift from an active tournament' }, status: :forbidden
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    end

    def update
      self.shift = Shift.includes(:tournament).find_by!(identifier: params[:identifier])
      self.tournament = shift.tournament

      authorize tournament, :update?
      shift.update!(shift_params)

      render json: ShiftBlueprint.render(shift.reload), status: :ok
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    rescue ActiveRecord::RecordInvalid
      render json: { error: 'Cannot make capacity less than the number of confirmed bowlers' }, status: :conflict
    end

    private

    attr_accessor :tournament, :shift

    def shift_params
      params.permit(:tournament_identifier,
        :identifier,
        shift: %i(capacity description name display_order).concat([details: %i(permit_new_teams permit_solo permit_joins permit_partnering).concat([events: []])])
      ).require(:shift)
    end
  end
end
