# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(128), not null
#  description   :string
#  display_order :integer          default(1), not null
#  identifier    :string           not null
#  is_full       :boolean          default(FALSE)
#  name          :string
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

    trait :half_requested do
      requested { 20 }
    end

    trait :half_filled do
      requested { 20 }
    end

    trait :high_demand do
      requested { 35 }
    end

    # TODO update this if we make any model changes to indicate full
    trait :full do
      requested { 40 }
    end
  end
end
