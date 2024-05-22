require 'rails_helper'

describe ShiftBlueprint do
  describe 'non-attribute fields' do
    let(:tournament) { create(:one_shift_standard_tournament, :active) }
    let(:shift) { tournament.shifts.first }

    let(:team_count) { 16 }

    before do
      team_count.times do
        create :team, tournament: tournament, shifts: [shift]
      end
    end

    subject { described_class.render_as_hash(shift) }

    it 'includes a team count' do
      result = subject
      expect(result[:team_count]).to eq(team_count)
    end
  end
end
