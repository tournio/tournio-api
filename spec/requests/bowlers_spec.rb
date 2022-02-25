require 'rails_helper'

describe BowlersController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe '#create' do
    subject { post uri, params: joining_bowler_params, as: :json }

    let(:uri) { "/teams/#{team.identifier}/bowlers" }
    let(:tournament) { create :tournament, :active, :with_entry_fee }

    before do
      comment = create(:extended_form_field, :comment)
      pronouns = create(:extended_form_field, :pronouns)
      standings = create(:extended_form_field, :standings_link)

      create(:additional_question, extended_form_field: comment, tournament: tournament)
      create(:additional_question, extended_form_field: pronouns, tournament: tournament)
      create(:additional_question, extended_form_field: standings, tournament: tournament)
    end

    context 'with valid bowler input' do
      let(:joining_bowler_params) do
        {
          bowler: joining_bowler_test_data.merge({ position: 4 })
        }
      end

      context 'with a partial team' do
        let(:team) { create(:team, :standard_three_bowlers, tournament: tournament) }

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'includes the new team in the response' do
          subject
          expect(json).to have_key('identifier')
        end
      end

      context 'with a full team' do
        let(:team) { create(:team, :standard_full_team, tournament: tournament) }

        it 'fails' do
          subject
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context 'with invalid data' do
      let(:team) { create(:team, :standard_three_bowlers, tournament: tournament) }
      let(:joining_bowler_params) do
        {
          bowler: invalid_joining_bowler_test_data.merge({position: 4})
        }
      end

      it 'fails' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end

