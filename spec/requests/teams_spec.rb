require 'rails_helper'

describe TeamsController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe '#create' do
    subject { post uri, params: new_team_params, as: :json }

    let(:uri) { "/tournaments/#{tournament.identifier}/teams" }
    let(:tournament) { create :tournament, :active, :with_entry_fee }

    before do
      comment = create(:extended_form_field, :comment)
      pronouns = create(:extended_form_field, :pronouns)
      standings = create(:extended_form_field, :standings_link)

      create(:additional_question, extended_form_field: comment, tournament: tournament)
      create(:additional_question, extended_form_field: pronouns, tournament: tournament)
      create(:additional_question, extended_form_field: standings, tournament: tournament)
    end

    context 'with a full team' do
      let(:new_team_params) do
        {
          team: full_team_test_data
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'includes the new team in the response' do
        subject
        expect(json).to have_key('name')
        expect(json).to have_key('identifier')
        expect(json).to have_key('bowlers')
        expect(json['name']).to eq(full_team_test_data['name'])
        expect(json['size']).to eq(4)
      end
    end

    context 'with a partial team' do
      let(:new_team_params) do
        {
          team: partial_team_test_data
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'includes the new team in the response' do
        subject
        expect(json).to have_key('name')
        expect(json).to have_key('identifier')
        expect(json).to have_key('bowlers')
        expect(json['name']).to eq(partial_team_test_data['name'])
        expect(json['size']).to eq(3)
      end
    end

    context 'with invalid data' do
      let(:new_team_params) do
        {
          team: invalid_team_test_data
        }
      end

      it 'fails' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
