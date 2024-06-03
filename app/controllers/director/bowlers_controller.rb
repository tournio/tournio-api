# frozen_string_literal: true

module Director
  class BowlersController < BaseController
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized
    wrap_parameters false

    PERSON_ATTRS = %i[
        first_name
        last_name
        usbc_id
        igbo_id
        birth_month
        birth_day
        birth_year
        nickname
        phone
        email
        address1
        address2
        city
        state
        country
        postal_code
      ].freeze

    def index
      load_tournament
      unless tournament.present?
        skip_policy_scope
        render json: nil, status: :not_found
        return
      end
      authorize tournament, :show?

      # do we need to use the "modern" serializer?
      if params[:serializer] == 'modern'
        # load bowlers with all the associations. (probably want more)
        bowlers = policy_scope(tournament.bowlers).includes(
            :ledger_entries,
            :additional_question_responses,
            :team,
            :person,
            :free_entry,
            purchases: :purchasable_item,
            doubles_partner: :person,
          )
        render json: DirectorBowlerSerializer.new(bowlers).serialize, status: :ok
      else
        # if not:
        bowlers = policy_scope(tournament.bowlers).includes(:person, :free_entry, :team)

        if params[:unpartnered]
          bowlers = bowlers.where(doubles_partner_id: nil)
        end

        hashed_bowlers = bowlers.map { |b| BowlerBlueprint.render_as_hash(b, view: :director_list, **url_options) }
        hashed_bowlers.sort_by! { |h| h[:full_name].downcase }
        render json: hashed_bowlers, status: :ok
      end
    end

    def show
      load_bowler_and_tournament
      unless bowler.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :show?

      if params[:serializer] == 'modern'
        render json: DirectorBowlerSerializer.new(bowler).as_json
      else
        render json: BowlerBlueprint.render(bowler, view: :director_detail, **url_options)
      end
    end

    def create
      load_tournament
      unless tournament.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      bowler = Bowler.new(create_bowler_params)
      bowler.tournament = tournament
      unless bowler.valid?
        render json: { error: bowler.errors.full_messages.join('; ') }, status: :bad_request
        return
      end

      bowler.save
      team = bowler.team
      TournamentRegistration.register_bowler(bowler, team.present? ? 'standard' : 'solo')

      if team.present? && team.bowlers.count == tournament.team_size
        # automatically pair up the last two bowlers
        # TODO: only if there's a team event (which we don't handle separately yet)
        unpartnered = team.bowlers.without_doubles_partner
        if unpartnered.count == 2
          unpartnered[0].doubles_partner = unpartnered[1]
          unpartnered[1].doubles_partner = unpartnered[0]
          unpartnered.map(&:save)
        end
      end

      # Need to actually register the bowler, derp. (And auto-assign doubles partner if possible.)
      render json: BowlerBlueprint.render(bowler.reload, view: :director_detail), status: :created
    end

    def update
      load_bowler_and_tournament
      unless bowler.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      try_updating_details
      try_updating_additional_question_responses
      try_reassigning
      try_partnering

      if error.present?
        render json: { error: error }, status: :bad_request
        return
      end

      # render json: BowlerBlueprint.render(bowler.reload, view: :director_detail)
      render json: DirectorBowlerSerializer.new(bowler.reload).as_json
    end

    def destroy
      load_bowler_and_tournament
      unless bowler.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      bowler.destroy

      render json: nil, status: :no_content
    end

    def resend_email
      load_bowler_and_tournament
      unless bowler.present?
        skip_authorization
        render json: nil, status: :not_found
        return
      end

      authorize tournament, :update?

      email_params = params.permit(:type, :order_identifier, :identifier)
      case email_params['type']
      when 'registration'
        TournamentRegistration.send_confirmation_email(bowler)
      when 'payment_receipt'
        ep = ExternalPayment.find_by_identifier(email_params['order_identifier'])
        TournamentRegistration.send_receipt_email(bowler, ep.id) unless ep.nil?
      end

      render json: nil, status: :no_content
    end

    private

    attr_accessor :tournament, :bowler, :error

    def load_tournament
      id = params.require(:tournament_identifier)
      @tournament = Tournament.find_by_identifier(id)
    end

    def load_bowler_and_tournament
      id = params.require(:identifier)
      @bowler = Bowler.includes(:purchases,
        :ledger_entries,
        :additional_question_responses,
        :team,
        :person,
        :free_entry,
        doubles_partner: :person,
        tournament: [:additional_questions],
      ).find_by(identifier: id)
      @tournament = @bowler.tournament if @bowler.present?
    end

    def update_bowler_params
      params.require(:bowler).permit(
        team: %i(identifier),
        doubles_partner: %i(identifier),
        person_attributes: PERSON_ATTRS,
        additional_question_responses: %i(name response),
        verified_data: %i(verified_average handicap igbo_member),
      )
            .to_h.with_indifferent_access
    end

    def create_bowler_params
      bowler_data = params.require(:bowler).permit(
        :position,
        team: %i(identifier),
        doubles_partner: %i(identifier),
        person_attributes: PERSON_ATTRS,
        additional_question_responses: %i(name response),
        verified_data: %i(verified_average handicap igbo_member),
      ).to_h.with_indifferent_access
      bowler_data[:additional_question_responses_attributes] = additional_question_response_data(bowler_data[:additional_question_responses])
      bowler_data.delete(:additional_question_responses)

      # Are we creating a bowler on a team?
      unless bowler_data[:team][:identifier].blank?
        team = tournament.teams.find_by(identifier: bowler_data[:team][:identifier])
        unless team.present?
          self.error = 'Could not find the specified team.'
          return
        end

        unless team.bowlers.count < tournament.team_size
          self.error = 'The specified team is full.'
          return
        end

        bowler_data[:team_id] = team.id
        bowler_data.delete(:team)
      end

      bowler_data
    end

    def additional_question_response_data(responses)
      responses.each_with_object([]) do |response_param, collected|
        collected << {
          response: response_param[:response],
          extended_form_field_id: extended_form_fields[response_param[:name]].id,
        }
      end
    end

    def extended_form_fields
      @extended_form_fields ||= ExtendedFormField.all.index_by(&:name)
    end

    def try_reassigning
      bowler_data = update_bowler_params
      return unless bowler_data[:team].present?

      new_team = tournament.teams.find_by(identifier: bowler_data[:team][:identifier])
      unless new_team.present?
        self.error = 'Could not find the specified team.'
        return
      end

      unless new_team.bowlers.count < tournament.team_size
        self.error = 'The specified team is full.'
        return
      end

      DirectorUtilities.reassign_bowler(bowler: bowler, to_team: new_team)
    end

    def try_partnering
      bowler_data = update_bowler_params
      return unless bowler_data[:doubles_partner] && bowler_data[:doubles_partner][:identifier].present?

      new_partner = tournament.bowlers.find_by(identifier: bowler_data[:doubles_partner][:identifier])
      unless new_partner.present?
        self.error = 'Could not find the desired bowler to partner up with'
        return
      end

      DirectorUtilities.assign_partner(bowler: bowler, new_partner: new_partner)
    end

    def try_updating_details
      bowler_data = update_bowler_params

      # First, update bowler deets
      if bowler_data[:verified_data].present?
        bowler.verified_data.merge!(bowler_data[:verified_data])
        unless bowler.save
          self.error = bowler.errors.full_messages
          return
        end
      end

      # Next, update person deets, if there are any
      return unless bowler_data[:person_attributes].present?

      unless bowler.person.update(bowler_data[:person_attributes])
        self.error = bowler.person.errors.full_messages
      end
    end

    def try_updating_additional_question_responses
      bowler_data = update_bowler_params
      return false unless bowler_data[:additional_question_responses].present?

      bowler_data[:additional_question_responses].each do |aqr_data|
        aqr = bowler.additional_question_responses.joins(:extended_form_field).where(extended_form_field: { name: aqr_data[:name] }).first

        # is the name one that the tournament supports? if so, let's create one instead of barking about it
        unless aqr.present?
          eff = tournament.extended_form_fields.find_by_name(aqr_data[:name])
          unless eff.present?
            # ok, NOW we can bark about it.
            self.error = "Unrecognized additional question: #{aqr_data[:name]}"
            return
          end
          aqr = AdditionalQuestionResponse.create(bowler: bowler, extended_form_field: eff)
        end

        unless aqr.update(response: aqr_data[:response])
          self.error = bowler.person.errors.full_messages
          return
        end
      end
    end
  end
end
