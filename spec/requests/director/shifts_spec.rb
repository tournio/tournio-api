require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::ShiftsController, type: :request do
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

    let(:uri) { "/director/tournaments/#{tournament_identifier}/shifts" }

    let(:tournament) { create :tournament }
    let(:tournament_identifier) { tournament.identifier }

    let(:params) do
      {
        shift: new_shift_params,
      }
    end
    let(:new_shift_params) do
      {
        capacity: 32,
        name: 'Early',
        description: 'Singles on Friday 5-9pm, Doubles/Team on Saturday 9am-3pm',
        display_order: 1,
      }
    end

    ###############

    include_examples 'an authorized action'

    it 'succeeds with a 201 Created' do
      subject
      expect(response).to have_http_status(:created)
    end

    it 'returns the created shift' do
      subject
      expect(json).to have_key('identifier')
      expect(json['capacity']).to eq(32)
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

  # describe '#update' do
  #   subject { patch uri, headers: auth_headers, params: params, as: :json }
  #
  #   let(:uri) { "/director/purchasable_items/#{purchasable_item_id}" }
  #
  #   let(:tournament_identifier) { tournament.identifier }
  #   let(:tournament) { create :tournament }
  #   let(:purchasable_item) { create :purchasable_item, :entry_fee, tournament: tournament }
  #   let(:purchasable_item_id) { purchasable_item.identifier }
  #
  #   let(:configuration_param) do
  #     {
  #       order: '',
  #       applies_at: '',
  #       valid_until: '',
  #       division: '',
  #       note: '',
  #       denomination: '',
  #     }
  #   end
  #   let(:params) do
  #     {
  #       purchasable_item: {
  #         value: 99,
  #         configuration: configuration_param,
  #       }
  #     }
  #   end
  #
  #   include_examples 'an authorized action'
  #
  #   it 'succeeds with a 200 OK' do
  #     subject
  #     expect(response).to have_http_status(:ok)
  #   end
  #
  #   context 'an active tournament' do
  #     let(:tournament) { create :tournament, :active }
  #
  #     it 'prevents updates' do
  #       subject
  #       expect(response).to have_http_status(:forbidden)
  #     end
  #   end
  #
  #   context 'as an unpermitted user' do
  #     let(:requesting_user) { create(:user, :unpermitted) }
  #
  #     it 'shall not pass' do
  #       subject
  #       expect(response).to have_http_status(:unauthorized)
  #     end
  #   end
  #
  #   context 'as a director' do
  #     let(:requesting_user) { create(:user, :director) }
  #
  #     it 'shall not pass' do
  #       subject
  #       expect(response).to have_http_status(:unauthorized)
  #     end
  #
  #     context 'associated with this tournament' do
  #       let(:requesting_user) { create :user, :director, tournaments: [tournament] }
  #
  #       it 'shall pass' do
  #         subject
  #         expect(response).to have_http_status(:ok)
  #       end
  #     end
  #   end
  #
  #   context 'error scenarios' do
  #     context 'an unrecognized purchasable item id' do
  #       let(:purchasable_item_id) { 'say-what-now' }
  #
  #       it 'yields a 404 Not Found' do
  #         subject
  #         expect(response).to have_http_status(:not_found)
  #       end
  #     end
  #   end
  # end
  #
  # describe '#destroy' do
  #   subject { delete uri, headers: auth_headers, as: :json }
  #
  #   let(:uri) { "/director/purchasable_items/#{purchasable_item_id}" }
  #
  #   let(:tournament) { create :tournament }
  #   let(:tournament_identifier) { tournament.identifier }
  #   let(:purchasable_item) { create :purchasable_item, :entry_fee, tournament: tournament }
  #   let(:purchasable_item_id) { purchasable_item.identifier }
  #
  #   include_examples 'an authorized action'
  #
  #   context 'an unrecognized item identifier' do
  #     let(:purchasable_item_id) { 'i-dont-know-her' }
  #
  #     it 'responds with a Not Found' do
  #       subject
  #       expect(response).to have_http_status(:not_found)
  #     end
  #   end
  #
  #   context 'Tournament modes' do
  #     context 'Setup' do
  #       it 'responds with No Content' do
  #         subject
  #         expect(response).to have_http_status(:no_content)
  #       end
  #
  #       it 'destroys the item' do
  #         subject
  #         begin
  #           purchasable_item.reload
  #         rescue => exception
  #         ensure
  #           expect(exception).to be_instance_of ActiveRecord::RecordNotFound
  #         end
  #       end
  #     end
  #
  #     context 'Testing' do
  #       let(:tournament) { create :tournament, :testing }
  #
  #       it 'responds with No Content' do
  #         subject
  #         expect(response).to have_http_status(:no_content)
  #       end
  #
  #       it 'destroys the item' do
  #         subject
  #         begin
  #           purchasable_item.reload
  #         rescue => exception
  #         ensure
  #           expect(exception).to be_instance_of ActiveRecord::RecordNotFound
  #         end
  #       end
  #     end
  #
  #     context 'Active' do
  #       let(:tournament) { create :tournament, :active }
  #
  #       it 'responds with Forbidden' do
  #         subject
  #         expect(response).to have_http_status(:forbidden)
  #       end
  #
  #       it 'does not destroy the item' do
  #         subject
  #         expect(purchasable_item.reload).not_to be_nil
  #       end
  #     end
  #
  #     context 'Closed' do
  #       let(:tournament) { create :tournament, :closed }
  #
  #       it 'responds with No Content' do
  #         subject
  #         expect(response).to have_http_status(:no_content)
  #       end
  #
  #       it 'destroys the item' do
  #         subject
  #         begin
  #           purchasable_item.reload
  #         rescue => exception
  #         ensure
  #           expect(exception).to be_instance_of ActiveRecord::RecordNotFound
  #         end
  #       end
  #     end
  #   end
  # end
end
