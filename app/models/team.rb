# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id            :bigint           not null, primary key
#  identifier    :string           not null
#  initial_size  :integer          default(4)
#  name          :string
#  options       :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  shift_id      :bigint
#  tournament_id :bigint
#
# Indexes
#
#  index_teams_on_identifier     (identifier) UNIQUE
#  index_teams_on_shift_id       (shift_id)
#  index_teams_on_tournament_id  (tournament_id)
#

class Team < ApplicationRecord
  include TeamBusiness

  belongs_to :tournament
  belongs_to :shift, optional: true
  has_many :bowlers, -> { order(position: :asc) }, dependent: :destroy
  accepts_nested_attributes_for :bowlers
  # accepts_nested_attributes_for :shift, update_only: true

  before_create :generate_identifier

  delegate :timezone, to: :tournament

  # This allows us to use the team's identifier instead of numeric ID as its helper parameter
  def to_param
    identifier
  end

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end
