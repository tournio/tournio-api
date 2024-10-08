# frozen_string_literal: true

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

require 'rails_helper'

RSpec.describe ConfigItemSerializer do
  let(:tournament) { create :tournament }
  let(:config_item) { tournament.config_items.find_by(key: ConfigItem::Keys::TEAM_SIZE) }

  subject { ConfigItemSerializer.new(config_item).serialize }

  it 'parses as JSON' do
    expect(json_hash).to be_an_instance_of(HashWithIndifferentAccess)
  end

  describe 'model attributes' do
    let(:expected_attributes) { %w(id key label) }

    it 'has the expected attributes' do
      expect(json_hash.keys).to include(*expected_attributes)
    end
  end

  describe 'other simple attributes' do
    let(:expected_attributes) { %w(value) }

    it 'has the expected attributes' do
      expect(json_hash.keys).to include(*expected_attributes)
    end
  end

  describe 'where value is a boolean' do
    let(:key) { ConfigItem::Keys::ENABLE_FREE_ENTRIES }
    let(:config_item) { tournament.config_items.find_by(key: key) }

    context 'for something that is true' do
      let(:value) { true }

      before do
        config_item.update(value: 'true')
      end

      it 'has a value that parses as boolean' do
        expect(json_hash[:value]).to be_an_instance_of(TrueClass)
      end
    end

    context 'for something that is false' do
      let(:value) { false }

      before do
        config_item.update(value: 'false')
      end

      it 'has a value that parses as boolean' do
        expect(json_hash[:value]).to be_an_instance_of(FalseClass)
      end
    end
  end
end
