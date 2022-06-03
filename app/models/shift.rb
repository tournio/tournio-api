# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(128), not null
#  confirmed     :integer          default(0), not null
#  description   :string
#  details       :jsonb
#  display_order :integer          default(1), not null
#  identifier    :string           not null
#  name          :string
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
  has_many :shift_teams, dependent: :destroy
  has_many :teams, through: :shift_teams

  validates :capacity, comparison: { greater_than_or_equal_to: :confirmed }
  validate :no_unknown_detail_properties

  scope :available, -> { where('confirmed < capacity') }

  before_create :generate_identifier, if: -> { identifier.blank? }

  SUPPORTED_DETAILS = %w(events permit_new_teams permit_solo permit_joins permit_partnering)

  def to_param
    identifier
  end

  def reset_counts
    update(confirmed: 0, requested: 0)
  end

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end

  def no_unknown_detail_properties
    return unless details.present?
    detail_keys = details.keys
    diff = detail_keys - SUPPORTED_DETAILS
    unless diff.empty?
      errors.add(:details, "includes unrecognized properties: #{diff.join(', ')}")
    end
  end
end
