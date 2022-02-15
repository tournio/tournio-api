# frozen_string_literal: true

# == Schema Information
#
# Table name: paypal_orders
#
#  id         :bigint           not null, primary key
#  details    :jsonb
#  identifier :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class PaypalOrder < ApplicationRecord
  has_many :purchases
end
