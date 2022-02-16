require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::UsersController, type: :request do
  let(:requesting_user) { create(:user) }
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers({}, requesting_user) }

  describe '#show' do
    subject { get "/director/users/#{desired_user_identifier}", headers: auth_headers }

    context "When a user wants to fetch their own details" do
      let(:desired_user_identifier) { requesting_user.identifier }

      include_examples 'an authorized action'

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
        expect(json['identifier']).to eq(requesting_user.identifier)
      end
    end

    context "When they want to fetch someone else's details" do
      let(:requested_user) { create(:user) }
      let(:desired_user_identifier) { requested_user.identifier }

      include_examples 'for superusers only', :ok
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

    include_examples 'an authorized action'
    include_examples 'for superusers only', :ok
  end

  describe '#create' do
    subject { post '/director/users', params: params, headers: auth_headers, as: :json }

    let(:requesting_user) { create(:user, :superuser) }
    let(:email) { 'a_new_user@tournament.org' }
    let(:role) { 'director' }
    let(:tournament) { create(:tournament) }
    let(:params) do
      {
        user: {
          email: email,
          role: role,
          tournament_ids: [tournament.id],
        }
      }
    end

    include_examples 'an authorized action'
    include_examples 'for superusers only', :created

    it 'includes the new user in the response' do
      subject
      expect(json).to have_key('identifier')
      expect(json['email']).to eq(email)
      expect(json['role']).to eq(role)
    end
  end
end
