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

FactoryBot.define do
  factory :person do
    first_name  { 'Angus' }
    last_name   { 'McBowler' }
    birth_day   { 28 }
    birth_month { 12 }
    birth_year  { 1980 }
    address1    { '123 Synthetic Lane' }
    city        { 'Denver' }
    country     { 'US' }
    email       { 'angus@bowlers.of.the.world' }
    phone       { '1-800-555-5555' }
    state       { 'CO' }
    postal_code { '80237' }
    usbc_id     { '1234-56789' }
  end
end
