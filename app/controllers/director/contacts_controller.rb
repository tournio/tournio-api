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

    end

    def destroy

    end

    private

    attr_accessor :tournament, :contact

    def new_contact_params
      params.permit(:tournament_identifier, contact: %i(name email role notify_on_payment notify_on_registration notification_preference)).require(:contact)
    end
  end
end
