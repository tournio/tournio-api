# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExpireUnpaidEarlyDiscountsJob, type: :job do
  describe '#do_the_work' do
    let(:wall_clock_time) { Time.zone.parse('2022-12-28T18:37:00-04:00') }
    let(:valid_until) { '2022-12-28T12:37:00-04:00' }
    let(:tournament) do
      create :tournament,
        :active,
        :one_shift,
        :with_entry_fee
    end
    let!(:discount_item) do
      create :purchasable_item,
        :early_discount,
        tournament: tournament,
        configuration: { valid_until: valid_until }
    end

    let(:job_object) { described_class.new }
    subject { job_object.do_the_work(wall_clock_time) }

    it 'enqueues a SchedulePurchaseVoidsJob' do
      allow(SchedulePurchaseVoidsJob).to receive(:perform_async)
      subject
      expect(SchedulePurchaseVoidsJob).to have_received(:perform_async).once
    end

    context 'when valid_until is more than 24 hours before' do
      let(:valid_until) { '2022-12-27T12:37:00-04:00' }

      it 'does not enqueue a SchedulePurchaseVoidsJob' do
        allow(SchedulePurchaseVoidsJob).to receive(:perform_async)
        subject
        expect(SchedulePurchaseVoidsJob).not_to have_received(:perform_async)
      end
    end

    context 'when valid_until is in the future' do
      let(:valid_until) { '2022-12-29T12:37:00-04:00' }

      it 'does not enqueue a SchedulePurchaseVoidsJob' do
        allow(SchedulePurchaseVoidsJob).to receive(:perform_async)
        subject
        expect(SchedulePurchaseVoidsJob).not_to have_received(:perform_async)
      end
    end

    context 'when there is no discount item' do
      let!(:discount_item) do
        create :purchasable_item,
          :late_fee,
          tournament: tournament,
          configuration: { applies_at: '2022-12-31T12:37:00-04:00' }
      end

      it 'does not enqueue a SchedulePurchaseVoidsJob' do
        allow(SchedulePurchaseVoidsJob).to receive(:perform_async)
        subject
        expect(SchedulePurchaseVoidsJob).not_to have_received(:perform_async)
      end
    end

    # before do
    #   10.times do |i|
    #     b = create :bowler, tournament: tournament
    #     create :purchase, purchasable_item: discount_item, bowler: b, amount: discount_item.value
    #   end
    #   5.times do |i|
    #     b = create :bowler, tournament: tournament
    #     create :purchase,
    #       purchasable_item: discount_item,
    #       bowler: b,
    #       amount: discount_item.value,
    #       paid_at: wall_clock_time.advance(days: -6)
    #   end
    # end

    # it 'reduces the number of unpaid discounts by 10' do
    #   expect { subject }.to change(Purchase, :unpaid).by(-10)
    # end
    #
    # it 'voids the 10 unpaid purchases' do
    #   expect { subject }.to change(Purchase, :void).by(10)
    # end
    #
    # it 'leaves the 5 paid purchases intact' do
    #   expect { subject }.not_to change(Purchase, :paid)
    # end
  end
end
