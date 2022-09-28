# == Schema Information
#
# Table name: data_points
#
#  id            :bigint           not null, primary key
#  key           :integer          not null
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
class DataPoint < ApplicationRecord
  enum :key, %i(registration_type)
  belongs_to :tournament
end
