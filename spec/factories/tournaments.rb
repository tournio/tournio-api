# frozen_string_literal: true

# == Schema Information
#
# Table name: tournaments
#
#  id             :bigint           not null, primary key
#  aasm_state     :string           not null
#  abbreviation   :string
#  details        :jsonb
#  end_date       :date
#  entry_deadline :datetime
#  identifier     :string           not null
#  location       :string
#  name           :string           not null
#  start_date     :date
#  timezone       :string           default("America/New_York")
#  year           :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_tournaments_on_aasm_state  (aasm_state)
#  index_tournaments_on_identifier  (identifier)
#

FactoryBot.define do
  factory :tournament do
    name { 'An IGBO Tournament' }
    location { 'Atlanta, GA' }
    timezone { 'America/New_York' }
    year { (Date.today + 90.days).year }
    start_date { Date.today + 90.days }
    end_date { Date.today + 92.days }
    entry_deadline { Date.today + 80.days }

    trait :demo do
      aasm_state { :demo }
    end

    trait :testing do
      aasm_state { :testing }
    end

    trait :active do
      aasm_state { :active }
    end

    trait :closed do
      aasm_state { :closed }
    end

    trait :past do
      start_date { Date.today - 10.days }
      end_date { Date.today - 8.days }
      year { (Date.today - 10.days).year }
      entry_deadline { Date.today - 20.days }
    end

    trait :one_shift do
      after(:create) do |t, _|
        create :shift, tournament: t, capacity: 160
      end
    end

    trait :one_small_shift do
      after(:create) do |t, _|
        create :shift, tournament: t, capacity: 16
      end
    end

    trait :two_shifts do
      after(:create) do |t, _|
        create :shift, tournament: t, name: 'Shift 1'
        create :shift, tournament: t, name: 'Shift 2', display_order: 2
      end
    end

    trait :with_entry_fee do
      after(:create) do |t, _|
        create(:purchasable_item,
          :entry_fee,
          tournament: t)
      end
    end

    trait :with_scratch_competition_divisions do
      after(:create) do |t, _|
        create(:purchasable_item,
          :scratch_competition,
          tournament: t,
          configuration: { division: 'Alpha', note: '205+' }
        )
        create(:purchasable_item,
          :scratch_competition,
          tournament: t,
          configuration: { division: 'Bravo', note: '190-204' }
        )
        create(:purchasable_item,
          :scratch_competition,
          tournament: t,
          configuration: { division: 'Charlie', note: '175-189' }
        )
        create(:purchasable_item,
          :scratch_competition,
          tournament: t,
          configuration: { division: 'Delta', note: '160-174' }
        )
        create(:purchasable_item,
          :scratch_competition,
          tournament: t,
          configuration: { division: 'Echo', note: '0-159' }
        )
      end
    end

    trait :with_an_optional_event do
      after(:create) do |t, _|
        create(:purchasable_item,
          :optional_event,
          tournament: t,
          configuration: { order: 1 }
        )
      end
    end

    trait :with_a_banquet do
      after(:create) do |t, _|
        create(:purchasable_item,
          :banquet_entry,
          tournament: t,
        )
      end
    end

    trait :with_extra_stuff do
      after(:create) do |t, _|
        create(:purchasable_item, :banquet_entry, tournament: t)
        create(:purchasable_item, :raffle_bundle, value: 75, tournament: t)
      end
    end

    trait :with_a_bowling_event do
      after(:create) do |t, _|
        create(:purchasable_item, :bowling_event, tournament: t)
      end
    end

    trait :with_a_doubles_event do
      after(:create) do |t, _|
        create(:purchasable_item, :doubles_event, tournament: t)
      end
    end

    trait :with_sanction_item do
      after(:create) do |t, _|
        create(:purchasable_item, :sanction, tournament: t)
      end
    end
  end
end
