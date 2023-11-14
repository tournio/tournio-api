# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(128), not null
#  description   :string
#  display_order :integer          default(1), not null
#  event_string  :string
#  group_title   :string
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
  has_and_belongs_to_many :events

  validates :capacity, numericality: { greater_than: 0 }

  scope :available, -> { where(is_full: false) }

  before_create :generate_identifier, if: -> { identifier.blank? }
  before_save :generate_event_string, if: -> { events.any? }
  before_save :generate_group_title, if: -> { events.any? }

  def to_param
    identifier
  end

  private

  def generate_identifier
    begin
      self.identifier = SecureRandom.alphanumeric(6)
    end while Shift.exists?(identifier: self.identifier)
  end

  def generate_event_string
    self.event_string = events.collect(&:roster_type).sort.join('_')
  end

  def generate_group_title
    self.group_title = events.collect(&:name).join(' / ')
  end
end
