require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::TeamsController, type: :request do
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

    let(:uri) { "/director/tournaments/#{tournament_identifier}/teams" }

    let(:tournament_identifier) { tournament.identifier }
    let(:tournament) { create :tournament, :active }

    before do
      10.times do
        create :team, :standard_full_team, tournament: tournament
      end

      2.times do
        create :team, :standard_one_bowler, tournament: tournament
      end

      2.times do
        create :team, :standard_two_bowlers, tournament: tournament
      end

      1.times do
        create :team, :standard_three_bowlers, tournament: tournament
      end
    end

    include_examples 'an authorized action'

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'includes all registered teams in the response' do
      subject
      expect(json.length).to eq(15);
    end

    context 'as an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'retrieving only partial teams' do
      let(:uri) { "/director/tournaments/#{tournament_identifier}/teams?partial=true" }

      it 'includes all registered teams in the response' do
        subject
        expect(json.length).to eq(5);
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

    let(:uri) { "/director/tournaments/#{tournament_identifier}/teams" }

    let(:tournament_identifier) { tournament.identifier }
    let(:tournament) { create :tournament, :active }

    let(:params) do
      {
        team: {
          name: 'High Rollers',
        }
      }
    end

    include_examples 'an authorized action'

    it 'succeeds with a 201 Created' do
      subject
      expect(response).to have_http_status(:created)
    end

    it 'includes the new team in the response' do
      subject
      expect(json).to have_key('name')
      expect(json).to have_key('identifier')
      expect(json['name']).to eq('High Rollers');
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

  describe '#show' do
    subject { get uri, headers: auth_headers }

    let(:uri) { "/director/teams/#{team_identifier}" }

    let(:tournament) { create :tournament }
    let(:team) { create :team, tournament: tournament }
    let(:team_identifier) { team.identifier }

    include_examples 'an authorized action'

    it 'returns a JSON representation of the team' do
      subject
      expect(json['identifier']).to eq(team.identifier);
    end

    context 'When I am an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'When I am a tournament director' do
      let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
      let(:my_tournaments) { [] }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'for this tournament' do
        let(:my_tournaments) { [tournament] }

        it 'yields a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'returns a JSON representation of the team' do
          subject
          expect(json['identifier']).to eq(team.identifier);
        end
      end
    end
  end

  describe '#update' do
    subject { patch uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/teams/#{team_identifier}" }

    let(:tournament) { create :tournament, :active }
    let(:team) { create :team, :standard_full_team, tournament: tournament }
    let(:team_identifier) { team.identifier }
    let(:new_name) { 'High Rollers' }
    let(:attributes_array) do
      team.bowlers.each_with_object([]) do |bowler, result|
        result << {
          id: bowler.id,
          position: 5 - bowler.position,
        }
      end
    end

    let(:params) do
      {
        team: {
          name: new_name,
          bowlers_attributes: attributes_array,
        }
      }
    end

    include_examples 'an authorized action'

    it 'succeeds with a 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'includes the updated team in the response' do
      subject
      expect(json).to have_key('name')
      expect(json).to have_key('identifier')
      expect(json['name']).to eq(new_name)
    end

    context 'Changing the chosen shift' do
      let(:shift1) { create :shift, tournament: tournament, requested: 20, confirmed: 20, capacity: 100 }
      let(:shift2) { create :shift, tournament: tournament, requested: 30, confirmed: 30, capacity: 100 }
      let!(:shift_team) { create :shift_team, team: team, shift: shift1 }
      let(:params) do
        {
          team: {
            name: new_name,
            shift: shift2.identifier,
            bowlers_attributes: attributes_array,
          }
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it "changes the team's shift assignment" do
        subject
        expect(team.reload.shift).to eq(shift2)
      end

      it "drops the requested count of shift1" do
        expect { subject }.to change { shift1.reload.requested }.by(-4)
      end

      it "increases the requested count of shift2" do
        expect { subject }.to change { shift2.reload.requested }.by(4)
      end

      it "doesn't change the confirmed count of shift1" do
        expect { subject }.not_to change { shift1.reload.confirmed }
      end

      it "doesn't change the confirmed count of shift2" do
        expect { subject }.not_to change { shift2.reload.confirmed }
      end

      context "The team's spot in the previous shift was confirmed" do
        let!(:shift_team) { create :shift_team, team: team, shift: shift1, confirmed_at: 2.days.ago }

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it "changes the team's shift assignment" do
          subject
          expect(team.reload.shift).to eq(shift2)
        end

        it "copies over the confirmed_at date from the previous shift to the new one" do
          prev_confirmed_at = shift_team.confirmed_at
          subject
          new_confirmed_at = team.reload.shift_team.confirmed_at
          expect(new_confirmed_at).to eq(prev_confirmed_at)
        end

        it "ensures the state of the new shift_team is confirmed" do
          subject
          expect(team.reload.shift_team.confirmed?).to be_truthy
        end

        it "drops the confirmed count of shift1" do
          expect { subject }.to change { shift1.reload.confirmed }.by(-4)
        end

        it "increases the confirmed count of shift2" do
          expect { subject }.to change { shift2.reload.confirmed }.by(4)
        end

        it "doesn't change the requested count of shift1" do
          expect { subject }.not_to change { shift1.reload.requested }
        end

        it "doesn't change the requested count of shift2" do
          expect { subject }.not_to change { shift2.reload.requested }
        end
      end
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
      context 'an unrecognized team identifier' do
        let(:team_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'a failed validation' do
        let(:params) do
          {
            team: {
              name: new_name,
              bowlers_attributes: attributes_array
            }
          }
        end

        context 'duplicated positions' do
          let(:attributes_array) do
            team.bowlers.each_with_object([]) do |bowler, result|
              result << {
                id: bowler.id,
                position: 1,
              }
            end
          end

          it 'yields a 400 Bad Request' do
            subject
            expect(response).to have_http_status(:bad_request)
          end

          it 'puts the validation errors into the response' do
            subject
            expect(json).to have_key('errors')
          end
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete uri, headers: auth_headers, as: :json }

    let(:uri) { "/director/teams/#{team_identifier}" }

    let(:tournament) { create :tournament, :active }
    let(:team) { create :team, :standard_full_team, tournament: tournament }
    let(:team_identifier) { team.identifier }

    include_examples 'an authorized action'

    it 'succeeds with a 204 No Content' do
      subject
      expect(response).to have_http_status(:no_content)
    end

    context 'when the team is on a shift' do
      let(:shift) { create :shift, :high_demand, tournament: tournament }
      let!(:shift_team) { create :shift_team, team: team, shift: shift }

      it 'drops the shift requested count by the team size' do
        expect { subject }.to change { shift.reload.requested }.by(-4)
      end
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
      context 'an unrecognized team identifier' do
        let(:team_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
