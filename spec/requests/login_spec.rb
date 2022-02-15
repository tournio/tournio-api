require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Users::SessionsController, type: :request do
  let(:user) { create(:user) }
  let(:login_url) { '/login' }
  let(:logout_url) { '/logout' }

  context 'when logging in' do
    before do
      login_with_api(user)
    end

    it 'returns a token' do
      expect(response.headers['Authorization']).to be_present
    end

    it 'returns a 200 OK status' do
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when password is missing' do
    before do
      post login_url, params: {
        user: {
          email: user.email,
          password: nil,
        }
      }
    end

    it 'returns a 401' do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when logging out' do
    before do
      headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }
      auth_headers = Devise::JWT::TestHelpers.auth_headers(headers, user)
      delete "/logout", headers: auth_headers
    end

    it 'returns a 204' do
      expect(response).to have_http_status(:no_content)
    end
  end
end
