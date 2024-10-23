# frozen_string_literal: true

class DirectorTournamentSerializer < TournamentSerializer
  attributes :id

  many :config_items, resource: ConfigItemSerializer
  many :shifts, resource: ShiftSerializer
  many :purchasable_items, proc { |purchasable_items, params, tournament|
    ledger_items = tournament.purchasable_items.ledger
    event_items = tournament.purchasable_items.event
    division_items = tournament.purchasable_items.division
    single_bowling_items = tournament.purchasable_items.bowling.single_use.where(refinement: nil).order(name: :asc)
    multi_bowling_items = tournament.purchasable_items.bowling.multi_use.order(name: :asc)
    banquet = tournament.purchasable_items.banquet.order(name: :asc)
    raffle = tournament.purchasable_items.raffle.order(name: :asc)
    product = tournament.purchasable_items.product.order(determination: :desc, refinement: :desc, name: :asc)
    sanction = tournament.purchasable_items.sanction.order(name: :asc)

    determination_order = {
      entry_fee: 0,
      early_discount: 1,
      late_fee: 2,
      event: 4,
      igbo: 5,
      single_use: 6,
      multi_use: 7,
      bundle_discount: 8,
      apparel: 9,
      general: 10,
      handicap: 11,
      scratch: 12,
    }

    ledger_items.sort_by { |li| determination_order[li.determination.to_sym] } +
      event_items +
      division_items.sort_by { |di| di.configuration['division'] } +
      single_bowling_items +
      multi_bowling_items +
      banquet +
      raffle +
      product +
      sanction
  },
    resource: PurchasableItemSerializer

  attribute :bowler_count do |t|
    t.bowlers.count
  end

  attribute :team_count do |t|
    t.teams.count
  end

  attribute :free_entry_count do |t|
    t.free_entries.count
  end

  attribute :chart_data do |t|
    {
      lastWeekRegistrations: ChartDataQueries.last_week_registrations_by_day(t),
      lastWeekPayments: ChartDataQueries.last_week_payments_by_day(t),
      lastWeekRegistrationTypes: ChartDataQueries.last_week_registration_types_by_day(t),
      lastWeekPurchasesByDay: ChartDataQueries.last_week_item_purchases_by_day(t),
    }
  end
end
