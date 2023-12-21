# frozen_string_literal: true
#
# == Schema Information
#
# Table name: config_items
#
#  id            :bigint           not null, primary key
#  key           :string           not null
#  label         :string
#  value         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint
#
# Indexes
#
#  index_config_items_on_tournament_id_and_key  (tournament_id,key) UNIQUE
#

class ConfigItemSerializer < JsonSerializer
  attributes :id, :key, :label

  attribute :value do |ci|
    %w(true t T).include?(ci.value)
  end
end
