# == Schema Information
#
# Table name: data_points
#
#  id            :bigint           not null, primary key
#  key           :string           not null
#  value         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint
#
# Indexes
#
#  index_data_points_on_created_at     (created_at)
#  index_data_points_on_key            (key)
#  index_data_points_on_tournament_id  (tournament_id)
#
FactoryBot.define do
  factory :data_point do
    
  end
end
