# == Schema Information
#
# Table name: events
#
#  id                      :bigint           not null, primary key
#  game_count              :integer
#  name                    :string           not null
#  permit_multiple_entries :boolean          default(FALSE)
#  required                :boolean          default(TRUE)
#  roster_type             :integer          not null
#  scratch                 :boolean          default(FALSE)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  tournament_id           :bigint           not null
#
# Indexes
#
#  index_events_on_tournament_id  (tournament_id)
#
FactoryBot.define do
  factory :event do
    ScratchDivision { "MyString" }
  end
end
