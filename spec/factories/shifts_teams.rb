# == Schema Information
#
# Table name: shifts_teams
#
#  id           :bigint           not null, primary key
#  aasm_state   :string           not null
#  confirmed_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  shift_id     :bigint           not null
#  team_id      :bigint           not null
#
# Indexes
#
#  index_shifts_teams_on_shift_id  (shift_id)
#  index_shifts_teams_on_team_id   (team_id)
#
FactoryBot.define do
  factory :shift_team do
  end

  trait :confirmed do
    after(:create) do |st, _|
      st.confirm!
    end
  end
end
