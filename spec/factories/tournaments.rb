# frozen_string_literal: true

# == Schema Information
#
# Table name: tournaments
#
#  id         :bigint           not null, primary key
#  aasm_state :string           not null
#  identifier :string           not null
#  name       :string           not null
#  start_date :date
#  year       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tournaments_on_aasm_state  (aasm_state)
#  index_tournaments_on_identifier  (identifier)
#

FactoryBot.define do
  factory :tournament do
    name { 'An IGBO Tournament' }
    start_date { Date.today + 90.days }
    year { (Date.today + 90.days).year }

    after(:create) do |t, _|
      create(:config_item, :entry_deadline, tournament: t, value: Date.today + 80.days)
    end
  end

  trait :testing do
    aasm_state { :testing }
  end

  trait :active do
    aasm_state { :active }
  end

  trait :closed do
    aasm_state { :closed }
    start_date { Date.today - 30.days }
    year { (Date.today - 30.days).year }
  end

  trait :future_closed do
    aasm_state { :closed }
    start_date { Date.today + 10.days }
    year { (Date.today + 10.days).year }
  end

  trait :accepting_payments do
    after(:create) do |t, _|
      create(:config_item, :paypal_client_id, tournament: t)
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
end
