# frozen_string_literal: true

require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::TournamentOrgsController, type: :request do
  let(:requesting_user) { create(:user, :superuser) }
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, requesting_user) }

  describe '#index' do
    subject { get uri, headers: auth_headers }

    let(:uri) { '/director/tournament_orgs' }

    before do
      create :tournament_org, name: 'Org 1'
      create :tournament_org, name: 'Org 2'
      create :tournament_org, name: 'Org 3'
      create :tournament_org, name: 'Org 4'
    end

    include_examples 'an authorized action'

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'includes all tournament orgs in the response' do
      subject
      expect(json.length).to eq(4);
    end

    it 'includes the tournament org identifier in each one' do
      subject
      expect(json[0]).to have_key('identifier')
    end

    it 'includes the tournament org name in each one' do
      subject
      expect(json[0]).to have_key('name')
    end

    it 'includes the serialized user accounts of each one' do
      subject
      expect(json[0]).to have_key('users')
    end

    it 'includes the stripe account details in each one' do
      subject
      expect(json[0]).to have_key('stripeAccount')
    end
  end

  describe '#show' do
    subject { get uri, headers: auth_headers }

    let(:uri) { "/director/tournament_orgs/#{org.identifier}" }

    let(:org) { create :tournament_org }

    include_examples 'an authorized action'

    it 'returns a JSON representation of the org' do
      subject
      expect(json['identifier']).to eq(org.identifier)
    end

    context 'When I am an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

  end
end
