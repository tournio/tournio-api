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

    context 'when there is just the requesting superuser' do
      let(:requesting_user) { create :user, :superuser }

      it 'includes one row' do
        subject
        expect(json.count).to eq(1)
      end

      it 'indicates the superuser role' do
        subject
        expect(json[0]['role']).to eq('superuser')
      end
    end

    context 'when there is a superuser and a tournament org user' do
      let(:requesting_user) { create :user, :superuser }

      before do
        create :user_with_orgs
      end

      it 'includes two rows' do
        subject
        expect(json.count).to eq(2)
      end

      it 'includes an orgs attribute for each' do
        subject
        expect(json[0]).to have_key('tournamentOrgs')
        expect(json[1]).to have_key('tournamentOrgs')
      end

      it 'includes the org for the director' do
        subject
        user = json.filter { |row| row['tournamentOrgs'].present? }.first
        expect(user['tournamentOrgs'][0]['name']).to eq(TournamentOrg.last.name)
      end
    end
  end

  describe '#create' do
    subject { post '/director/users', params: params, headers: auth_headers, as: :json }

    let(:requesting_user) { create(:user, :superuser) }
    let(:email) { 'a_new_user@tournament.org' }
    let(:role) { 'director' }
    let(:first_name) { 'Kylie' }
    let(:last_name) { 'Minogue' }
    let(:tournament) { create(:tournament) }
    let(:params) do
      {
        user: {
          email: email,
          role: role,
          first_name: first_name,
          last_name: last_name,
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

    it 'associates the new user with the desired tournaments' do
      subject
      expect(json).to have_key('tournaments')
      expect(json['tournaments'].length).to eq(1)
      expect(json['tournaments'].first['identifier']).to eq(tournament.identifier)
    end
  end

  describe '#update' do
    subject { patch "/director/users/#{desired_user_identifier}", params: params, headers: auth_headers, as: :json }

    let(:requesting_user) { create(:user) }
    let(:new_email) { 'a_new_address@tournament.org' }
    let(:params) do
      {
        user: {
          email: new_email,
          password: 'new password',
        }
      }
    end

    context "When a user wants to update their own details" do
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

      it 'reflects the updated details' do
        subject
        expect(json['email']).to eq(new_email)
      end

      context 'attempting to update something they are not permitted to' do
        let(:params) do
          {
            user: {
              role: 'superuser',
            }
          }
        end

        it 'rejects the request' do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "When they want to update someone else's details" do
      let(:requesting_user) { create(:user, :superuser) }
      let(:requested_user) { create(:user) }
      let(:desired_user_identifier) { requested_user.identifier }
      let(:tournament) { create :tournament }

      include_examples 'for superusers only', :ok

      context 'attempting to update something other than email/password' do
        let(:params) do
          {
            user: {
              role: 'director',
              first_name: 'Robyn',
              tournament_ids: [tournament.id],
            }
          }
        end

        it 'allows the update to proceed' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'reflects the updated details' do
          subject
          expect(json['email']).to eq(requested_user.email)
          expect(json['role']).to eq('director')
          expect(json['tournaments']).to be_instance_of(Array)
          expect(json['tournaments'][0]['identifier']).to eq(tournament.identifier)
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

  describe '#destroy' do
    subject { delete "/director/users/#{desired_user_identifier}", headers: auth_headers, as: :json }

    let(:requesting_user) { create(:user, :superuser) }
    let(:requested_user) { create(:user) }
    let(:desired_user_identifier) { requested_user.identifier }

    include_examples 'an authorized action'
    include_examples 'for superusers only', :no_content

    context 'attempting to delete self' do
      let(:desired_user_identifier) { requesting_user.identifier }

      it 'rejects the request' do
        subject
        expect(response).to have_http_status(:method_not_allowed)
      end
    end
  end
end
