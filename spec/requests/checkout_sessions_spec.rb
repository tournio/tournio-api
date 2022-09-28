require 'rails_helper'

RSpec.describe CheckoutSessionsController, type: :request do
  describe "#show" do
    subject { get "/checkout_sessions/#{identifier}" }

    let(:tournament) { create :tournament }
    let(:bowler) { create :bowler, tournament: tournament }
    let(:checkout_session) { create :stripe_checkout_session, bowler_id: bowler.id }
    let(:identifier) { checkout_session.identifier }

    it 'returns a success status code' do
      subject
      expect(response).to have_http_status :ok
    end

    it 'returns the important details of a checkout session' do
      subject
      expect(json.keys).to match_array(%w(identifier status))
    end

    context 'error conditions' do
      let(:identifier) { 'i-dont-know-her' }

      it 'returns a Not Found' do
        subject
        expect(response).to have_http_status :not_found
      end
    end
  end
end
