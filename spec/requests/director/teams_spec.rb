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

    let!(:tournament) { create :tournament, :active, :one_shift }
    let(:tournament_identifier) { tournament.identifier }
    let(:shift) { tournament.shifts.first }

    before do
      10.times do
        create :team, :standard_full_team, tournament: tournament, shifts: [shift]
      end

      2.times do
        create :team, :standard_one_bowler, tournament: tournament, shifts: [shift]
      end

      2.times do
        create :team, :standard_two_bowlers, tournament: tournament, shifts: [shift]
      end

      1.times do
        create :team, :standard_three_bowlers, tournament: tournament, shifts: [shift]
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
        let(:requesting_user) { create :user, :director, tournament_orgs: [tournament.tournament_org] }

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
    let(:tournament) { create :tournament, :active, :one_shift }
    let(:shift) { tournament.shifts.first }

    let(:params) do
      {
        team: {
          name: 'High Rollers',
          shift_identifiers: [shift.identifier],
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

    it 'links the team with the indicated shift' do
      subject
      expect(json).to have_key('shifts')
      expect(json['shifts'][0]['identifier']).to eq(shift.identifier)
    end

    context 'when the tournament has 2 inclusive shifts' do
      let(:tournament) { create :tournament, :active, :two_shifts }
      let(:shift) { tournament.shifts.last }

      it 'succeeds with a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'links the team with the indicated shift' do
        subject
        expect(json).to have_key('shifts')
        expect(json['shifts'][0]['identifier']).to eq(shift.identifier)
      end
    end

    context 'when the tournament has mix-and-match shifts' do
      let(:tournament) { create :tournament, :active, :mix_and_match_shifts }
      let(:shifts) do
        [
          tournament.events.team.first.shifts.first,
          tournament.events.double.first.shifts.last,
        ]
      end
      let(:shift_identifiers) { shifts.collect(&:identifier) }
      let(:params) do
        {
          team: {
            name: 'High Rollers',
            shift_identifiers: shift_identifiers,
          }
        }
      end

      it 'succeeds with a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'links the team with the indicated shifts' do
        subject
        expect(json).to have_key('shifts')
        identifiers = json['shifts'].collect { |s| s['identifier'] }
        expect(identifiers).to match_array(shift_identifiers)
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
        let(:requesting_user) { create :user, :director, tournament_orgs: [tournament.tournament_org] }

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
    let(:team) { create :team, tournament: tournament, shifts: tournament.shifts }
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
      let(:requesting_user) { create(:user, :director, tournament_orgs: my_orgs) }
      let(:my_orgs) { [] }

      it 'yields a 401 Unauthorized' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'for this tournament' do
        let(:my_orgs) { [tournament.tournament_org] }

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
    let(:team) { create :team, :standard_full_team, tournament: tournament, shifts: tournament.shifts }
    let(:team_identifier) { team.identifier }
    let(:new_name) { 'High Rollers' }
    let(:new_initial_size) { 4 }
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
          initial_size: new_initial_size,
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

    it 'updates the initial size' do
      subject
      expect(team.reload.initial_size).to eq(new_initial_size)
    end

    context 'moving to a different shift' do
      let(:tournament) { create :tournament, :active, :two_shifts }
      let(:old_shift) { tournament.shifts.first }
      let(:new_shift) { tournament.shifts.second }
      let(:team) { create :team, :standard_full_team, tournament: tournament, shifts: [old_shift] }

      let(:params) do
        {
          team: {
            shift_identifiers: [new_shift.identifier],
          }
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'includes the updated team in the response' do
        subject
        expect(json['shifts'][0]['name']).to eq(new_shift.name)
      end

      context 'error scenarios' do
        context 'an unrecognized shift identifier' do
          let(:params) do
            {
              team: {
                shift_identifiers: ['no-the-other-one'],
              }
            }
          end

          it 'yields a 404 Not Found' do
            subject
            expect(response).to have_http_status(:not_found)
          end
        end

        # TODO We aren't worrying about capacity. But we do want to be able to mark a shift as full / unavailable
        # context 'the destination shift is full' do
        #   # try moving to a shift that's full of confirmed bowlers.
        #   let(:new_shift) { create :shift, :full, tournament: tournament }
        #
        #   it 'yields a 409 Conflict' do
        #     subject
        #     expect(response).to have_http_status(:conflict)
        #   end
        # end
      end
    end

    context 'moving around a mix-and-match tournament' do
      let(:tournament) { create :tournament, :active, :mix_and_match_shifts }
      let(:old_shifts) do
        [
          tournament.events.team.first.shifts.first,
          tournament.events.double.first.shifts.last,
        ]
      end
      let(:new_shifts) do
        [
          tournament.events.team.first.shifts.last,
          tournament.events.double.first.shifts.first,
        ]
      end
      let(:params) do
        {
          team: {
            shift_identifiers: new_shifts.collect { |s| s.identifier },
          }
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'includes the new shifts in the response' do
        subject
        identifiers = json['shifts'].collect { |s| s['identifier'] }
        expect(identifiers).to match_array(new_shifts.collect { |s| s.identifier })
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
        let(:requesting_user) { create :user, :director, tournament_orgs: [tournament.tournament_org] }

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
    let(:team) { create :team, :standard_full_team, tournament: tournament, shifts: tournament.shifts }
    let(:team_identifier) { team.identifier }

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
        let(:requesting_user) { create :user, :director, tournament_orgs: [tournament.tournament_org] }

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
