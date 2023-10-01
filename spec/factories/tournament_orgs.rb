# == Schema Information
#
# Table name: tournament_orgs
#
#  id         :bigint           not null, primary key
#  identifier :string           not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tournament_orgs_on_identifier  (identifier) UNIQUE
#
FactoryBot.define do
  factory :tournament_org do
    name { 'An All-Powerful Tournament Organization' }
  end
end
