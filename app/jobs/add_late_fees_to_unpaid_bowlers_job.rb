# frozen_string_literal: true

class AddLateFeesToUnpaidBowlersJob
  include Sidekiq::Job

  def perform
    do_the_work
  end

  def do_the_work(time_of_day = Time.zone.now)
    Tournament.upcoming(time_of_day).each do |t|
      # Only do this if the tournament's config item is set.
      next unless t.config['automatic_late_fees']

      t.purchasable_items.late_fee.map do |late_fee_item|
        next unless late_fee_item.configuration['applies_at'].present?

        applies_at = Time.zone.parse(late_fee_item.configuration['applies_at'])
        one_day_ago = time_of_day.advance(days: -1)

        if applies_at.between?(one_day_ago, time_of_day)
          ScheduleAutomaticLateFeesJob.perform_async(t.id)
        end
      end
    end
  end
end
