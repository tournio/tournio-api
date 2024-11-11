module Director
  class ContactsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    def create
      self.tournament = Tournament.find_by_identifier!(params[:tournament_identifier])

      authorize tournament, :update?

      contact = Contact.new(new_contact_params)
      contact.tournament = tournament
      if (contact.save)
        render json: ContactBlueprint.render(contact), status: :created
      end
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    def update
      contact = Contact.includes(:tournament).find_by_identifier!(params[:identifier])
      self.tournament = contact.tournament

      authorize tournament, :update?

      if contact.update(update_contact_params)
        render json: ContactBlueprint.render(contact.reload), status: :ok
      end
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    def destroy
      contact = Contact.includes(:tournament).find_by_identifier!(params[:identifier])
      self.tournament = contact.tournament

      authorize tournament, :update?

      contact.destroy
      render json: nil, status: :no_content
    rescue ActiveRecord::RecordNotFound
      skip_authorization
      render json: {}, status: :not_found
    end

    private

    attr_accessor :tournament, :contact

    def new_contact_params
      params.permit(:tournament_identifier, contact: %i(name email role notify_on_payment notify_on_registration notification_preference)).require(:contact)
    end

    def update_contact_params
      params.require(:contact).permit(%i(name email role notify_on_payment notify_on_registration notification_preference))
    end
  end
end
