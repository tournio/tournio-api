require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::FreeEntriesController, type: :request do
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

    let(:uri) { "/director/tournaments/#{tournament_identifier}/free_entries" }

    let(:tournament_identifier) { tournament.identifier }
    let(:tournament) { create :tournament, :active }

    before do
      10.times do
        create :free_entry, tournament: tournament
      end
    end

    include_examples 'an authorized action'

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'includes all free entries in the response' do
      subject
      expect(json.length).to eq(10);
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
      context 'an unrecognized tournament identifier' do
        let(:tournament_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#create' do
    subject { post uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/tournaments/#{tournament_identifier}/free_entries" }

    let(:tournament_identifier) { tournament.identifier }
    let(:tournament) { create :tournament, :active }

    let(:params) do
      {
        free_entry: {
          unique_code: 'I-BOWL-4-FREE',
        }
      }
    end

    include_examples 'an authorized action'

    it 'succeeds with a 201 Created' do
      subject
      expect(response).to have_http_status(:created)
    end

    it 'includes the new free entry in the response' do
      subject
      expect(json).to have_key('unique_code')
      expect(json['unique_code']).to eq('I-BOWL-4-FREE');
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

  # describe '#show' do
  #   subject { get uri, headers: auth_headers }
  #
  #   let(:uri) { "/director/tournaments/#{tournament.identifier}" }
  #
  #   let(:tournament) { create :tournament }
  #
  #   include_examples 'an authorized action'
  #
  #   it 'returns a JSON representation of the tournament' do
  #     subject
  #     expect(json['identifier']).to eq(tournament.identifier);
  #   end
  #
  #   context 'When I am an unpermitted user' do
  #     let(:requesting_user) { create(:user, :unpermitted) }
  #
  #     it 'yields a 401 Unauthorized' do
  #       subject
  #       expect(response).to have_http_status(:unauthorized)
  #     end
  #   end
  #
  #   context 'When I am a tournament director' do
  #     let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
  #     let(:my_tournaments) { [] }
  #
  #     it 'yields a 401 Unauthorized' do
  #       subject
  #       expect(response).to have_http_status(:unauthorized)
  #     end
  #
  #     context 'for this tournament' do
  #       let(:my_tournaments) { [tournament] }
  #
  #       it 'yields a 200 OK' do
  #         subject
  #         expect(response).to have_http_status(:ok)
  #       end
  #
  #       it 'returns a JSON representation of the tournament' do
  #         subject
  #         expect(json['identifier']).to eq(tournament.identifier);
  #       end
  #     end
  #   end
  # end

end

