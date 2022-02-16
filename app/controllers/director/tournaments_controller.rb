# frozen_string_literal: true

module Director
  class TournamentsController < BaseController
    before_action :load_tournament, except: [:index]

    def index
      tournaments = Tournament.includes(:config_items).order(name: :asc)
      render json: TournamentBlueprint.render(tournaments, view: :director_list)
    end

    def show
      unless @tournament.present?
        render json: nil, status: 404
        return
      end
      render json: TournamentBlueprint.render(@tournament, view: :director_detail)
    end

    def clear_test_data
      unless @tournament.present?
        render json: nil, status: 404
        return
      end
      DirectorUtilities.clear_test_data(tournament: @tournament)
      render json: nil, status: 204
    end

    def csv_download
      export_data = DirectorUtilities.csv_hash(tournament: @tournament)

      send_data export_data, filename: 'tournament_bowlers.csv', type: 'text/plain', disposition: 'attachment'
    end

    def igbots_download
      export_data = DirectorUtilities.igbots_hash(tournament: @tournament)
      xml_data = export_data.to_xml(root: 'igbots', dasherize: false, skip_types: true).gsub(/\w+>/, &:upcase)

      send_data xml_data, filename: 'igbots_import.xml', type: 'application/xml', disposition: 'attachment'
    end

    def state_change
      unless @tournament.present?
        render json: nil, status: 404
        return
      end

      action = params.require(:state_action)
      allowable_actions = @tournament.aasm.events.map(&:name)
      render json: nil, status: 400 and return unless allowable_actions.include?(action.to_sym)

      action_sym = "#{action}!".to_sym
      @tournament.send(action_sym)

      render json: TournamentBlueprint.render(@tournament, view: :director_detail)
    end

    private

    def load_tournament
      params.require(:identifier)
      id = params[:identifier]
      @tournament = Tournament.includes(:config_items,
                                        :contacts,
                                        :testing_environment,
                                        :teams,
                                        :bowlers,
                                        :free_entries,
                                        additional_questions: [:extended_form_field])
                              .find_by_identifier(id)
    end
  end
end