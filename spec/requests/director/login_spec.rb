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

    it "includes the user's identifier in the payload" do
      token = HttpAuth.jwt_from_auth_header(response.headers['Authorization'])

      expect(token).to have_key(:identifier)
    end

    it "includes a role attribute in the token's payload" do
      token = HttpAuth.jwt_from_auth_header(response.headers['Authorization'])

      expect(token).to have_key(:role)
    end

    it 'has a role of "director"' do
      token = HttpAuth.jwt_from_auth_header(response.headers['Authorization'])

      expect(token[:role]).to eq('director')
    end

    it 'includes a tournaments attribute in the token payload' do
      token = HttpAuth.jwt_from_auth_header(response.headers['Authorization'])

      expect(token).to have_key(:tournament_org_ids)
    end

    it 'has an empty array for the tournament_orgs attribute' do
      token = HttpAuth.jwt_from_auth_header(response.headers['Authorization'])

      expect(token[:tournament_org_ids]).to eq([])
    end

    context 'and the user is a superuser' do
      let(:user) { create(:user, :superuser) }

      it 'includes the superuser role in the returned token' do
        token = HttpAuth.jwt_from_auth_header(response.headers['Authorization'])

        expect(token[:role]).to eq('superuser')
      end
    end

    context 'and the user is a director of a tournament' do
      let(:org) { create(:tournament_org) }
      let(:user) { create(:user, :director, tournament_orgs: [org]) }

      it 'includes the director role in the returned token' do
        token = HttpAuth.jwt_from_auth_header(response.headers['Authorization'])

        expect(token[:role]).to eq('director')
      end

      it 'includes a non-empty tournaments array' do
        token = HttpAuth.jwt_from_auth_header(response.headers['Authorization'])

        expect(token[:tournament_org_ids].length).to eq(1)
      end

      it 'includes the correct tournament org identifier in the array' do
        token = HttpAuth.jwt_from_auth_header(response.headers['Authorization'])

        expect(token[:tournament_org_ids][0]).to eq(org.id)
      end
    end
  end

  context 'when password is missing' do
    before do
      post login_url, params: {
        user: {
          email: user.email,
          password: nil,
        },
        as: :json
      }
    end

    it 'returns a 401' do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when logging out' do
    let (:auth_headers) { Devise::JWT::TestHelpers.auth_headers({}, user) }

    subject { delete "/logout", headers: auth_headers }

    it 'returns a 204' do
      subject
      expect(response).to have_http_status(:no_content)
    end
  end
end
