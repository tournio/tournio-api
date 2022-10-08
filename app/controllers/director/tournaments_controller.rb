# frozen_string_literal: true

module Director
  class TournamentsController < BaseController
    # this gives us attributes: tournament, stripe_account
    # as well as some methods
    include StripeUtilities

    rescue_from Pundit::NotAuthorizedError, with: :unauthorized

    before_action :load_tournament, except: %i(index create)
    before_action :set_time_zone, except: %i(index create)

    MAX_STRIPE_ATTEMPTS = 10
    TOURNAMENT_PARAMS = [
      :name,
      :abbreviation,
      :year,
      :start_date,
      :end_date,
      :entry_deadline,
      :location,
      :timezone,
      additional_questions_attributes: [
        :id,
        :extended_form_field_id,
        :order,
        :_destroy,
        validation_rules: {}
      ],
      config_items_attributes: [
        :id,
        :key,
        :value,
      ],
      scratch_divisions_attributes: [
        :id,
        :key,
        :name,
        :low_average,
        :high_average,
      ],
      events_attributes: [
        :id,
        :roster_type,
        :name,
        :required,
        :scratch,
        :entry_fee, # not a model attribute
        scratch_division_entry_fees: [ # not a model attribute
          :id,
          :fee,
        ]
      ],
    ]

    def index
      tournaments = if params[:upcoming]
                      policy_scope(Tournament).includes(:config_items).upcoming.order(name: :asc)
                    else
                      policy_scope(Tournament).includes(:config_items).order(name: :asc)
                    end
      authorize(Tournament)
      render json: TournamentBlueprint.render(tournaments, view: :director_list, **url_options)
    end

    def show
      unless tournament.present?
        skip_authorization
        render json: nil, status: 404
        return
      end
      authorize tournament
      render json: TournamentBlueprint.render(tournament, view: :director_detail, **url_options)
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

      if %w(demonstrate reset).include?(action)
        authorize tournament, :demo_or_reset?
      end

      action_sym = "#{action}!".to_sym
      tournament.send(action_sym)

      render json: TournamentBlueprint.render(tournament, view: :director_detail, **url_options)
    end

    def create
      authorize Tournament

      tournament = Tournament.new(create_params)
      if tournament.valid?
        tournament.save
      else
        render json: { error: tournament.errors.full_messages.join(' ') }, status: :unprocessable_entity
        return
      end

      if current_user.director?
        current_user.tournaments << tournament
      end

      render json: TournamentBlueprint.render(tournament, view: :director_detail, **url_options), status: :created
    end

    def update
      unless tournament.present?
        render json: nil, status: 404
        return
      end

      authorize tournament

      if tournament.active? || tournament.closed? || tournament.demo?
        render json: nil, status: 403
        return
      end

      updates = update_params
      updates[:additional_questions_attributes].each do |aqa|
        if aqa[:extended_form_field_id].present?
          eff = ExtendedFormField.find(aqa[:extended_form_field_id])
          aqa[:validation_rules] = eff.validation_rules.merge(aqa[:validation_rules])
        end
      end if updates[:additional_questions_attributes].present?

      purchasable_items_to_create = []
      updates[:events_attributes].each do |ea|
        if !ea[:required].nil? && (ea[:required] == 'false' || !ea[:required])
          if ea[:scratch_division_entry_fees].present?
            ea[:scratch_division_entry_fees].each do |sdef|
              division = tournament.scratch_divisions.find(sdef[:id])
              note = "Averages "
              if division.low_average == 0
                note += "#{division.high_average} and under"
              elsif division.high_average == 300
                note += "#{division.low_average} and up"
              else
                note += "#{division.low_average} - #{division.high_average}"
              end
              purchasable_items_to_create << PurchasableItem.new(
                tournament: tournament,
                category: :bowling,
                determination: :single_use,
                refinement: :division,
                name: ea[:name],
                value: sdef[:fee],
                configuration: {
                  division: division.key,
                  note: note,
                }
              )
            end
            ea.delete :scratch_division_entry_fees
          else
            purchasable_items_to_create << PurchasableItem.new(
              tournament: tournament,
              category: :bowling,
              determination: :single_use,
              refinement: ea[:roster_type],
              name: ea[:name],
              value: ea[:entry_fee]
            )
            ea.delete :entry_fee
          end
        end
      end if updates[:events_attributes].present?

      tournament.update(updates)
      purchasable_items_to_create.map(&:save!)

      render json: TournamentBlueprint.render(tournament.reload, view: :director_detail, **url_options)
    end

    def destroy
      unless tournament.present?
        skip_authorization
        render json: nil, status: 404
        return
      end

      authorize tournament

      unless tournament.active? || tournament.demo?
        tournament.destroy
        render json: {}, status: :no_content
        return
      end

      render json: { error: 'Cannot delete an active tournament' }, status: :forbidden
    end

    def email_payment_reminders
      unless tournament.present?
        skip_authorization
        render json: nil, status: 404
        return
      end

      authorize tournament

      unless tournament.active? || tournament.closed?
        render json: nil, status: 403
        return
      end

      PaymentReminderSchedulerJob.perform_async(tournament.id)

      render json: nil, status: :ok
    end

    def stripe_refresh
      unless tournament.present?
        render json: nil, status: :not_found
        return
      end

      authorize tournament

      load_stripe_account
      unless stripe_account.present?
        self.stripe_account = create_stripe_account
      end
      unless stripe_account.present?
        render json: { error: 'Failed to create a Stripe account in time.' }, status: :service_unavailable
        return
      end

      # this will update the stripe_account's attributes if it's successful
      get_updated_account_link

      unless stripe_account.link_expires_at.to_i > Time.zone.now.to_i
        render json: { error: 'Failed to get an account link in time.'}, status: :service_unavailable
        return
      end

      render json: StripeAccountBlueprint.render(stripe_account), status: :ok
    end

    def stripe_status
      unless tournament.present?
        render json: nil, status: :not_found
        return
      end

      authorize tournament

      load_stripe_account

      unless stripe_account.present?
        render json: { error: 'No Stripe account exists yet.' }, status: :precondition_failed
        return
      end

      result = get_account_details
      unless result.present?
        render json: { error: 'Failed to retrieve account status from Stripe.' }, status: :service_unavailable
        return
      end

      update_account_details(result)

      render json: StripeAccountBlueprint.render(stripe_account.reload), status: :ok
    end

    def logo_upload
      unless tournament.present?
        render json: nil, status: :not_found
        return
      end

      authorize tournament

      tournament.logo_image.purge if tournament.logo_image.attached?
      tournament.logo_image.attach(params['file'])

      render json: { image_url: url_for(tournament.logo_image) }, status: :accepted
    end

    private

    def load_tournament
      params.require(:identifier)
      id = params[:identifier]
      self.tournament = Tournament.includes(:config_items,
                                            :contacts,
                                            :testing_environment,
                                            :teams,
                                            :bowlers,
                                            :free_entries,
                                            :shifts,
                                            :stripe_account,
                                            additional_questions: [:extended_form_field])
                                  .find_by_identifier(id)
    end

    def update_params
      params.require(:tournament).permit(TOURNAMENT_PARAMS)
    end

    def create_params
      params.require(:tournament).permit(TOURNAMENT_PARAMS)
    end
  end
end
