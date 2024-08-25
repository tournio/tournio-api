# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TournamentConfig do
  let(:tournament) { create :one_shift_standard_tournament }
  let(:tournament_config) { TournamentConfig.new(tournament.config_items) }

  describe '#[]' do
    let(:c1) { tournament.config_items.find_by_key(ConfigItem::Keys::EMAIL_IN_DEV) }
    let(:url) { 'www.igbo.org' }

    before do
      tournament.config_items << ConfigItem.gimme(key_sym: :EMAIL_IN_DEV, initial_value: 'true')
      tournament.config_items.find_by_key(ConfigItem::Keys::WEBSITE).update(value: url)
    end

    it 'accepts a string argument' do
      expect(tournament_config[ConfigItem::Keys::WEBSITE]).to eq(url)
    end

    it 'accepts a symbol argument' do
      expect(tournament_config[:website]).to eq(url)
    end

    it 'returns null when the key is not present' do
      expect(tournament_config[:missing_property]).to be_nil
    end

    it 'returns a boolean value for false, rather than a string' do
      expect(tournament_config[:display_capacity]).to be_falsey
      expect(tournament_config[:display_capacity]).not_to be_instance_of(String)
    end

    it 'returns a boolean value for true, rather than a string' do
      expect(tournament_config[:email_in_dev]).to be_truthy
      expect(tournament_config[:email_in_dev]).not_to be_instance_of(String)
    end

    context 'an integer value' do
      before { tournament.config_items.find_by(key: ConfigItem::Keys::TEAM_SIZE).update(value: 42) }

      it 'returns the value as an integer' do
        expect(tournament_config[ConfigItem::Keys::TEAM_SIZE]).to be_instance_of Integer
      end
    end
  end

  describe '#[]=' do
    let(:c1) { tournament.config_items.find_by_key(ConfigItem::Keys::EMAIL_IN_DEV) }

    before do
      tournament.config_items << ConfigItem.gimme(key_sym: :EMAIL_IN_DEV, initial_value: 'true')
    end

    subject { tournament_config[key] = new_value }

    context 'a string key' do
      let(:key) { ConfigItem::Keys::WEBSITE }
      let(:new_value) { 'www.tourn.io' }

      it 'updates the config item value' do
        subject
        config_item = tournament.config_items.find_by_key(key)
        expect(config_item.value).to eq(new_value)
      end
    end

    context 'a symbol key' do
      let(:key) { ConfigItem::Keys::WEBSITE.to_sym }
      let(:new_value) { 'www.tourn.io' }

      it 'updates the config item value' do
        subject
        config_item = tournament.config_items.find_by_key(key)
        expect(config_item.value).to eq(new_value)
      end
    end

    context 'a numeric value' do
      let(:key) { ConfigItem::Keys::WEBSITE }
      let(:new_value) { 42 }

      it 'updates the config item value' do
        subject
        config_item = tournament.config_items.find_by_key(key)
        expect(config_item.value.to_i).to eq(new_value)
      end
    end

    context 'boolean false' do
      let(:key) { ConfigItem::Keys::EMAIL_IN_DEV }
      let(:new_value) { false }

      it 'updates the config item value' do
        subject
        expect(c1.reload.value).to eq('false')
      end
    end

    context 'boolean true' do
      let(:key) { ConfigItem::Keys::DISPLAY_CAPACITY }
      let(:new_value) { true }

      it 'updates the config item value' do
        subject
        expect(tournament.config_items.find_by_key(key).value).to eq('true')
      end
    end

    context 'an unrecognized key' do
      let(:key) { :strongest_avenger }
      let(:new_value) { 'point break' }

      it 'ignores the assignment' do
        expect { subject }.not_to raise_error
      end

      it 'does not create a new config_item' do
        subject
        expect(tournament.config_items.find_by_key(key)).to be_nil
      end
    end
  end
end
