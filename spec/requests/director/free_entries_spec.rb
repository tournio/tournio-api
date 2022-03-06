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

  describe '#confirm' do
    subject { post uri, headers: auth_headers, as: :json }

    let(:uri) { "/director/free_entries/#{free_entry_id}/confirm" }

    let(:tournament) { create :tournament, :active }
    let(:free_entry) { create :free_entry, tournament: tournament, bowler: (create :bowler, tournament: tournament) }
    let(:free_entry_id) { free_entry.id }

    include_examples 'an authorized action'

    it 'succeeds with a 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
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
      context 'an unrecognized id' do
        let(:free_entry_id) { 99999 }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'an already-confirmed free entry' do
        let(:free_entry) { create :free_entry, tournament: tournament, confirmed: true }

        it 'yields a 409 Conflict' do
          subject
          expect(response).to have_http_status(:conflict)
        end
      end

      context 'a free entry without a bowler associated' do
        let(:free_entry) { create :free_entry, tournament: tournament }

        it 'yields a 409 Conflict' do
          subject
          expect(response).to have_http_status(:conflict)
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete uri, headers: auth_headers, as: :json }

    let(:uri) { "/director/free_entries/#{free_entry_id}" }

    let(:tournament) { create :tournament, :active }
    let(:free_entry) { create :free_entry, tournament: tournament }
    let(:free_entry_id) { free_entry.id }

    include_examples 'an authorized action'

    it 'succeeds with a 204 No Content' do
      subject
      expect(response).to have_http_status(:no_content)
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
          expect(response).to have_http_status(:no_content)
        end
      end
    end

    context 'error scenarios' do
      context 'an unrecognized id' do
        let(:free_entry_id) { 99999 }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'a confirmed free entry' do
        let(:free_entry) { create :free_entry, tournament: tournament, confirmed: true }

        it 'yields a 409 Conflict' do
          subject
          expect(response).to have_http_status(:conflict)
        end
      end
    end
  end
end

