# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(40), not null
#  confirmed     :integer          default(0), not null
#  description   :string           not null
#  display_order :integer          default(1), not null
#  identifier    :string           not null
#  name          :string           not null
#  requested     :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_shifts_on_identifier     (identifier) UNIQUE
#  index_shifts_on_tournament_id  (tournament_id)
#
FactoryBot.define do
  factory :shift do
    capacity { 40 }
    description { 'One event on Friday, the other two on Saturday' }
    name { 'Main' }
  end

  trait :half_requested do
    requested { 20 }
  end

  trait :half_filled do
    confirmed { 20 }
  end

  trait :high_demand do
    confirmed { 30 }
    requested { 20 }
  end

  trait :full do
    confirmed { 40 }
  end
end
