# == Schema Information
#
# Table name: purchasable_items
#
#  id              :bigint           not null, primary key
#  category        :string           not null
#  configuration   :jsonb
#  determination   :string
#  enabled         :boolean          default(TRUE)
#  identifier      :string           not null
#  name            :string           not null
#  refinement      :string
#  user_selectable :boolean          default(TRUE), not null
#  value           :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_id       :bigint
#  tournament_id   :bigint
#
# Indexes
#
#  index_purchasable_items_on_tournament_id  (tournament_id)
#
require 'rails_helper'

RSpec.describe PurchasableItem, type: :model do
  describe 'validations' do
    let(:tournament) { create(:tournament) }
    let(:base_configuration) { {} }
    let(:category) { :bowling }
    let(:determination) { :single_use }
    let(:refinement) { nil }
    let(:selectable) { true }
    let(:configuration) { base_configuration }
    let(:pi) do
      PurchasableItem.new(
        tournament: tournament,
        category: category,
        determination: determination,
        refinement: refinement,
        name: 'Name of the purchasable item',
        user_selectable: selectable,
        value: 100,
        configuration: configuration,
      )
    end

    subject { pi.valid? }

    # Example: late fee
    describe '#contains_applies_at' do
      let(:category) { :ledger }
      let(:determination) { :late_fee }
      let(:time_string) { Time.zone.now.strftime('%FT%T%:z') }
      let(:configuration) { base_configuration.merge({ applies_at: time_string }) }

      it { is_expected.to be_truthy }

      context 'with a missing value' do
        let(:configuration) { base_configuration }

        it { is_expected.to be_falsey }
      end

      context 'with an obviously invalid time string' do
        let(:time_string) { 'Samantha' }

        it { is_expected.to be_falsey }
      end

      context 'with an almost-valid time string' do
        let(:time_string) { '2021-051-04T00:00:00-04:00' }

        it { is_expected.to be_falsey }
      end
    end

    # Example: early registration discount
    describe '#contains_valid_until' do
      let(:category) { :ledger }
      let(:determination) { :early_discount }
      let(:time_string) { Time.zone.now.strftime('%FT%T%:z') }
      let(:configuration) { base_configuration.merge({ valid_until: time_string }) }

      it { is_expected.to be_truthy }

      context 'with a missing value' do
        let(:configuration) { base_configuration }

        it { is_expected.to be_falsey }
      end

      context 'with an obviously invalid time string' do
        let(:time_string) { 'Samantha' }

        it { is_expected.to be_falsey }
      end

      context 'with an almost-valid time string' do
        let(:time_string) { '2021-051-04T00:00:00-04:00' }

        it { is_expected.to be_falsey }
      end
    end

    # Example: late fee, late fee on an event
    describe '#one_ledger_item_per_determination' do
      let(:category) { :ledger }
      let(:determination) { :late_fee }
      let(:time_string) { 2.weeks.from_now.strftime('%FT%T%:z') }
      let(:configuration) { base_configuration.merge({ applies_at: time_string }) }

      it { is_expected.to be_truthy }

      context 'a standard tournament' do
        before do
          create :purchasable_item, :late_fee, tournament: tournament
        end

        it { is_expected.to be_falsey }
      end

      context 'with event selection' do
        before do
          create :purchasable_item, :event_late_fee, tournament: tournament
        end

        let(:refinement) { :event_linked }

        it { is_expected.to be_truthy }
      end
    end

    # Things like a non-bowler banquet entry, which require some kind of text.
    describe '#contains_input_label' do
      let(:category) { :banquet }
      let(:refinement) { :input }
      let(:label) { 'Attendee name' }
      let(:configuration) { base_configuration.merge({ input_label: label }) }

      it { is_expected.to be_truthy }

      context 'with a missing label' do
        let(:configuration) { base_configuration }

        it { is_expected.to be_falsey }
      end

      context 'with an empty input label string' do
        let(:label) { '' }

        it { is_expected.to be_falsey }
      end
    end

    # Things like Scratch Masters, which break the participants down by average (or some other criterion)
    describe '#contains_division' do
      let(:category) { :bowling }
      let(:determination) { :single_use }
      let(:refinement) { :division }
      let(:extra_configuration) do
        {
          division: 'A',
          note: '211+',
        }
      end
      let(:configuration) { base_configuration.merge(extra_configuration) }

      it { is_expected.to be_truthy }

      context 'with a missing note string' do
        let(:extra_configuration) { { division: 'A' } }

        it { is_expected.to be_truthy }
      end

      context 'with a missing division' do
        let(:configuration) { base_configuration }

        it { is_expected.to be_falsey }
      end

      context 'with an empty division string' do
        let(:extra_configuration) { { division: '' } }

        it { is_expected.to be_falsey }
      end
    end
  end
end
