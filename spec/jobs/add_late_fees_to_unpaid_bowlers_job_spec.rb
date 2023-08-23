# frozen_string_literal: true

require "rails_helper"

# Intended to add late fees to bowlers who haven't paid their entry fees
# if the late-registration period started within the last 24 hours
RSpec.describe AddLateFeesToUnpaidBowlersJob, type: :job do
  describe '#do_the_work' do
    let(:wall_clock_time) { Time.zone.parse('2023-12-28T18:37:00-04:00') }
    # late registration started six hours ago
    let(:applies_at) { wall_clock_time.advance(hours: -6) }
    let(:tournament) do
      create :tournament,
        :active,
        :one_shift,
        :with_entry_fee,
        start_date: wall_clock_time + 90.days,
        end_date: wall_clock_time + 92.days,
        entry_deadline: wall_clock_time + 80.days
    end
    let!(:late_fee_item) do
      create :purchasable_item,
        :late_fee,
        tournament: tournament,
        configuration: { applies_at: applies_at }
    end

    subject { described_class.new.do_the_work(wall_clock_time) }

    before do
      allow(ScheduleAutomaticLateFeesJob).to receive(:perform_async)
    end

    it 'does not enqueue a ScheduleAutomaticLateFeesJob' do
      expect(ScheduleAutomaticLateFeesJob).not_to receive(:perform_async)
      subject
    end

    context 'When the config option is enabled' do
      before do
        tournament.config_items.find_by(key: 'automatic_late_fees').update(value: 'true')
      end

      it 'enqueues a ScheduleAutomaticLateFeesJob' do
        expect(ScheduleAutomaticLateFeesJob).to receive(:perform_async).once
        subject
      end

      context 'when applies_at is more than 24 hours before' do
        let(:applies_at) { wall_clock_time.advance(hours: -25) }

        it 'does not enqueue a ScheduleAutomaticLateFeesJob' do
          expect(ScheduleAutomaticLateFeesJob).not_to receive(:perform_async)
          subject
        end
      end

      context 'when applies_at is in the future' do
        let(:applies_at) { wall_clock_time.advance(minutes: 5) }

        it 'does not enqueue a ScheduleAutomaticLateFeesJob' do
          expect(ScheduleAutomaticLateFeesJob).not_to receive(:perform_async)
          subject
        end
      end

      # More of a sanity check, because why would the config item be set if there is no late-fee item?
      context 'when there is no late-fee item' do
        let(:late_fee_item) { nil }

        it 'does not enqueue a ScheduleAutomaticLateFeesJob' do
          expect(ScheduleAutomaticLateFeesJob).not_to receive(:perform_async)
          subject
        end
      end

      context 'for a tournament in demo mode' do
        let(:tournament) do
          create :tournament,
            :demo,
            :one_shift,
            :with_entry_fee,
            start_date: wall_clock_time + 90.days,
            end_date: wall_clock_time + 92.days,
            entry_deadline: wall_clock_time + 80.days
        end

        it 'enqueues a ScheduleAutomaticLateFeesJob' do
          expect(ScheduleAutomaticLateFeesJob).to receive(:perform_async).once
          subject
        end
      end

      context 'for a tournament in the past' do
        let(:tournament) do
          create :tournament,
            :active,
            :one_shift,
            :with_entry_fee,
            start_date: wall_clock_time - 9.days,
            end_date: wall_clock_time - 7.days,
            entry_deadline: wall_clock_time - 20.days
        end

        it 'does not enqueue a ScheduleAutomaticLateFeesJob' do
          expect(ScheduleAutomaticLateFeesJob).not_to receive(:perform_async)
          subject
        end
      end
    end
  end
end
