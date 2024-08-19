require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::LedgerEntriesController, type: :request do
  let(:requesting_user) { create(:user, :superuser) }
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, requesting_user) }

  describe '#create' do
    subject { post uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/bowlers/#{bowler_identifier}/ledger_entries" }

    let(:tournament) { create :tournament, :with_entry_fee }
    let(:bowler) { create :bowler, tournament: tournament }
    let(:bowler_identifier) { bowler.identifier }
    let(:entry_fee_pi) { tournament.purchasable_items.entry_fee.first }

    let(:params) do
      {
        ledger_entry: new_entry_params,
      }
    end

    let(:new_entry_params) do
      {
        credit: entry_fee_pi.value,
        identifier: 'cash payment',
      }
    end

    ###############

    include_examples 'an authorized action'

    it 'succeeds with a 201 Created' do
      subject
      expect(response).to have_http_status(:created)
    end

    it 'returns the created item' do
      subject
      expect(json).to have_key('source')
    end

    it 'creates a ledger entry' do
      expect { subject }.to change(LedgerEntry, :count).by(1)
    end

    it 'writes "manual" as the source' do
      subject
      expect(LedgerEntry.last.manual?).to be_truthy
    end

    it "writes the requesting user's email in the notes" do
      subject
      expect(LedgerEntry.last.notes).to include(requesting_user.email)
    end

    it "adds it to the bowler's list of entries" do
      expect { subject }.to change(bowler.ledger_entries, :count).by(1)
    end

    it "creates an Entry Fee purchase" do
      expect { subject }.to change(Purchase, :count).by(1)
    end

    it "links the new purchase with the bowler" do
      expect { subject }.to change(bowler.purchases, :count).by(1)
    end

    context 'when it covers a late-registration fee, too' do
      let(:tournament) { create :tournament, :with_entry_fee, :with_late_fee }
      let(:late_fee_pi) { tournament.purchasable_items.late_fee.first }

      let(:new_entry_params) do
        {
          credit: entry_fee_pi.value + late_fee_pi.value,
          identifier: 'cash payment',
        }
      end

      it "creates a Late Fee purchase as well" do
        expect { subject }.to change(Purchase, :count).by(2)
      end

      it "links the new purchases with the bowler" do
        expect { subject }.to change(bowler.purchases, :count).by(2)
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

    context 'error scenarios' do
      context 'an unrecognized bowler identifier' do
        let(:bowler_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

end
