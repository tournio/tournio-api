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

  has_many :bowler_shifts, dependent: :destroy
  has_many :bowlers, through: :bowler_shifts

  validates :capacity, comparison: { greater_than_or_equal_to: :confirmed }
  validate :no_unknown_detail_properties, :no_unknown_registration_types

  scope :available, -> { where('confirmed < capacity') }

  before_create :generate_identifier, if: -> { identifier.blank? }

  SUPPORTED_DETAILS = %w(events registration_types)
  SUPPORTED_REGISTRATION_TYPES = %w(new_team solo join_team partner new_pair)

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

  def no_unknown_registration_types
    return unless details.present?
    registration_types = details['registration_types'] || []
    diff = registration_types - SUPPORTED_REGISTRATION_TYPES
    unless diff.empty?
      errors.add(:details, "includes unrecognized registration types: #{diff.join(', ')}")
    end
  end
end
