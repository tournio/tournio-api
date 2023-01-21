# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchedulePurchaseVoidsJob, type: :job do
  let(:why) { 'because I said so' }

  describe 'perform' do
    let(:wall_clock_time) { Time.zone.parse('2022-12-28T18:37:00-04:00') }
    let(:valid_until) { '2022-12-28T12:37:00-04:00' }
    let(:tournament) do
      create :tournament,
        :active,
        :one_shift,
        :with_entry_fee
    end
    let(:discount_item) do
      create :purchasable_item,
        :early_discount,
        tournament: tournament,
        configuration: { valid_until: '2022-12-28T12:37:00-04:00' }
    end

    let(:job_object) { described_class.new }
    subject { job_object.perform(discount_item.id, why) }

    before do
      10.times do |i|
        b = create :bowler, tournament: tournament
        create :purchase, purchasable_item: discount_item, bowler: b, amount: discount_item.value
      end
      5.times do |i|
        b = create :bowler, tournament: tournament
        create :purchase,
          purchasable_item: discount_item,
          bowler: b,
          amount: discount_item.value,
          paid_at: wall_clock_time.advance(days: -6)
      end
      3.times do |i|
        b = create :bowler, tournament: tournament
        create :purchase,
          purchasable_item: discount_item,
          bowler: b,
          amount: discount_item.value,
          voided_at: wall_clock_time.advance(days: -6)
      end
    end

    it 'calls the VoidPurchaseJob 10 times' do
      # 10 times, because 5 of the purchases are paid, and 3 are already voided
      expect(VoidPurchaseJob).to receive(:perform_async).exactly(10).times
      subject
    end
  end
end
