# == Schema Information
#
# Table name: external_payments
#
#  id           :bigint           not null, primary key
#  details      :jsonb
#  identifier   :string
#  payment_type :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class ExternalPayment < ApplicationRecord
  has_many :purchases

  enum :payment_type, %i(paypal stripe)
end
