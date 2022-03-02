require 'rails_helper'

describe FreeEntriesController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe '#create' do
    subject { post uri, params: params, as: :json }

    let(:uri) { "/tournaments/#{tournament_identifier}/free_entries" }

    let(:tournament) { create :tournament, :active, :with_entry_fee }
    let(:tournament_identifier) { tournament.identifier}
    let(:bowler) { create :bowler, tournament: tournament }
    let(:bowler_identifier) { bowler.identifier }
    let(:unique_code) { 'congrats-you-win-789' }

    let(:params) do
      {
        unique_code: unique_code,
        bowler_identifier: bowler_identifier,
      }
    end

    context 'first time we see the code' do
      it 'creates a free entry' do
        expect { subject }.to change(FreeEntry, :count).by(1)
      end

      it 'renders a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'puts the unique code on the entry' do
        subject
        free_entry = FreeEntry.last
        expect(free_entry.unique_code).to eq(unique_code.upcase)
      end

      it 'links it with the bowler' do
        subject
        free_entry = FreeEntry.last
        expect(free_entry.bowler_id).to eq(bowler.id)
      end

      it 'includes a message in the response' do
        subject
        expect(json).to have_key("message")
      end

      it 'includes the free entry code in the response' do
        subject
        expect(json).to have_key("unique_code")
      end

      it 'contains the code, upper-cased' do
        subject
        expect(json['unique_code']).to eq(unique_code.upcase)
      end
    end

    context 'director already created the code' do
      before { create :free_entry, tournament: tournament, unique_code: unique_code.upcase }

      it 'does not create a new free entry' do
        expect { subject }.not_to change(FreeEntry, :count)
      end

      it 'renders a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'links it with the bowler' do
        subject
        free_entry = FreeEntry.find_by(unique_code: unique_code.upcase, tournament: tournament)
        expect(free_entry.bowler_id).to eq(bowler.id)
      end

      it 'contains a message in the response' do
        subject
        expect(json).to have_key("message")
      end
    end

    context 'error conditions' do
      context 'an unknown tournament identifier' do
        let(:tournament_identifier) { 'gobbledegook' }

        it 'renders a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'an unknown bowler identifier' do
        let(:bowler_identifier) { 'gobbledegook' }

        it 'renders a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'a free entry already associated with a bowler' do
        let!(:other_bowler) { create(:bowler, tournament: tournament) }

        before { create :free_entry, tournament: tournament, unique_code: unique_code.upcase, bowler: other_bowler }

        it 'does not create a new free entry' do
          expect { subject }.not_to change(FreeEntry, :count)
        end

        it 'renders a 409 Conflict' do
          subject
          expect(response).to have_http_status(:conflict)
        end

        it 'does not link it with the bowler' do
          subject
          free_entry = FreeEntry.find_by(unique_code: unique_code.upcase, tournament: tournament)
          expect(free_entry.bowler_id).to eq(other_bowler.id)
        end

        it 'contains an error message in the response' do
          subject
          expect(json).to have_key("error")
        end
      end

      context 'bowler already has a free entry associated' do
        before { create :free_entry, tournament: tournament, bowler: bowler }

        it 'does not create a new free entry' do
          expect { subject }.not_to change(FreeEntry, :count)
        end

        it 'renders a 409 Conflict' do
          subject
          expect(response).to have_http_status(:conflict)
        end

        it 'does not link the supplied code with the bowler' do
          subject
          expect(bowler.free_entry.unique_code).not_to eq(unique_code.upcase)
        end

        it 'contains an error message in the response' do
          subject
          expect(json).to have_key("error")
        end
      end
    end
  end
end
