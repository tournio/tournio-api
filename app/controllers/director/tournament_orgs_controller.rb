# frozen_string_literal: true

module Director
  class TournamentOrgsController < BaseController
    # We mustn't use anything that assumes a :tournament attribute.
    # This might necessitate a different version of StripeUtilities, but not just yet
    include StripeUtilities

    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    before_action :load_tournament_org, except: %i(index create)

    ORG_PARAMS = [
      :name,
      :identifier,
      tournaments_attributes: [
        :id,
      ],
    ]

    def index
      tournament_orgs = policy_scope(TournamentOrg).includes(:tournaments).order(name: :asc)
      authorize(TournamentOrg)
      render json: TournamentOrgSerializer.new(tournament_orgs).serialize
    end

    def show
      unless tournament_org.present?
        skip_authorization
        render json: nil, status: 404
        return
      end
      authorize tournament_org

      render json: TournamentOrgSerializer.new(tournament_org).serialize
    end

    private

    attr_accessor :tournament_org

    def load_tournament_org
      params.require(:identifier)
      id = params[:identifier]
      self.tournament_org = TournamentOrg
                              .includes(:tournaments,
                                :stripe_account,
                                :users)
                              .find_by_identifier(id)
    end
  end
end
