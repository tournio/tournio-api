# frozen_string_literal: true

# == Schema Information
#
# Table name: signups
#
#  id                  :bigint           not null, primary key
#  aasm_state          :string           default("initial")
#  identifier          :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  bowler_id           :bigint
#  purchasable_item_id :bigint
#
# Indexes
#
#  index_signups_on_bowler_id            (bowler_id)
#  index_signups_on_purchasable_item_id  (purchasable_item_id)
#
class Signup < ApplicationRecord
  include AASM

  belongs_to :bowler
  belongs_to :purchasable_item

  aasm do
    state :initial, initial: true
    state :requested
    state :paid

    event :request do
      transitions from: :initial, to: :requested
    end

    event :never_mind do
      transitions from: :requested, to: :initial
    end

    event :pay do
      transitions from: %i[initial requested], to: :paid
    end
  end

  before_create :generate_identifier

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end
