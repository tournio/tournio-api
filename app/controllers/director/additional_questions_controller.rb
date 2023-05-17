module Director
  class AdditionalQuestionsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def create
      self.tournament = Tournament.find_by_identifier!(params[:tournament_identifier])

      authorize tournament, :update?

      # contact = Contact.new(new_contact_params)
      # contact.tournament = tournament
      # if (contact.save)
      #   render json: ContactBlueprint.render(contact), status: :created
      # end
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    def update
      # contact = Contact.includes(:tournament).find_by_identifier!(params[:identifier])
      # self.tournament = contact.tournament
      #
      # authorize tournament, :update?
      #
      # if contact.update(update_contact_params)
      #   render json: ContactBlueprint.render(contact.reload), status: :ok
      # end
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    def destroy

    end

    private

    attr_accessor :tournament, :question

    # def new_question_params
    #   params.permit(:tournament_identifier, additional_question: %i(name email role notify_on_payment notify_on_registration notification_preference)).require(:additional_question)
    # end
    #
    # def update_question_params
    #   params.require(:additional_question).permit(%i(name email role notify_on_payment notify_on_registration notification_preference))
    # end
  end
end
