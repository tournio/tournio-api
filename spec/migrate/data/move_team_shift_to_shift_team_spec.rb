# frozen_string_literal: true

require 'rails_helper'
Dir[Rails.root.join('db', 'data', '**', '*.rb')].sort.each { |f| require f }

RSpec.describe MoveTeamShiftToShiftTeam do
  describe 'up' do
    subject { described_class.new.up }

    context 'a tournament with just one shift' do
      let(:tournament) { create :tournament }
      let(:shift) { tournament.shifts.first }

      context 'a team with no bowlers' do
        let!(:team) do
          create :team,
            tournament: tournament,
            shift_id: shift.id
        end

        it 'adds the shift to the HABTM relationship' do
          subject
          expect(team.shifts).to match_array([shift])
        end

        it 'leaves the original shift_id intact' do
          expect { subject }.not_to change(team, :shift_id)
        end
      end

      context 'a team with bowlers' do
        let!(:team) do
          create :team, :standard_full_team,
            tournament: tournament,
            shift_id: tournament.shifts.last.id
        end

        it 'adds the shift to the HABTM relationship' do
          subject
          expect(team.shifts).to match_array([shift])
        end

        it 'leaves the original shift_id intact' do
          expect { subject }.not_to change(team, :shift_id)
        end
      end
    end

    context 'a tournament with two shifts' do
      let(:tournament) { create :tournament, :two_shifts }
      let(:shift) { tournament.shifts.last }

      context 'a team with no bowlers' do
        let!(:team) do
          create :team,
            tournament: tournament,
            shift_id: shift.id
        end

        it 'adds the shift to the HABTM relationship' do
          subject
          expect(team.shifts).to match_array([shift])
        end

        it 'leaves the original shift_id intact' do
          expect { subject }.not_to change(team, :shift_id)
        end
      end

      context 'a team with bowlers' do
        let!(:team) do
          create :team, :standard_full_team,
            tournament: tournament,
            shift_id: tournament.shifts.last.id
        end

        it 'adds the shift to the HABTM relationship' do
          subject
          expect(team.shifts).to match_array([shift])
        end

        it 'leaves the original shift_id intact' do
          expect { subject }.not_to change(team, :shift_id)
        end
      end
    end
  end

  describe 'down' do

  end
end
