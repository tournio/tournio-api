# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id          :bigint           not null, primary key
#  address1    :string
#  address2    :string
#  birth_day   :integer
#  birth_month :integer
#  birth_year  :integer
#  city        :string
#  country     :string
#  email       :string           not null
#  first_name  :string           not null
#  last_name   :string           not null
#  nickname    :string
#  payment_app :string
#  phone       :string           not null
#  postal_code :string
#  state       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  usbc_id     :string
#
# Indexes
#
#  index_people_on_last_name  (last_name)
#  index_people_on_usbc_id    (usbc_id)
#

class Person < ApplicationRecord
  alias_attribute :preferred_name, :nickname

  has_one :bowler

  validates :first_name,
            :last_name,
            :email,
            :phone,
            presence: { message: 'is required' }
end
