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

    it "includes a role attribute in the token's payload" do
      header = response.headers['Authorization']
      token_part = header.split(' ').last
      hashed_token = JsonWebToken.decode(token_part)

      expect(hashed_token).to have_key(:role)
    end

    it 'has a role of "unpermitted"' do
      header = response.headers['Authorization']
      token_part = header.split(' ').last
      hashed_token = JsonWebToken.decode(token_part)

      expect(hashed_token[:role]).to eq('unpermitted')
    end

    context 'and the user is a superuser' do
      let(:user) { create(:user, :superuser) }

      it 'includes the superuser role in the returned token' do
        header = response.headers['Authorization']
        token_part = header.split(' ').last
        hashed_token = JsonWebToken.decode(token_part)

        expect(hashed_token[:role]).to eq('superuser')
      end
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
