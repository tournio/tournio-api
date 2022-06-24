require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::TournamentsController, type: :controller do
  let(:requesting_user) { create(:user, :superuser) }
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, requesting_user) }

  describe '#stripe_refresh' do
    subject do
      request.headers.merge!(auth_headers)
      get :stripe_refresh, params: { identifier: tournament.identifier }
    end

    let(:tournament) { create :tournament }
    let(:link_url) { 'http://this-is-stripe' }
    let(:expires_at) { Time.zone.now + 10.minutes }
    let(:stripe_account) do
      create :stripe_account,
        tournament: tournament,
        link_url: link_url,
        link_expires_at: expires_at
    end

    include_examples 'an authorized action'

    before do
      allow(controller).to receive(:find_stripe_account)
      allow(controller).to receive(:create_stripe_account).and_return(stripe_account)
      allow(controller).to receive(:get_updated_account_link)
    end

    it 'responds with OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'tries to create an account' do
      expect(controller).to receive(:create_stripe_account).once
      subject
    end

    it 'tries to create an account link' do
      expect(controller).to receive(:get_updated_account_link).once
      subject
    end

    it 'includes the necessary stuff in the response' do
      subject
      expect(json).to have_key('link_url')
      expect(json).to have_key('link_expires_at')
    end

    it 'contains the expected values' do
      subject
      expect(json['link_url']).to eq(link_url)
      expect(json['link_expires_at']).to eq(expires_at.strftime('%F %T UTC'))
    end

    context 'when we already have a Stripe account' do
      before do
        allow(controller).to receive(:find_stripe_account).and_call_original
        allow(controller).to receive(:create_stripe_account).and_return(nil)
      end

      it 'does not try to create an account' do
        expect(controller).not_to receive(:create_stripe_account)
        subject
      end

      it 'tries to create an account link' do
        expect(controller).to receive(:get_updated_account_link).once
        subject
      end
    end

    context 'when communication with Stripe fails on account creation' do
      before do
        allow(controller).to receive(:create_stripe_account).and_return(nil)
      end

      it 'has a predictable status code' do
        subject
        expect(response).to have_http_status(:service_unavailable)
      end

      it 'contains an error message' do
        subject
        expect(json).to have_key('error')
      end

      it 'gives a meaningful message' do
        subject
        expect(json['error']).to eq('Failed to create a Stripe account in time.')
      end
    end

    context 'when communication with Stripe fails on account link creation' do
      before do
        stripe_account.update(link_url: nil, link_expires_at: nil)
      end

      it 'has a predictable status code' do
        subject
        expect(response).to have_http_status(:service_unavailable)
      end

      it 'contains an error message' do
        subject
        expect(json).to have_key('error')
      end

      it 'gives a meaningful message' do
        subject
        expect(json['error']).to eq('Failed to get an account link in time.')
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
end
