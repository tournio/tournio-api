# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id            :bigint           not null, primary key
#  identifier    :string           not null
#  name          :string
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

  # @mix-and-match Create a migration to drop shift_id from this table

  has_and_belongs_to_many :shifts

  has_many :bowlers, -> { order(position: :asc) }, dependent: :destroy
  accepts_nested_attributes_for :bowlers

  validates :name, presence: { message: 'Please provide a team name.'}

  before_create :generate_identifier

  delegate :timezone, to: :tournament

  # This allows us to use the team's identifier instead of numeric ID as its helper parameter
  def to_param
    identifier
  end

  private

  def generate_identifier
    begin
      self.identifier = "#{tournament.identifier}-#{SecureRandom.alphanumeric(6)}"
    end while Team.exists?(identifier: self.identifier)
  end
end
