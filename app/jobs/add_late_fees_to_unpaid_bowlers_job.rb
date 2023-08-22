# frozen_string_literal: true

class AddLateFeesToUnpaidBowlersJob
  include Sidekiq::Job

  def perform
    do_the_work
  end

  def do_the_work(time_of_day = Time.zone.now)
    Tournament.active.each do |t|
      # Only do this if the tournament's config item is set.
      next unless t.config['automatic_discount_voids']

      t.purchasable_items.early_discount.map do |discount_item|
        next unless discount_item.configuration['valid_until'].present?

        expires_at = Time.zone.parse(discount_item.configuration['valid_until'])
        one_day_ago = time_of_day.advance(days: -1)

        if expires_at.between?(one_day_ago, time_of_day)
          SchedulePurchaseVoidsJob.perform_async(discount_item.id, 'Bowler failed to pay registration fee before the early-registration discount passed')
        end
      end
    end
  end
end
