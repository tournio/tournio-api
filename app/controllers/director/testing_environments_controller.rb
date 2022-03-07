# frozen_string_literal: true

module Director
  class TestingEnvironmentsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def update
      load_tournament

      unless tournament.present?
        skip_authorization
        render json: nil, status: :not_found
      end

      authorize tournament, :update?

      unless tournament.testing?
        render json: { error: 'Tournament is not in testing.' }, status: :conflict
        return
      end

      ActionController::Parameters.action_on_unpermitted_parameters = :raise

      unless tournament.testing_environment.update(conditions: condition_params)
        render json: { error: tournament.testing_environment.errors.full_messages }, status: :unprocessable_entity
        return
      end

      render json: TestingEnvironmentBlueprint.render(tournament.testing_environment.reload), status: :ok
    rescue ActionController::UnpermittedParameters
      render json: { error: 'No valid testing conditions found' }, status: :unprocessable_entity
    end

    private

    attr_accessor :tournament

    def condition_params
      params.require(:testing_environment).require(:conditions).permit(TestingEnvironment::SUPPORTED_CONDITIONS.keys)
    end

    def load_tournament
      params.require(:tournament_identifier)
      id = params[:tournament_identifier]
      self.tournament = Tournament.includes(:testing_environment).find_by_identifier(id)
    end
  end
end
