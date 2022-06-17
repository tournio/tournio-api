# == Schema Information
#
# Table name: bowlers_shifts
#
#  id           :bigint           not null, primary key
#  aasm_state   :string           not null
#  confirmed_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  bowler_id    :bigint           not null
#  shift_id     :bigint           not null
#
# Indexes
#
#  index_bowlers_shifts_on_bowler_id  (bowler_id)
#  index_bowlers_shifts_on_shift_id   (shift_id)
#
FactoryBot.define do
  factory :bowler_shift do

    trait :confirmed do
      after(:create) do |bs, _|
        bs.confirm!
      end
    end
  end
end
