require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::PurchasableItemsController, type: :request do
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

    let(:uri) { "/director/purchasable_items/#{purchasable_item_id}" }

    let(:tournament_identifier) { tournament.identifier }
    let(:tournament) { create :tournament }
    let(:purchasable_item) { create :purchasable_item, :entry_fee, tournament: tournament }
    let(:purchasable_item_id) { purchasable_item.identifier }

    let(:configuration_param) do
      {
        order: '',
        applies_at: '',
        valid_until: '',
        division: '',
        note: '',
        denomination: '',
      }
    end
    let(:params) do
      {
        purchasable_item: {
          value: 99,
          configuration: configuration_param,
        }
      }
    end

    include_examples 'an authorized action'

    it 'succeeds with a 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    context 'early discount' do
      let(:purchasable_item) { create :purchasable_item, :early_discount, tournament: tournament }
      let(:configuration_param) do
        {
          order: '',
          applies_at: '',
          valid_until: (Time.zone.now + 2.weeks).strftime("%FT%T%:z"),
          division: '',
          note: '',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'late fee' do
      let(:purchasable_item) { create :purchasable_item, :late_fee, tournament: tournament }
      let(:configuration_param) do
        {
          order: '',
          applies_at: (Time.zone.now + 6.weeks).strftime("%FT%T%:z"),
          valid_until: '',
          division: '',
          note: '',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'a bowling event' do
      let(:purchasable_item) { create :purchasable_item, :optional_event, tournament: tournament }
      let(:configuration_param) do
        {
          order: 5,
          applies_at: '',
          valid_until: '',
          division: '',
          note: '',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'a division-based bowling event' do
      let(:purchasable_item) { create :purchasable_item, :scratch_competition, tournament: tournament }
      let(:configuration_param) do
        {
          order: '',
          applies_at: '',
          valid_until: '',
          division: 'B',
          note: '170-189',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'a banquet entry' do
      let(:purchasable_item) { create :purchasable_item, :banquet_entry, tournament: tournament }
      let(:configuration_param) do
        {
          order: '',
          applies_at: '',
          valid_until: '',
          division: '',
          note: '',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'a raffle ticket bundle' do
      let(:purchasable_item) { create :purchasable_item, :raffle_bundle, tournament: tournament }
      let(:configuration_param) do
        {
          order: 3,
          applies_at: '',
          valid_until: '',
          division: '',
          note: 'Nice.',
          denomination: '69 tickets',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'an active tournament' do
      let(:tournament) { create :tournament, :active }

      it 'prevents updates' do
        subject
        expect(response).to have_http_status(:forbidden)
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
        let(:requesting_user) { create :user, :director, tournaments: [tournament] }

        it 'shall pass' do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'error scenarios' do
      context 'an unrecognized purchasable item id' do
        let(:purchasable_item_id) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

end
