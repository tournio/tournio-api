# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(128), not null
#  confirmed     :integer          default(0), not null
#  description   :string
#  details       :jsonb
#  display_order :integer          default(1), not null
#  identifier    :string           not null
#  name          :string
#  requested     :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_shifts_on_identifier     (identifier) UNIQUE
#  index_shifts_on_tournament_id  (tournament_id)
#
require 'rails_helper'

RSpec.describe Shift, type: :model do
  describe 'validations' do
    describe 'details' do
      let(:details) { nil }
      let(:shift) { build :shift, details: details }

      subject { shift.valid? }

      it { is_expected.to be_truthy }

      context 'a standard tournament' do
        let(:details) do
          {
            registration_types: %i(new_team solo join_team)
          }
        end

        it { is_expected.to be_truthy }
      end

      context 'a tournament with event selection, e.g., DAMIT' do
        let(:details) do
          {
            registration_types: %i(solo partner new_pair),
          }
        end

        it { is_expected.to be_truthy }
      end

      context 'no registration types specified' do
        let(:details) do
          {}
        end

        it {is_expected.to be_truthy }
      end

      context 'unknown registration type' do
        let(:details) do
          {
            registration_types: %i(group),
          }
        end

        it { is_expected.to be_falsey }
      end

      context 'unrecognized properties' do
        let(:details) do
          {
            unknown: true,
            also_unknown: true,
          }
        end

        it { is_expected.to be_falsey }
      end
    end
  end
end
