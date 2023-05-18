module Director
  class AdditionalQuestionsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def create
      self.tournament = Tournament.find_by_identifier!(params[:tournament_identifier])

      authorize tournament, :update?

      question = AdditionalQuestion.new(new_question_params)
      question.tournament = tournament
      if (question.save)
        render json: AdditionalQuestionBlueprint.render(question), status: :created
      end
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    def update
      question = AdditionalQuestion.includes(:tournament).find_by_identifier!(params[:identifier])
      self.tournament = question.tournament

      authorize tournament, :update?

      if question.update(update_question_params)
        render json: AdditionalQuestionBlueprint.render(question.reload), status: :ok
      end
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    def destroy
      self.question = AdditionalQuestion.includes(:tournament).find_by_identifier!(params[:identifier])
      self.tournament = question.tournament

      authorize tournament, :update?

      unless tournament.active?
        question.destroy
        render json: nil, status: :no_content
        return;
      end
      render json: { error: 'Cannot delete a question from an active tournament' }, status: :forbidden
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: nil, status: :not_found
    end

    private

    attr_accessor :tournament, :question

    def new_question_params
      params.permit(
        :tournament_identifier,
        additional_question: [
          :extended_form_field_id,
          :order,
          validation_rules: %i(required),
        ],
      ).require(:additional_question)
    end

    def update_question_params
      params.require(:additional_question).permit([
        :order,
        validation_rules: [
          :required,
        ],
      ])
    end
  end
end
