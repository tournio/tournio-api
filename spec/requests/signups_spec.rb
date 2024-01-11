require 'rails_helper'

describe SignupsController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe "#update" do
    subject { patch uri, params: params, as: :json }

    let(:uri) { "/signups/#{signup_identifier}" }

    let(:tournament) { create :tournament, :active, :with_an_optional_event }
    let(:bowler) do
      create :bowler,
        tournament: tournament
    end
    let(:bowler_identifier) { bowler.identifier }
    let(:purchasable_item) do
      create :purchasable_item, :optional_event,
        tournament: tournament
    end
    let(:signup) { create :signup, bowler: bowler, purchasable_item: purchasable_item }
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
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'returns an updated Signup with in the response' do
      subject
      expect(json['status']).to eq('requested')
    end

    context 'changing their mind after requesting' do
      let(:signup) { create :signup, :requested, bowler: bowler, purchasable_item: purchasable_item }
      let(:event_name) { 'never_mind' }

      it 'returns the status to initial' do
        subject
        expect(json['status']).to eq('initial')
      end
    end

    describe 'error scenarios' do
      context 'changing their mind after paying' do
        let(:signup) { create :signup, :paid, bowler: bowler, purchasable_item: purchasable_item }
        let(:event_name) { 'never_mind' }

        it 'rejects the request with Conflict' do
          subject
          expect(response).to have_http_status(:conflict)
        end
      end

      context 'with an unrecognized event' do
        let(:event_name) { 'lolwut' }

        it 'rejects the request with Unprocessable Entity' do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with an unrecognized bowler' do
        let(:bowler_identifier) { 'i-dont-know-her' }

        it 'rejects the request with Unprocessable Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'with an unrecognized signup identifier' do
        let(:signup_identifier) { 'my-totally-legit-signup' }

        it 'rejects the request with Unprocessable Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
