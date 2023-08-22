# frozen_string_literal: true

require "rails_helper"

RSpec.describe AddLateFeesToUnpaidBowlersJob, type: :job do
  describe '#do_the_work' do
    let(:wall_clock_time) { Time.zone.parse('2022-12-28T18:37:00-04:00') }
    let(:applies_at) { '2022-12-28T12:37:00-04:00' }
    let(:tournament) do
      create :tournament,
        :active,
        :one_shift,
        :with_entry_fee
    end
    let(:late_fee_item) do
      create :purchasable_item,
        :late_fee,
        tournament: tournament,
        configuration: { applies_at: applies_at }
    end
    let(:job_object) { described_class.new }

    subject { job_object.do_the_work(wall_clock_time) }

    before do
      allow(ScheduleAutomaticLateFeesJob).to receive(:perform_async)
    end

    it 'does not enqueue a ScheduleAutomaticLateFeesJob' do
      expect(ScheduleAutomaticLateFeesJob).not_to receive(:perform_async)
      subject
    end

    context 'When the config option is enabled' do
      before do
        tournament.config_items.find_by_key('automatic_late_fees').update(value: 'true')
      end

      it 'enqueues a ScheduleAutomaticLateFeesJob' do
        expect(ScheduleAutomaticLateFeesJob).to receive(:perform_async).once
        subject
      end

      # context 'when valid_until is more than 24 hours before' do
      #   let(:valid_until) { '2022-12-27T12:37:00-04:00' }
      #
      #   it 'does not enqueue a SchedulePurchaseVoidsJob' do
      #     allow(SchedulePurchaseVoidsJob).to receive(:perform_async)
      #     expect(SchedulePurchaseVoidsJob).not_to receive(:perform_async)
      #     subject
      #   end
      # end

      # context 'when valid_until is in the future' do
      #   let(:valid_until) { '2022-12-29T12:37:00-04:00' }
      #
      #   it 'does not enqueue a SchedulePurchaseVoidsJob' do
      #     allow(SchedulePurchaseVoidsJob).to receive(:perform_async)
      #     expect(SchedulePurchaseVoidsJob).not_to receive(:perform_async)
      #     subject
      #   end
      # end
      #
      # context 'when there is no discount item' do
      #   let!(:discount_item) do
      #     create :purchasable_item,
      #       :late_fee,
      #       tournament: tournament,
      #       configuration: { applies_at: '2022-12-31T12:37:00-04:00' }
      #   end
      #
      #   it 'does not enqueue a SchedulePurchaseVoidsJob' do
      #     allow(SchedulePurchaseVoidsJob).to receive(:perform_async)
      #     expect(SchedulePurchaseVoidsJob).not_to receive(:perform_async)
      #     subject
      #   end
      # end
    end
  end
end
