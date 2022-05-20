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
    let(:shift) { create :shift, tournament: tournament }
    let(:shift_params) do
      {
        shift: {
          identifier: shift.identifier,
        }
      }
    end

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
          team: full_team_test_data.merge(shift_params),
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it "creates a ShiftTeam instance" do
        expect { subject }.to change(ShiftTeam, :count).by(1)
      end

      it "associates the new team to the shift" do
        subject
        team = Team.last
        expect(team.shift).to eq(shift)
      end

      it "bumps the shift's requested attribute by 4" do
        expect { subject }.to change { shift.reload.requested }.by(4)
      end

      it "does not change the shift's confirmed attribute" do
        expect { subject }.not_to change { shift.reload.confirmed }
      end

      it 'does not set the place_with_others attribute under options' do
        subject
        team = Team.last
        expect(team.options['place_with_others']).to be_nil
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
          team: partial_team_test_data.merge(shift_params)
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it "creates a ShiftTeam instance" do
        expect { subject }.to change(ShiftTeam, :count).by(1)
      end

      it "associates the new team to the shift" do
        subject
        team = Team.last
        expect(team.shift).to eq(shift)
      end

      it "bumps the shift's requested attribute" do
        expect { subject }.to change { shift.reload.requested }.by(3)
      end

      it "does not change the shift's confirmed attribute" do
        expect { subject }.not_to change { shift.reload.confirmed }
      end

      it 'the options object is not empty' do
        subject
        team = Team.last
        expect(team.options).not_to be_empty
      end

      it 'sets the place_with_others attribute under options' do
        subject
        team = Team.last
        expect(team.options['place_with_others']).to be_truthy
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
          team: invalid_team_test_data.merge(shift_params)
        }
      end

      it 'fails' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe '#index' do
    subject { get uri, headers: headers, as: :json }

    let(:uri) { "/tournaments/#{tournament.identifier}/teams" }
    let(:tournament) { create :tournament, :active }
    let(:expected_keys) { %w(identifier name size) }

    before do
      create :team, :standard_one_bowler, tournament: tournament
      create :team, :standard_one_bowler, tournament: tournament
      create :team, :standard_two_bowlers, tournament: tournament
      create :team, :standard_two_bowlers, tournament: tournament
      create :team, :standard_three_bowlers, tournament: tournament
      create :team, :standard_three_bowlers, tournament: tournament
      create :team, :standard_three_bowlers, tournament: tournament
      create :team, :standard_full_team, tournament: tournament
      create :team, :standard_full_team, tournament: tournament
      create :team, :standard_full_team, tournament: tournament
    end

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'includes all teams' do
      subject
      expect(json.count).to eq(10)
    end

    context 'Requesting incomplete teams only' do
      let(:uri) { "/tournaments/#{tournament.identifier}/teams?incomplete=true" }

      it 'includes incomplete teams only' do
        subject
        expect(json.count).to eq(7)
      end
    end
  end

  describe '#show' do
    subject { get uri, headers: headers, as: :json }

    let(:uri) { "/teams/#{team.identifier}" }
    let(:tournament) { create :tournament, :active }
    let!(:team) { create :team, :standard_full_team, tournament: tournament }
    let(:expected_keys) { %w(identifier name size bowlers) }

    it 'succeeds' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'returns the expected team in the body' do
      subject
      expect(json['identifier']).to eq(team.identifier)
      expect(json['name']).to eq(team.name)
      expect(json['bowlers'].count).to eq(team.bowlers.count)
    end

    context 'a team that does not exist' do
      let (:uri) { '/teams/some-other-identifier'}

      it 'fails with a 404' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
