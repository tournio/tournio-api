# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(40), not null
#  confirmed     :integer          default(0), not null
#  description   :string           not null
#  desired       :integer          default(0), not null
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_shifts_on_tournament_id  (tournament_id)
#
class Shift < ApplicationRecord
  belongs_to :tournament
  has_many :teams, through: :shift_teams
end
