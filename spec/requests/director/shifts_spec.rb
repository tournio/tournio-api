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

  describe '#update' do
    subject { patch uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/shifts/#{shift_id}" }

    let(:tournament_identifier) { tournament.identifier }
    let(:tournament) { create :tournament }
    let(:shift) { create :shift,  tournament: tournament }
    let(:shift_id) { shift.identifier }

    let(:params) do
      {
        shift: shift_params,
      }
    end
    let(:shift_params) do
      {
        capacity: 32,
        display_order: 2,
      }
    end

    include_examples 'an authorized action'

    it 'succeeds with a 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'returns the same shift' do
      subject
      expect(json['name']).to eq(shift.name)
    end

    it 'reflects the desired changes' do
      subject
      expect(json['capacity']).to eq(32)
      expect(json['display_order']).to eq(2)
    end

    context 'trying to change a calculated attribute' do
      let(:shift_params) do
        {
          capacity: 32,
          confirmed: 10,
          requested: 17,
        }
      end

      it 'raises if we try to change calculated attributes' do
        initial_confirmed = shift.confirmed
        initial_requested = shift.requested
        subject
        expect(response).to have_http_status(:conflict)
      end
    end

    context 'trying to make capacity < confirmed' do
      let(:shift) { create :shift, :full, tournament: tournament }

      it 'rejects it with Conflict' do
        subject
        expect(response).to have_http_status(:conflict)
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
      context 'an unrecognized shift id' do
        let(:shift_id) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete uri, headers: auth_headers, as: :json }

    let(:uri) { "/director/shifts/#{identifier}" }

    let(:tournament) { create :tournament }
    let(:shift) { create :shift, tournament: tournament }
    let(:identifier) { shift.identifier }

    include_examples 'an authorized action'

    context 'an unrecognized shift identifier' do
      let(:identifier) { 'i-dont-know-her' }

      it 'responds with a Not Found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'Tournament modes' do
      context 'Setup' do
        it 'responds with No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'destroys the shift' do
          subject
          begin
            shift.reload
          rescue => exception
          ensure
            expect(exception).to be_instance_of ActiveRecord::RecordNotFound
          end
        end
      end

      context 'Testing' do
        let(:tournament) { create :tournament, :testing }

        it 'responds with No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'destroys the shift' do
          subject
          begin
            shift.reload
          rescue => exception
          ensure
            expect(exception).to be_instance_of ActiveRecord::RecordNotFound
          end
        end
      end

      context 'Active' do
        let(:tournament) { create :tournament, :active }

        it 'responds with Forbidden' do
          subject
          expect(response).to have_http_status(:forbidden)
        end

        it 'does not destroy the shift' do
          subject
          expect(shift.reload).not_to be_nil
        end
      end

      context 'Closed' do
        let(:tournament) { create :tournament, :closed }

        it 'responds with No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'destroys the shift' do
          subject
          begin
            shift.reload
          rescue => exception
          ensure
            expect(exception).to be_instance_of ActiveRecord::RecordNotFound
          end
        end
      end
    end
  end
end
