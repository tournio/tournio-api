require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::TournamentsController, type: :request do
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

    let(:uri) { '/director/tournaments' }

    let!(:setup_tournament) { create :tournament }
    let!(:testing_tournament) { create :tournament, :testing }
    let!(:active_tournament) { create :tournament, :active }
    let!(:closed_tournament) { create :tournament, :closed }

    include_examples 'an authorized action'

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'includes all tournaments in the response' do
      subject
      expect(json.length).to eq(4);
    end

    it 'includes the tournament id in each one' do
      subject
      expect(json[0]).to have_key('id')
    end

    context 'When all I need is upcoming tournaments' do
      let(:uri) { '/director/tournaments?upcoming=true' }

      it 'excludes past tournaments' do
        subject
        expect(json.length).to eq(3);
      end
    end

    context 'When I am a tournament director' do
      let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
      let(:my_tournaments) { [testing_tournament, active_tournament] }

      it 'includes just my tournaments in the response' do
        subject
        expect(json.length).to eq(2);
      end

      context 'with no active tournaments' do
        let(:my_tournaments) { [] }

        it 'returns an empty array' do
          subject
          expect(json).to be_empty
        end

        it 'returns a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end

  end

  describe '#show' do
    subject { get uri, headers: auth_headers }

    let(:uri) { "/director/tournaments/#{tournament.identifier}" }

    let(:tournament) { create :tournament }

    include_examples 'an authorized action'

    it 'returns a JSON representation of the tournament' do
      subject
      expect(json['identifier']).to eq(tournament.identifier)
    end

    context 'When I am an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'When I am a tournament director' do
      let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
      let(:my_tournaments) { [] }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'for this tournament' do
        let(:my_tournaments) { [tournament] }

        it 'yields a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'returns a JSON representation of the tournament' do
          subject
          expect(json['identifier']).to eq(tournament.identifier);
        end
      end
    end
  end

  describe '#clear_test_data' do
    subject { post uri, headers: auth_headers }

    let(:uri) { "/director/tournaments/#{tournament.identifier}/clear_test_data" }

    let(:tournament) { create :tournament, :testing }

    include_examples 'an authorized action'

    context 'Tournament modes' do
      context 'Setup' do
        let(:tournament) { create :tournament }

        it 'rejects the request' do
          subject
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'Testing' do
        let(:tournament) { create :tournament, :testing }

        it 'responds with 204 No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end
      end

      context 'Active' do
        let(:tournament) { create :tournament, :active }

        it 'rejects the request' do
          subject
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'Closed' do
        let(:tournament) { create :tournament, :closed }

        it 'rejects the request' do
          subject
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context 'When I am an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'When I am a tournament director' do
      let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
      let(:my_tournaments) { [] }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'for this tournament' do
        let(:my_tournaments) { [tournament] }

        it 'yields a 204 No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end
      end
    end
  end

  describe '#state_change' do
    subject { post uri, headers: auth_headers, params: { state_action: action }, as: :json }

    let(:uri) { "/director/tournaments/#{tournament.identifier}/state_change" }

    let(:tournament) { create :tournament }
    let(:action) { 'test' }

    include_examples 'an authorized action'

    context 'Tournament modes' do
      context 'Setup' do
        it 'responds with 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'moves the tournament into test mode' do
          subject
          expect(tournament.reload.testing?).to be_truthy
        end

        context 'Going into demo mode' do
          let(:action) { 'demonstrate' }

          it 'responds with 200 OK' do
            subject
            expect(response).to have_http_status(:ok)
          end

          it 'moves the tournament into demo mode' do
            subject
            expect(tournament.reload.demo?).to be_truthy
          end

          context 'as a tournament director' do
            let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
            let(:my_tournaments) { [] }

            it 'yields a 401 Unauthorized' do
              subject
              expect(response).to have_http_status(:unauthorized)
            end

            context 'for this tournament' do
              let(:my_tournaments) { [tournament] }

              it 'it still yields a 401 Unauthorized' do
                subject
                expect(response).to have_http_status(:unauthorized)
              end
            end
          end
        end
      end

      context 'Testing' do
        let(:tournament) { create :tournament, :testing }
        let(:action) { 'open' }

        it 'responds with 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'moves the tournament into active mode' do
          subject
          expect(tournament.reload.active?).to be_truthy
        end
      end

      context 'Active' do
        let(:tournament) { create :tournament, :active }
        let(:action) { 'close' }

        it 'responds with a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'moves the tournament into closed mode' do
          subject
          expect(tournament.reload.closed?).to be_truthy
        end
      end

      context 'Closed' do
        let(:tournament) { create :tournament, :closed }

        it 'rejects the request' do
          subject
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'Demo' do
        let(:tournament) { create :tournament, :demo }
        let(:action) { 'reset' }

        it 'responds with a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'moves the tournament into setup mode' do
          subject
          expect(tournament.reload.setup?).to be_truthy
        end

        context 'as a tournament director' do
          let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
          let(:my_tournaments) { [] }

          it 'yields a 401 Unauthorized' do
            subject
            expect(response).to have_http_status(:unauthorized)
          end

          context 'for this tournament' do
            let(:my_tournaments) { [tournament] }

            it 'it still yields a 401 Unauthorized' do
              subject
              expect(response).to have_http_status(:unauthorized)
            end
          end
        end
      end
    end

    context 'When I am an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'When I am a tournament director' do
      let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
      let(:my_tournaments) { [] }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'for this tournament' do
        let(:my_tournaments) { [tournament] }

        it 'yields a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe '#update' do
    subject { patch uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/tournaments/#{tournament.identifier}" }

    let(:tournament) { create :tournament }
    let(:eff) { create :extended_form_field }
    let(:params) do
      {
        tournament: {
          additional_questions_attributes: [
            {
              extended_form_field_id: eff.id,
              validation_rules: {
                required: false,
              },
              order: 1,
            },
          ],
        },
      }
    end

    include_examples 'an authorized action'

    it 'responds with OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'creates an additional question' do
      expect{ subject }.to change { AdditionalQuestion.count }.by(1)
    end

    it 'includes the necessary stuff in the response' do
      subject
      expect(json['identifier']).to eq(tournament.identifier)
      expect(json['additional_questions']).not_to be_empty
    end

    context 'changing the order of existing questions' do
      let!(:aq1) { create :additional_question, extended_form_field: eff, tournament: tournament }
      let!(:aq2) { create :additional_question, extended_form_field: create(:extended_form_field, :average), tournament: tournament }
      let(:params) do
        {
          tournament: {
            additional_questions_attributes: [
              {
                id: aq1.id,
                order: 2,
                _destroy: false,
              },
              {
                id: aq2.id,
                order: 1,
                _destroy: false,
              },
            ],
          },
        }
      end

      it 'responds with OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'does not change the count of Additional Questions' do
        expect{ subject }.not_to change { AdditionalQuestion.count }
      end
    end

    context 'deleting an existing question' do
      let!(:aq1) { create :additional_question, extended_form_field: eff, tournament: tournament }
      let!(:aq2) { create :additional_question, extended_form_field: create(:extended_form_field, :average), tournament: tournament }
      let(:params) do
        {
          tournament: {
            additional_questions_attributes: [
              {
                id: aq1.id,
                order: 2,
                _destroy: true,
              },
              {
                id: aq2.id,
                order: 1,
                _destroy: false,
              },
            ],
          },
        }
      end

      it 'responds with OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'drops the count of Additional Questions' do
        expect{ subject }.to change { AdditionalQuestion.count }.by(-1)
      end
    end

    context 'a question that has validation rules' do
      let(:eff) { create :extended_form_field, :average }
      let(:params) do
        {
          tournament: {
            additional_questions_attributes: [
              {
                extended_form_field_id: eff.id,
                validation_rules: {
                  required: true,
                },
                order: 1,
              },
            ],
          },
        }
      end

      it "merges validation rules with what's on the EFF" do
        subject
        eff_key_count = eff.validation_rules.keys.count
        expect(AdditionalQuestion.last.validation_rules.keys.count).to eq(eff_key_count + 1)
      end
    end

    context 'Other tournament modes' do
      context 'Testing' do
        let(:tournament) { create :tournament, :testing }

        it 'responds with OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'creates an additional question' do
          expect{ subject }.to change { AdditionalQuestion.count }.by(1)
        end
      end

      context 'Active' do
        let(:tournament) { create :tournament, :active }

        it 'responds with Forbidden' do
          subject
          expect(response).to have_http_status(:forbidden)
        end

        it 'does not create an additional question' do
          expect{ subject }.not_to change { AdditionalQuestion.count }
        end
      end

      context 'Closed' do
        let(:tournament) { create :tournament, :closed }

        it 'rejects the request' do
          subject
          expect(response).to have_http_status(:forbidden)
        end

        it 'does not create an additional question' do
          expect{ subject }.not_to change { AdditionalQuestion.count }
        end
      end
    end

    context 'When I am an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'When I am a tournament director' do
      let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
      let(:my_tournaments) { [] }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'for this tournament' do
        let(:my_tournaments) { [tournament] }

        it 'responds with OK' do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end


  describe '#csv_download' do

  end

  describe '#igbots_download' do

  end

  describe '#email_payment_reminders' do
    subject { post uri, headers: auth_headers, as: :json }

    let(:uri) { "/director/tournaments/#{tournament_identifier}/email_payment_reminders" }

    let(:tournament) { create :tournament }
    let(:tournament_identifier) { tournament.identifier }

    include_examples 'an authorized action'

    context 'an unrecognized tournament identifier' do
      let(:tournament_identifier) { 'i-dont-know-her' }

      it 'responds with a Not Found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'Tournament modes' do
      context 'Setup' do
        it 'responds with Forbidden' do
          subject
          expect(response).to have_http_status(:forbidden)
        end

        it 'does not invoke the scheduler' do
          expect { subject }.not_to change(PaymentReminderSchedulerJob.jobs, :size)
        end
      end

      context 'Testing' do
        let(:tournament) { create :tournament, :testing }

        it 'responds with Forbidden' do
          subject
          expect(response).to have_http_status(:forbidden)
        end

        it 'does not invoke the scheduler' do
          expect { subject }.not_to change(PaymentReminderSchedulerJob.jobs, :size)
        end
      end

      context 'Active' do
        let(:tournament) { create :tournament, :active }

        it 'responds with OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'invokes the scheduler' do
          expect { subject }.to change(PaymentReminderSchedulerJob.jobs, :size).by(1)
        end
      end

      context 'Closed' do
        let(:tournament) { create :tournament, :closed }

        it 'responds with OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'invokes the scheduler' do
          expect { subject }.to change(PaymentReminderSchedulerJob.jobs, :size).by(1)
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete uri, headers: auth_headers, as: :json }

    let(:uri) { "/director/tournaments/#{tournament_identifier}" }

    let(:tournament) { create :tournament }
    let(:tournament_identifier) { tournament.identifier }

    include_examples 'for superusers only', :no_content

    context 'an unrecognized tournament identifier' do
      let(:tournament_identifier) { 'i-dont-know-her' }

      it 'responds with a Not Found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'Tournament modes' do
      context 'Setup' do
        it 'responds with No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'destroys the tournament' do
          subject
          begin
            tournament.reload
          rescue => exception
          ensure
            expect(exception).to be_instance_of ActiveRecord::RecordNotFound
          end
        end
      end

      context 'Testing' do
        let(:tournament) { create :tournament, :testing }

        it 'responds with No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'destroys the tournament' do
          subject
          begin
            tournament.reload
          rescue => exception
          ensure
            expect(exception).to be_instance_of ActiveRecord::RecordNotFound
          end
        end
      end

      context 'Active' do
        let(:tournament) { create :tournament, :active }

        it 'responds with Forbidden' do
          subject
          expect(response).to have_http_status(:forbidden)
        end

        it 'does not destroy the tournament' do
          subject
          expect(tournament.reload).not_to be_nil
        end
      end

      context 'Closed' do
        let(:tournament) { create :tournament, :closed }

        it 'responds with No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'destroys the tournament' do
          subject
          begin
            tournament.reload
          rescue => exception
          ensure
            expect(exception).to be_instance_of ActiveRecord::RecordNotFound
          end
        end
      end
    end
  end



end
