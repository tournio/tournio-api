require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::UsersController, type: :request do
  let(:user) { create(:user) }
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, user) }

  describe '#show' do
    let(:desired_user_identifier) { user.identifier }

    subject { get "/director/users/#{desired_user_identifier}", headers: auth_headers }

    context 'When the Authorization header is missing' do
      let(:auth_headers) { headers }

      it 'returns a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "When a user wants to fetch their own details" do
      it 'returns a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'returns a JSON representation of the user' do
        subject
        expect(json).to have_key('identifier')
        expect(json).to have_key('email')
      end

      it 'returns the intended user' do
        subject
        expect(json['identifier']).to eq(user.identifier)
      end
    end

    context "When they want to fetch someone else's details" do
      let(:requesting_user) { create(:user, :director) }
      let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, requesting_user) }

      it 'returns a 404 not found, even for a director' do
        subject
        expect(response).to have_http_status(:not_found)
      end

      context "As a superuser" do
        let(:requesting_user) { create(:user, :superuser) }

        it 'returns a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'When the requested user does not exist' do
      let(:desired_user_identifier) { 'missing-user-identifier' }

      it 'returns a 404' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe '#index' do
    subject { get "/director/users", headers: auth_headers }

    context 'When the Authorization header is missing' do
      let(:auth_headers) { headers }

      it 'returns a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "As a superuser" do
      let(:user) { create(:user, :superuser) }

      it 'returns a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context "As a director" do
      let(:user) { create(:user, :director) }

      it 'returns a 404 not found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end

    context "As an unpermitted user" do
      it 'returns a 404 not found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
