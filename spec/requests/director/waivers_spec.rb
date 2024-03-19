# frozen_string_literal: true

require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::WaiversController, type: :request do
  let(:requesting_user) { create(:user, :superuser) }
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, requesting_user) }

  # Things common to both request paths
  let(:tournament) { create :tournament, :with_entry_fee, :with_late_fee }
  let(:bowler) { create :bowler, tournament: tournament }
  let(:bowler_identifier) { bowler.identifier }
  let(:late_fee_item) { tournament.purchasable_items.late_fee.first }

  describe '#create' do
    subject { post uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/bowlers/#{bowler_identifier}/waivers" }

    let(:params) { {} }

    ###############

    include_examples 'an authorized action'

    it 'succeeds with a 201 Created' do
      subject
      expect(response).to have_http_status(:created)
    end

    it 'returns the created item' do
      subject
      expect(json).to have_key('amount')
    end

    it 'creates a waiver' do
      expect { subject }.to change(Waiver, :count).by(1)
    end

    it 'has an amount equal to the PI value' do
      subject
      expect(json['amount']).to eq(late_fee_item.value)
    end

    it 'puts the logged-in user as created_by' do
      subject
      expect(json['createdBy']).to eq(requesting_user.email)
    end

    it 'links the new waiver with the bowler' do
      expect { subject }.to change(bowler.waivers, :count).by(1)
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

    context 'error scenarios' do
      context 'an unrecognized bowler identifier' do
        let(:bowler_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'a tournament with no late fee to waive' do
        let(:tournament) { create :tournament, :with_entry_fee }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete uri, headers: auth_headers, as: :json }

    let(:uri) { "/director/waivers/#{waiver_identifier}" }

    let(:waiver) do
      create :waiver,
        amount: late_fee_item.value,
        bowler: bowler,
        purchasable_item: late_fee_item
    end
    let(:waiver_identifier) { waiver.identifier }

    include_examples 'an authorized action'

    it 'succeeds with a 204 No Content' do
      subject
      expect(response).to have_http_status(:no_content)
    end

    it 'removes the waiver' do
      subject
      expect(Waiver.find_by_identifier(waiver_identifier)).to be_nil
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
      context 'an unrecognized waiver identifier' do
        let(:waiver_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
