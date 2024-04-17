require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::BowlersController, type: :request do
  let(:requesting_user) { create(:user, :superuser) }
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, requesting_user) }

  describe '#index' do
    subject { get uri, headers: auth_headers }

    let(:uri) { "/director/tournaments/#{tournament_identifier}/bowlers" }

    let(:tournament_identifier) { tournament.identifier }
    let(:tournament) { create :tournament, :active }

    before do
      10.times do
        create :bowler, :with_team, tournament: tournament
      end
      for i in 0..4 do
        src = tournament.bowlers[i*2]
        partner = tournament.bowlers[i*2 + 1]
        src.update(doubles_partner_id: partner.id)
        partner.update(doubles_partner_id: src.id)
      end
    end

    include_examples 'an authorized action'

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'includes all registered bowlers in the response' do
      subject
      expect(json.length).to eq(10);
    end

    context 'when requesting the modern serializer' do
      let(:uri) { "/director/tournaments/#{tournament_identifier}/bowlers?serializer=modern" }

      it 'includes a field used on the modern serializer' do
        subject
        expect(json[0]).to have_key('createdAt')
      end
    end

    context 'retrieving only unpartnered bowlers' do
      let(:uri) { "/director/tournaments/#{tournament_identifier}/bowlers?unpartnered=true" }

      before do
        7.times do
          create :bowler, :with_team, tournament: tournament
        end
      end

      it 'includes all unpartnered bowlers in the response' do
        subject
        expect(json.length).to eq(7)
      end
    end

    context 'as an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'as a director' do
      let(:requesting_user) { create(:user, :director) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'associated with this tournament' do
        let(:requesting_user) { create :user, :director, tournament_orgs: [tournament.tournament_org] }

        it 'shall pass' do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'error scenarios' do
      context 'an unrecognized tournament identifier' do
        let(:tournament_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#show' do
    subject { get uri, headers: auth_headers }

    let(:uri) { "/director/bowlers/#{bowler_identifier}" }

    let(:bowler) { create :bowler, :with_team }
    let(:tournament) { bowler.tournament }
    let(:bowler_identifier) { bowler.identifier }

    include_examples 'an authorized action'

    it 'returns a 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'returns a JSON representation of the bowler' do
      subject
      expect(json['identifier']).to eq(bowler.identifier);
    end

    context 'When I am an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'When I am a tournament director' do
      let(:requesting_user) { create(:user, :director, tournament_orgs: my_orgs) }
      let(:my_orgs) { [] }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'for this tournament' do
        let(:my_orgs) { [tournament.tournament_org] }

        it 'yields a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'returns a JSON representation of the bowler' do
          subject
          expect(json['identifier']).to eq(bowler.identifier);
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete uri, headers: auth_headers, as: :json }

    let(:uri) { "/director/bowlers/#{bowler_identifier}" }

    let(:bowler) { create :bowler }
    let(:bowler_identifier) { bowler.identifier }
    let(:tournament) { bowler.tournament }

    include_examples 'an authorized action'

    it 'succeeds with a 204 No Content' do
      subject
      expect(response).to have_http_status(:no_content)
    end

    context 'as an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'as a director' do
      let(:requesting_user) { create(:user, :director) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'associated with this tournament' do
        let(:requesting_user) { create :user, :director, tournament_orgs: [tournament.tournament_org] }

        it 'shall pass' do
          subject
          expect(response).to have_http_status(:no_content)
        end
      end
    end

    context 'error scenarios' do
      context 'an unrecognized team identifier' do
        let(:bowler_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#update' do
    subject { patch uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/bowlers/#{bowler_identifier}" }

    let(:bowler) { create :bowler, :with_team }
    let(:tournament) { bowler.tournament }
    let(:team) { bowler.team }
    let(:bowler_identifier) { bowler.identifier }
    let(:person_attributes) { { nickname: 'Freddy' } }
    let(:team_params) { {} }
    let(:partner_params) { {} }
    let(:additional_question_response_params) { {} }
    let(:verified_data_params) { {} }
    let(:params) do
      {
        bowler: {
          person_attributes: person_attributes,
          team: team_params,
          doubles_partner: partner_params,
          additional_question_responses: additional_question_response_params,
          verified_data: verified_data_params,
        },
      }
    end

    include_examples 'an authorized action'

    before do
      team.update(name: 'Ladies Who Lunch')
    end

    it 'succeeds with a 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'includes the updated bowler in the response' do
      subject
      expect(json).to have_key('last_name')
      expect(json).to have_key('identifier')
      expect(json['nickname']).to eq('Freddy')
    end

    it 'does not change their team' do
      subject
      expect(json['team']['name']).to eq('Ladies Who Lunch')
    end

    context 'as an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'as a director' do
      let(:requesting_user) { create(:user, :director) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'associated with this tournament' do
        let(:requesting_user) { create :user, :director, tournament_orgs: [tournament.tournament_org] }

        it 'shall pass' do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'moving the bowler to a different team' do
      let(:new_team) { create :team, name: 'Dudes Who Dance', tournament: tournament }
      let(:team_params) { { identifier: new_team.identifier } }

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'includes the updated bowler in the response' do
        subject
        expect(json).to have_key('identifier')
      end

      it 'reflects the new team' do
        subject
        expect(json['team']['name']).to eq('Dudes Who Dance')
      end

      context 'without supplying person_attributes' do
        let(:params) do
          {
            bowler: {
              team: team_params,
            },
          }
        end

        it 'succeeds with a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'reflects the new team' do
          subject
          expect(json['team']['name']).to eq('Dudes Who Dance')
        end
      end
    end

    context 'assigning a new doubles partner' do
      let(:new_partner) { create :bowler, tournament: tournament }
      let(:partner_params) { { identifier: new_partner.identifier } }

      before do
        create :purchasable_item, :doubles_event, tournament: tournament
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'includes the updated doubles partner in the response' do
        subject
        expect(json['doubles_partner']['full_name']).to eq(TournamentRegistration.person_list_name(new_partner.person))
      end
    end

    context 'updating an additional question response' do
      let(:aq) do
        create(:additional_question,
               extended_form_field: create(:extended_form_field, :standings_link),
               tournament: tournament)
      end
      let(:additional_question_response_params) do
        [
          {
            name: aq.name,
            response: 'my updated response',
          }
        ]
      end

      before do
        create :additional_question_response,
               response: 'my response',
               extended_form_field: aq.extended_form_field,
               bowler: bowler
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'includes the updated bowler in the response' do
        subject
        expect(json).to have_key('identifier')
      end

      it 'reflects the response' do
        subject
        expect(json).to have_key('additional_question_responses')
        expect(json['additional_question_responses'][aq.name]['response']).to eq('my updated response')
      end

      context 'to an empty response' do
        let(:additional_question_response_params) do
          [
            {
              name: aq.name,
              response: '',
            }
          ]
        end

        it 'reflects the response' do
          subject
          expect(json).to have_key('additional_question_responses')
          expect(json['additional_question_responses'][aq.name]['response']).to eq('')
        end
      end
    end

    context 'creating an additional question response' do
      let(:aq) do
        create(:additional_question,
          extended_form_field: create(:extended_form_field, :comment),
          tournament: tournament)
      end
      let(:additional_question_response_params) do
        [
          {
            name: aq.name,
            response: 'info provided by a director about the bowler',
          }
        ]
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'includes the updated bowler in the response' do
        subject
        expect(json).to have_key('identifier')
      end

      it 'reflects the response' do
        subject
        expect(json).to have_key('additional_question_responses')
        expect(json['additional_question_responses'][aq.name]['response']).to eq('info provided by a director about the bowler')
      end
    end

    context 'updating verified data' do
      let(:verified_data_params) do
        {
          verified_average: 199,
          handicap: 17,
          igbo_member: true,
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'includes the updated bowler in the response' do
        subject
        expect(json).to have_key('identifier')
      end

      it 'reflects the response' do
        subject
        expect(json).to have_key('verified_average')
        expect(json['verified_average']).to eq(199)
      end

      it 'includes the igbo_member property' do
        subject
        expect(json).to have_key('igbo_member')
        expect(json['igbo_member']).to eq(true)
      end
    end

    context 'error scenarios' do
      context 'an unrecognized bowler identifier' do
        let(:bowler_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'an unknown additional question' do
        let(:additional_question_response_params) do
          [
            {
              name: 'unknown-form-field',
              response: 'my detailed response to it',
            }
          ]
        end

        it 'yields a 400 Bad Request' do
          subject
          expect(response).to have_http_status(:bad_request)
        end

        it 'puts the validation errors into the response' do
          subject
          expect(json).to have_key('error')
        end
      end

      context 'a failed validation' do
        context 'missing a required value' do
          let(:person_attributes) { { last_name: '' } }

          it 'yields a 400 Bad Request' do
            subject
            expect(response).to have_http_status(:bad_request)
          end

          it 'puts the validation errors into the response' do
            subject
            expect(json).to have_key('error')
          end
        end
      end

      context 'moving the bowler to an unrecognized team' do
        let(:team_params) { { identifier: 'you-shall-not-pass' } }

        it 'yields a 400 Bad Request' do
          subject
          expect(response).to have_http_status(:bad_request)
        end

        it "does not change the bowler's team" do
          subject
          expect(bowler.team.reload.identifier).to eq(team.identifier)
        end
      end

      context 'moving the bowler to a full team' do
        let(:new_team) { create :team, :standard_full_team, tournament: tournament }
        let(:team_params) { { identifier: new_team.identifier } }

        it 'yields a 400 Bad Redquest' do
          subject
          expect(response).to have_http_status(:bad_request)
        end

        it "does not change the bowler's team" do
          subject
          expect(bowler.team.reload.identifier).to eq(team.identifier)
        end
      end
    end
  end

  describe '#create' do
    subject { post uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/tournaments/#{tournament.identifier}/bowlers" }

    let(:tournament) { create :tournament, :with_additional_questions }
    let(:team) { create :team, tournament: tournament }
    let(:partner_params) { {} }
    let(:params) do
      {
        bowler: create_bowler_test_data.merge({
          team: {
            identifier: team.identifier,
          },
        })
      }
    end

    include_examples 'an authorized action'

    it 'succeeds with a 201 Created' do
      subject
      expect(response).to have_http_status(:created)
    end

    it 'includes the new bowler in the response' do
      subject
      expect(json).to have_key('last_name')
      expect(json).to have_key('identifier')
      expect(json['nickname']).to eq('Gio')
    end

    # bowler blueprint: director detail
    it 'includes the team in the response' do
      subject
      expect(json['team']['identifier']).to eq(team.identifier)
    end

    it 'includes the additional question responses' do
      subject
      expect(json['additional_question_responses']).to have_key('pronouns')
    end

    context 'without extraneous data' do
      let(:params) do
        {
          bowler: create_bowler_slimmed_down_test_data.merge({
            team: {
              identifier: team.identifier,
            },
          })
        }
      end

      it 'succeeds with a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end
    end

    context 'as an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'as a director' do
      let(:requesting_user) { create(:user, :director) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'associated with this tournament' do
        let(:requesting_user) { create :user, :director, tournament_orgs: [tournament.tournament_org] }

        it 'shall pass' do
          subject
          expect(response).to have_http_status(:created)
        end
      end
    end
  end

  describe '#resend_email' do
    subject { post uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/bowlers/#{bowler_identifier}/resend_email" }

    let(:tournament) { bowler.tournament }
    let(:recipient_email) { 'the_bowler@the.correct.domain' }
    let(:bowler) { create :bowler, person: create(:person, email: recipient_email) }
    let(:bowler_identifier) { bowler.identifier }

    let(:email_type) { 'registration' }
    let(:order) { nil }

    let(:params) do
      {
        type: email_type,
        order_identifier: order&.identifier,
      }
    end

    include_examples 'an authorized action'

    it 'Succeeds with No Content' do
      subject
      expect(response).to have_http_status(:no_content)
    end

    it 'sends a confirmation email' do
      expect(TournamentRegistration).to receive(:send_confirmation_email).with(bowler)
      subject
    end

    context 'a payment receipt email' do
      let(:email_type) { 'payment_receipt' }
      let(:order) { create :external_payment, :from_stripe }

      it 'sends a receipt email' do
        expect(TournamentRegistration).to receive(:send_receipt_email).with(bowler, order.id)
        subject
      end
    end
  end
end
