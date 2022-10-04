# == Schema Information
#
# Table name: scratch_divisions
#
#  id            :bigint           not null, primary key
#  high_average  :integer          default(300), not null
#  key           :string           not null
#  low_average   :integer          default(0), not null
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_scratch_divisions_on_tournament_id  (tournament_id)
#
class ScratchDivision < ApplicationRecord
  belongs_to :tournament
  has_and_belongs_to_many :events
end
