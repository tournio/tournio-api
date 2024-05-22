# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(128), not null
#  description   :string
#  display_order :integer          default(1), not null
#  event_string  :string
#  group_title   :string
#  identifier    :string           not null
#  is_full       :boolean          default(FALSE)
#  name          :string
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

    tournament

    trait :full do
      is_full { true }
    end
  end
end
