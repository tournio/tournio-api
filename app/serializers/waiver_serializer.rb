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
class WaiverSerializer < JsonSerializer
  attributes :id, :identifier, :created_by, :created_at, :amount, :name
end
