# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduleAutomaticLateFeesJob, type: :job do
  describe 'perform' do
    let(:tournament) do
      create :tournament,
        :active,
        :one_shift,
        :with_entry_fee
    end
    let(:entry_fee_item) { tournament.purchasable_items.entry_fee.first }
    let!(:late_fee_item) do
      create :purchasable_item,
        :late_fee,
        tournament: tournament
    end

    subject { described_class.new.perform(tournament.id) }

    before do
      allow(AddPurchasableItemToBowlerJob).to receive(:perform_async)
      # 10 bowlers who haven't paid entry fee
      10.times do |i|
        b = create :bowler, tournament: tournament
        create :purchase,
          purchasable_item: entry_fee_item,
          bowler: b,
          amount: entry_fee_item.value
      end
      # 5 bowlers who have
      5.times do |i|
        b = create :bowler, tournament: tournament
        create :purchase,
          purchasable_item: entry_fee_item,
          bowler: b,
          amount: entry_fee_item.value,
          paid_at: Time.zone.now
      end
    end

    it 'calls the AddPurchasableItemToBowlerJob 10 times' do
      expect(AddPurchasableItemToBowlerJob).to receive(:perform_async).exactly(10).times
      subject
    end

    context 'in the event a bowler has more than one unpaid purchase' do
      # I could see this happening with an early-registration discount that didn't first get voided...

      let(:additional_item) { create :purchasable_item, :early_discount, tournament: tournament }
      let(:bowler) { create :bowler, tournament: tournament }

      before do
        create :purchase,
          purchasable_item: entry_fee_item,
          bowler: bowler,
          amount: entry_fee_item.value
        create :purchase,
          purchasable_item: additional_item,
          bowler: bowler,
          amount: additional_item.value
      end

      it 'applies only one late fee' do
        expect(AddPurchasableItemToBowlerJob).to receive(:perform_async).with(bowler.id, anything).once
        subject
      end
    end

    context 'in the event a bowler already has a late fee charged' do
      # mmm idempotency

      let(:bowler) { create :bowler, tournament: tournament }
      before do

        create :purchase,
          purchasable_item: entry_fee_item,
          bowler: bowler,
          amount: entry_fee_item.value
        create :purchase,
          purchasable_item: late_fee_item,
          bowler: bowler,
          amount: late_fee_item.value
      end

      it 'does not apply a second one' do
        expect(AddPurchasableItemToBowlerJob).not_to receive(:perform_async).with(bowler.id, late_fee_item.id)
        subject
      end
    end

    context 'the tournament has no late fee item' do
      let!(:late_fee_item) { nil }

      it 'does not create any jobs' do
        expect(AddPurchasableItemToBowlerJob).not_to receive(:perform_async)
        subject
      end
    end
  end
end
