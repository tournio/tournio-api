# frozen_string_literal: true

# == Schema Information
#
# Table name: waivers
#
#  id                  :bigint           not null, primary key
#  amount              :integer
#  created_by          :string
#  identifier          :string
#  name                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  bowler_id           :bigint
#  purchasable_item_id :bigint
#
# Indexes
#
#  index_waivers_on_bowler_id            (bowler_id)
#  index_waivers_on_purchasable_item_id  (purchasable_item_id)
#
class Waiver < ApplicationRecord
  belongs_to :bowler
  belongs_to :purchasable_item

  before_create :populate_from_pi
  before_create :generate_identifier

  private

  def generate_identifier
    begin
      self.identifier = SecureRandom.alphanumeric(6)
    end while Waiver.exists?(identifier: self.identifier)
  end

  def populate_from_pi
    self.name = purchasable_item.name
    self.amount = purchasable_item.value
  end
end
