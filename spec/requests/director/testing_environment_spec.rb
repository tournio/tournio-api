require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::TestingEnvironmentsController, type: :request do
  let(:requesting_user) { create(:user, :superuser) }
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, requesting_user) }

  describe '#update' do
    subject { patch uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/tournaments/#{tournament.identifier}/testing_environment" }
    let(:params) do
      {
        testing_environment: {
          conditions: env_param,
        },
      }
    end
    let(:env_param) { { registration_period: 'late' } }

    let(:tournament) { create :tournament, :testing }

    include_examples 'an authorized action'

    context 'Tournament modes' do
      context 'Setup' do
        let(:tournament) { create :tournament }

        it 'responds with 409 Conflict' do
          subject
          expect(response).to have_http_status(:conflict)
        end
      end

      context 'Testing' do
        let(:tournament) { create :tournament, :testing }

        it 'responds with 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end
      end

      context 'Active' do
        let(:tournament) { create :tournament, :active }

        it 'responds with 409 Conflict' do
          subject
          expect(response).to have_http_status(:conflict)
        end
      end

      context 'Closed' do
        let(:tournament) { create :tournament, :closed }

        it 'responds with 409 Conflict' do
          subject
          expect(response).to have_http_status(:conflict)
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
      end
    end

    context 'When I specify an unknown condition name' do
      let(:env_param) do
        {
          sociological_age: 'gilded',
        }
      end

      it 'responds with 422 Unprocessable Entity' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'puts an error message into the response' do
        subject
        expect(json).to have_key('error')
      end

      context 'in addition to a known one' do
        let(:env_param) do
          {
            registration_period: 'early',
            sociological_age: 'gilded',
          }
        end

        it 'responds with 422 Unprocessable Entity' do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'puts an error message into the response' do
          subject
          expect(json).to have_key('error')
        end
      end
    end

    context 'When I specify an unknown value for a known condition' do
      let(:env_param) do
        {
          registration_period: 'last minute',
        }
      end

      it 'responds with 422 Unprocessable Entity' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'puts an error message into the response' do
        subject
        expect(json).to have_key('error')
      end
    end
  end
end
