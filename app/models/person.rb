# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id          :bigint           not null, primary key
#  address1    :string           not null
#  address2    :string
#  birth_day   :integer          not null
#  birth_month :integer          not null
#  city        :string           not null
#  country     :string           not null
#  email       :string           not null
#  first_name  :string           not null
#  last_name   :string           not null
#  nickname    :string
#  phone       :string           not null
#  postal_code :string           not null
#  state       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  igbo_id     :string
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
            :address1,
            :city,
            :state,
            :country,
            :postal_code,
            :birth_month,
            :birth_day,
            :email,
            :phone,
            presence: { message: 'is required' }
end
