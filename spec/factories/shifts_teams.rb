# == Schema Information
#
# Table name: shifts_teams
#
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
  factory :shifts_team do
    
  end
end
