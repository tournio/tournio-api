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

  describe '#create' do
    subject { post uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/tournaments/#{tournament_identifier}/purchasable_items" }

    let(:tournament) { create :tournament }
    let(:tournament_identifier) { tournament.identifier }

    let(:params) do
      {
        purchasable_item: new_item_params,
      }
    end
    let(:new_item_params) do
      {
        category: category,
        determination: determination,
        name: 'A new purchasable item',
        value: 27,
        refinement: refinement,
        configuration: configuration_param,
      }
    end
    let(:category) { 'bowling' }
    let(:determination) { 'single_use' }
    let(:refinement) { '' }
    let(:configuration_param) do
      {
        order: 3,
        note: '',
      }
    end

    ###############

    include_examples 'an authorized action'

    it 'succeeds with a 201 Created' do
      subject
      expect(response).to have_http_status(:created)
    end

    it 'includes the new item in the response' do
      subject
      expect(json).to have_key('identifier')
    end

    context 'a ledger item' do
      let(:category) { 'ledger' }

      context 'entry fee' do
        let(:determination) { 'entry_fee' }
        let(:configuration_param) do
          {
            order: '',
            note: '',
          }
        end

        it 'succeeds with a 201 Created' do
          subject
          expect(response).to have_http_status(:created)
        end

        context 'when an entry fee already exists' do
          before { create :purchasable_item, :entry_fee, tournament: tournament }

          it 'fails with a Conflict' do
            subject
            expect(response).to have_http_status(:conflict)
          end
        end
      end

      context 'late registration fee' do
        let(:determination) { 'late_fee' }
        let(:configuration_param) do
          {
            applies_at: (Time.zone.now + 3.months).strftime("%FT%T%:z"),
            order: '',
            note: '',
          }
        end

        it 'succeeds with a 201 Created' do
          subject
          expect(response).to have_http_status(:created)
        end

        context 'without providing an applies_at timestamp' do
          let(:configuration_param) do
            {
              applies_at: '',
              order: '',
              note: '',
            }
          end

          it 'fails with unprocessable entity' do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'when a late fee already exists' do
          before { create :purchasable_item, :late_fee, tournament: tournament }

          it 'fails with a Conflict' do
            subject
            expect(response).to have_http_status(:conflict)
          end
        end
      end

      context 'early registration discount' do
        let(:determination) { 'early_discount' }
        let(:configuration_param) do
          {
            valid_until: (Time.zone.now + 3.months).strftime("%FT%T%:z"),
            order: '',
            note: '',
          }
        end

        it 'succeeds with a 201 Created' do
          subject
          expect(response).to have_http_status(:created)
        end

        context 'without providing a valid_until timestamp' do
          let(:configuration_param) do
            {
              valid_until: '',
              order: '',
              note: '',
            }
          end

          it 'fails with unprocessable entity' do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'when a discount already exists' do
          before { create :purchasable_item, :early_discount, tournament: tournament }

          it 'fails with a Conflict' do
            subject
            expect(response).to have_http_status(:conflict)
          end
        end
      end
    end

    context 'a banquet item' do
      let(:category) { 'banquet' }
      let(:determination) { 'multi_use' }
      let(:configuration_param) do
        {
          order: 1,
          note: '',
        }
      end

      it 'succeeds with a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end
    end

    context 'a product item with denomination refinement' do
      let(:category) { 'product' }
      let(:determination) { 'multi_use' }
      let(:refinement) { 'denomination' }
      let(:configuration_param) do
        {
          order: 2,
          note: 'Available for pre-purchase only',
          denomination: '237 of the thing',
        }
      end

      it 'succeeds with a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end

      context 'without providing a denomination' do
        let(:configuration_param) do
          {
            order: 3,
            note: 'A special item',
            denomination: '',
          }
        end

        it 'fails with unprocessable entity' do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'an active tournament' do
      let(:tournament) { create :tournament, :active }

      it 'is forbidden' do
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
          expect(response).to have_http_status(:created)
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
