# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(40), not null
#  confirmed     :integer          default(0), not null
#  description   :string           not null
#  desired       :integer          default(0), not null
#  display_order :integer          default(1), not null
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_shifts_on_tournament_id  (tournament_id)
#
FactoryBot.define do
  factory :shift do
    capacity { 40 }
    description { 'One event on Friday, the other two on Saturday' }
    name { 'Main' }
  end

  trait :half_requested do
    desired { 20 }
  end

  trait :half_filled do
    confirmed { 20 }
  end

  trait :high_demand do
    confirmed { 30 }
    desired { 20 }
  end

  trait :full do
    confirmed { 40 }
  end
end
