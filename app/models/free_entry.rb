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

# How directors use free entries:
#
# Give them away at other tournaments. Each one has a code unique to the tournament, for control.
#
# Associate with one bowler, which negates all fees for standard events, including late fees.
class FreeEntry < ApplicationRecord
  belongs_to :bowler, optional: true
  belongs_to :tournament

  validates :unique_code, uniqueness: { scope: :tournament_id, message: 'already exists on this tournament' }
  validates :bowler_id, uniqueness: { message: 'already has a free entry linked' }

  accepts_nested_attributes_for :bowler

  scope :unconfirmed, -> { where(confirmed: false) }
  scope :unassigned, -> { where(bowler: nil) }
end
