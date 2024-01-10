require 'rails_helper'

RSpec.describe SignupsController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe "PATCH :update" do
    subject { patch uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/#{signup_identifier}" }

    let(:bowler) { create :bowler, :with_team }
    let(:bowler_identifier) { bowler.identifier }
    let(:tournament) { bowler.tournament }
    let(:purchasable_item) do
      create :purchasable_item, :optional_event,
        tournament: tournament
    end
    let(:signup) { Signup.create(bowler: bowler, purchasable_item: purchasable_item) }
    let(:signup_identifier) { signup.identifier }

    let(:params) do
      {
        bowler_identifier: bowler_identifier,
        event: event_name,
      }
    end

    # default behavior: request
    let(:event_name) { 'request' }

    it 'returns a 200 OK' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns an updated Signup with in the response' do
      expect(json['status']).to eq('requested')
    end

    context 'changing their mind after requesting' do
      let(:event_name) { 'never_mind' }

      expect(json['status']).to eq('initial')
    end

    describe 'error scenarios' do
      context 'changing their mind after paying' do
        let(:event_name) { 'never_mind' }

        before do
          signup.pay!
        end

        it 'rejects the request with Conflict' do
          expect(response).to have_http_status(:conflict)
        end
      end

      context 'with an unrecognized event' do
        let(:event_name) { 'lolwut' }

        it 'rejects the request with Unprocessable Entity' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with an unrecognized bowler' do
        let(:bowler_identifier) { 'i-dont-know-her' }

        it 'rejects the request with Unprocessable Not Found' do
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'with an unrecognized signup identifier' do
        let(:signup_identifier) { 'my-totally-legit-signup' }

        it 'rejects the request with Unprocessable Not Found' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

end
