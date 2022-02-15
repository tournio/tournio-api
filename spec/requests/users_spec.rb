require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::UsersController, type: :request do
  let(:user) { create(:user) }

  context "When a user wants to fetch their own details" do
    before do
      headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }
      auth_headers = Devise::JWT::TestHelpers.auth_headers(headers, user)
      get "/director/users/#{user.identifier}", headers: auth_headers
    end

    it 'returns a 200 OK' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns a JSON representation of the user' do
      expect(json).to have_key('identifier')
      expect(json).to have_key('email')
    end
  end

  context 'When the requested user does not exist' do
    before do
      login_with_api(user)

      get "/director/users/missing-user-identifier", headers: {
        'Authorization': response.headers['Authorization']
      }
    end

    it 'returns a 404' do
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'When the Authorization header is missing' do
    before do
      get "/director/users/#{user.identifier}"
    end

    it 'returns a 401 Unauthorized' do
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
