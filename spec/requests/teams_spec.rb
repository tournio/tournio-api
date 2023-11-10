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
    let(:tournament) { create :tournament, :active }
    let!(:shift) { tournament.shifts.first }

    before do
      comment = create(:extended_form_field, :comment)
      pronouns = create(:extended_form_field, :pronouns)
      standings = create(:extended_form_field, :standings_link)

      create(:additional_question, extended_form_field: comment, tournament: tournament)
      create(:additional_question, extended_form_field: pronouns, tournament: tournament)
      create(:additional_question, extended_form_field: standings, tournament: tournament)
    end

    let(:new_team_params) do
      {
        team: single_bowler_team_test_data.merge(shift_params),
      }
    end
    let(:shift_params) do
      {
        shift_identifiers: [
          shift.identifier,
        ],
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
      expect(json['name']).to eq(single_bowler_team_test_data['name'])
    end

    it 'correctly associates the new team with its shift' do
      subject
      the_shift = Team.last.shifts.first
      expect(the_shift&.identifier).to eq(shift.identifier)
    end

    it 'includes shifts in the response' do
      subject
      expect(json).to have_key('shifts')
    end

    it 'includes the correct shifts in the response' do
      subject
      expect(json['shifts'][0]['identifier']).to eq(shift.identifier)
    end

    it 'creates data points' do
      expect { subject }.to change(DataPoint, :count).by(1)
    end

    it 'creates the right kinds of data point' do
      subject
      dp = DataPoint.last(4)
      keys = dp.collect(&:key).uniq
      values = dp.collect(&:value).uniq
      expect(keys).to match_array(%w(registration_type))
      expect(values).to match_array(%w(new_team))
    end

    it 'associates the data points with the tournament' do
      subject
      dp = DataPoint.last
      tournament_id = dp.tournament_id
      expect(tournament_id).to eq(tournament.id)
    end

    context 'with an initial size of 3' do
      let(:new_team_params) do
        {
          team: single_bowler_team_test_data.merge(shift_params).merge(
            'initial_size' => '3',
          ),
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
        expect(json['name']).to eq(single_bowler_team_test_data['name'])
        expect(json['initial_size']).to eq(3)
      end

      it 'creates the right kinds of data point' do
        subject
        dp = DataPoint.last
        expect(dp.key).to eq('registration_type')
        expect(dp.value).to eq('new_team')
      end

    end

    context 'with no shift identifier' do
      let(:shift_params) { {} }

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      # context "but we need one, because there are multiple shifts" do
      #   let(:tournament) { create :tournament, :active, :two_shifts }
      #
      #   it 'fails' do
      #     subject
      #     expect(response).to have_http_status(:unprocessable_entity)
      #   end
      # end
      #
      # context "but we need one, because this is a mix-and-match tournament" do
      #   let(:tournament) { create :tournament, :active, :mix_and_match_shifts }
      #
      #   it 'fails' do
      #     subject
      #     expect(response).to have_http_status(:unprocessable_entity)
      #   end
      # end
    end

    context 'a tournament with multiple inclusive shifts' do
      let(:tournament) { create :tournament, :active, :two_shifts }

      context 'when a shift is full' do
        before do
          tournament.shifts.second.update(is_full: true)
        end

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        context 'requesting the full shift' do
          before do
            tournament.shifts.first.update(is_full: true)
            tournament.shifts.second.update(is_full: false)
          end

          it 'fails' do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

    end

    context 'a tournament with mix-and-match shifts' do
      let(:tournament) { create :tournament, :active, :mix_and_match_shifts }
      let(:shift_params) do
        {
          shift_identifiers: [
            tournament.events.team.first.shifts.first.identifier,
            tournament.events.double.first.shifts.last.identifier,
          ],
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'includes the correct shifts in the response' do
        subject
        identifiers = json['shifts'].collect { |s| s['identifier'] }
        expect(identifiers).to match_array(shift_params[:shift_identifiers])
      end


      # This is worth doing, though maybe not initially.
      # ...
      # My client code will not let this happen, but never trust the public not to mess things up.
      context 'missing a shift for a set of events' do
        let(:shift_params) do
          {
            shift_identifiers: [
              tournament.events.team.first.shifts.first.identifier,
            ],
          }
        end

        # it 'fails' do
        #   subject
        #   expect(response).to have_http_status(:unprocessable_entity)
        # end
      end
    end

    context 'with invalid data' do
      let(:new_team_params) do
        {
          team: invalid_team_test_data,
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
      tournament.teams += [
        build(:team, :standard_one_bowler),
        build(:team, :standard_one_bowler),
        build(:team, :standard_two_bowlers),
        build(:team, :standard_two_bowlers),
        build(:team, :standard_three_bowlers),
        build(:team, :standard_three_bowlers),
        build(:team, :standard_three_bowlers),
        build(:team, :standard_full_team),
        build(:team, :standard_full_team),
        build(:team, :standard_full_team),
      ]
    end

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'includes all teams' do
      subject
      expect(json.count).to eq(10)
    end
  end

  describe '#show' do
    subject { get uri, headers: headers, as: :json }

    let(:uri) { "/teams/#{team.identifier}" }
    let(:tournament) { create :tournament, :active }
    let!(:team) { create :team, :standard_full_team, tournament: tournament }
    let(:expected_keys) { %w(identifier name initial_size bowlers) }

    it 'succeeds' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'includes a team in the body' do
      subject
      expect(json).not_to be_nil
    end

    it 'returns the expected identifier in the body' do
      subject
      expect(json['identifier']).to eq(team.identifier)
    end

    it 'returns the expected name in the body' do
      subject
      expect(json['name']).to eq(team.name)
    end

    it 'returns the expected bowlers in the body' do
      subject
      expect(json['bowlers'].count).to eq(team.bowlers.count)
    end

    context 'A regular tournament with a single shift' do
      let(:shift) { tournament.shifts.last }

      before do
        team.shifts << shift
      end

      it 'returns the expected shift in the body' do
        subject
        expect(json['shifts'][0]['identifier']).to eq(shift.identifier)
      end
    end

    context 'in a tournament with a shift preference for all events' do
      let(:tournament) { create :tournament, :active, :two_shifts }
      let(:shift) { tournament.shifts.last }

      before do
        team.shifts << shift
      end

      it 'returns the expected shift in the body' do
        subject
        expect(json['shifts'][0]['identifier']).to eq(shift.identifier)
      end
    end

    context 'with mix-and-match shift preferences' do
      let(:tournament) { create :tournament, :active, :mix_and_match_shifts }

      # Assumption: knowledge of how the events are distributed among the shifts.
      #
      # Future enhancement: it might be useful to add some kind of identifier
      # to each shift that's a hash or shorthand indicating which events it
      # includes, for the ability to easily query them, e.g., give me the shifts
      # that cover X and Y events, knowing how "X and Y events" gets hashed and
      # using that in the where, rather than building a complicated query with joins.
      before do
        team.shifts = [
          tournament.events.team.first.shifts.first,
          tournament.events.double.first.shifts.last,
        ]
      end

      it 'includes multiple shifts in the body' do
        subject
        expect(json['shifts'].count).to eq(2)
      end

      it 'includes the correct shifts' do
        subject
        # This purposefully duplicates the selection of shifts above
        expected = [
          tournament.events.team.first.shifts.first.identifier,
          tournament.events.double.first.shifts.last.identifier,
        ]
        actual = json['shifts'].collect { |shift| shift['identifier'] }
        expect(actual).to match_array(expected)
      end
    end

    context 'a team that does not exist' do
      let (:uri) { '/teams/some-other-identifier' }

      it 'fails with a 404' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
