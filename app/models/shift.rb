# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(128), not null
#  description   :string
#  display_order :integer          default(1), not null
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
class Shift < ApplicationRecord
  belongs_to :tournament
  has_and_belongs_to_many :teams

  validates :capacity, numericality: { greater_than: 0 }

  scope :available, -> { where(is_full: false) }

  before_create :generate_identifier, if: -> { identifier.blank? }

  def to_param
    identifier
  end

  private

  def generate_identifier
    begin
      self.identifier = SecureRandom.alphanumeric(6)
    end while Shift.exists?(identifier: self.identifier)
  end
end
