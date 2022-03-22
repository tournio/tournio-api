# frozen_string_literal: true

module Director
  class TournamentsController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    before_action :load_tournament, except: [:index]

    def index
      tournaments = if params[:upcoming]
                      policy_scope(Tournament).includes(:config_items).upcoming.order(name: :asc)
                    else
                      policy_scope(Tournament).includes(:config_items).order(name: :asc)
                    end
      authorize(Tournament)
      render json: TournamentBlueprint.render(tournaments, view: :director_list)
    end

    def show
      unless tournament.present?
        render json: nil, status: 404
        return
      end
      authorize tournament
      render json: TournamentBlueprint.render(tournament, view: :director_detail)
    end

    def clear_test_data
      unless tournament.present?
        render json: nil, status: 404
        return
      end
      authorize tournament
      unless tournament.testing?
        render json: nil, status: 403
        return
      end
      DirectorUtilities.clear_test_data(tournament: tournament)
      render json: nil, status: 204
    end

    def csv_download
      authorize tournament
      export_data = DirectorUtilities.csv_hash(tournament: tournament)

      send_data export_data, filename: 'tournament_bowlers.csv', type: 'text/plain', disposition: 'attachment'
    end

    def igbots_download
      authorize tournament
      export_data = DirectorUtilities.igbots_hash(tournament: tournament)
      xml_data = export_data.to_xml(root: 'igbots', dasherize: false, skip_types: true).gsub(/\w+>/, &:upcase)

      send_data xml_data, filename: 'igbots_import.xml', type: 'application/xml', disposition: 'attachment'
    end

    def state_change
      unless tournament.present?
        render json: nil, status: 404
        return
      end

      authorize tournament

      if tournament.closed?
        render json: nil, status: 403
        return
      end

      action = params.require(:state_action)
      allowable_actions = tournament.aasm.events.map(&:name)
      render json: nil, status: 400 and return unless allowable_actions.include?(action.to_sym)

      action_sym = "#{action}!".to_sym
      tournament.send(action_sym)

      render json: TournamentBlueprint.render(tournament, view: :director_detail)
    end

    def update
      unless tournament.present?
        render json: nil, status: 404
        return
      end

      authorize tournament

      if tournament.active? || tournament.closed?
        render json: nil, status: 403
        return
      end

      updates = update_params
      updates[:additional_questions_attributes].each do |aqa|
        if aqa[:extended_form_field_id].present?
          eff = ExtendedFormField.find(aqa[:extended_form_field_id])
          aqa[:validation_rules] = eff.validation_rules.merge(aqa[:validation_rules])
        end
      end
      tournament.update(updates)

      render json: TournamentBlueprint.render(tournament.reload, view: :director_detail)
    end

    private

    attr_accessor :tournament

    def load_tournament
      params.require(:identifier)
      id = params[:identifier]
      self.tournament = Tournament.includes(:config_items,
                                            :contacts,
                                            :testing_environment,
                                            :teams,
                                            :bowlers,
                                            :free_entries,
                                            additional_questions: [:extended_form_field])
                                  .find_by_identifier(id)
    end

    def update_params
      params.require(:tournament).permit(additional_questions_attributes: [:id, :extended_form_field_id, :order, :_destroy, validation_rules: {}])
    end
  end
end
