# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(40), not null
#  confirmed     :integer          default(0), not null
#  description   :string           not null
#  display_order :integer          default(1), not null
#  identifier    :string           not null
#  name          :string           not null
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
class Shift < ApplicationRecord
  belongs_to :tournament
  has_many :teams, through: :shift_teams

  scope :available, -> { where('confirmed < capacity') }

  before_create :generate_identifier, if: -> { identifier.blank? }

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end
