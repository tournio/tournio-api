# frozen_string_literal: true

# == Schema Information
#
# Table name: free_entries
#
#  id            :bigint           not null, primary key
#  confirmed     :boolean          default(FALSE)
#  unique_code   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  bowler_id     :bigint
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_free_entries_on_bowler_id      (bowler_id)
#  index_free_entries_on_tournament_id  (tournament_id)
#

FactoryBot.define do
  factory :free_entry do
    sequence(:unique_code) { |n| "FE-#{n}" }
  end
end
