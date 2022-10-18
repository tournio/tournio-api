# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TournamentConfig do
  let(:tournament) { create :tournament }
  let(:tournament_config) { TournamentConfig.new(tournament.config_items) }

  describe '#[]' do
    let!(:c1) { create :config_item, :email_in_dev, tournament: tournament, value: 'true' }
    let!(:c2) { create :config_item, :website, tournament: tournament }

    it 'accepts a string argument' do
      expect(tournament_config['website']).to eq(c2.value)
    end

    it 'accepts a symbol argument' do
      expect(tournament_config[:website]).to eq(c2.value)
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
      let!(:c3) { create :config_item, key: 'team_size', value: 42, tournament: tournament }

      it 'returns the value as an integer' do
        expect(tournament_config['team_size']).to be_instance_of Integer
      end
    end
  end

  describe '#[]=' do
    let!(:c1) { create :config_item, :email_in_dev, tournament: tournament, value: 'true' }
    let!(:c2) { create :config_item, :website, tournament: tournament }

    subject { tournament_config[key] = new_value }

    context 'a string key' do
      let(:key) { 'website' }
      let(:new_value) { 'www.tourn.io' }

      it 'updates the config item value' do
        subject
        expect(c2.reload.value).to eq(new_value)
      end
    end

    context 'a symbol key' do
      let(:key) { :website }
      let(:new_value) { 'www.tourn.io' }

      it 'updates the config item value' do
        subject
        expect(c2.reload.value).to eq(new_value)
      end
    end

    context 'a numeric value' do
      let(:key) { :website }
      let(:new_value) { 42 }

      it 'updates the config item value' do
        subject
        expect(c2.reload.value).to eq(new_value.to_s)
      end
    end

    context 'boolean false' do
      let(:key) { :email_in_dev }
      let(:new_value) { false }

      it 'updates the config item value' do
        subject
        expect(c1.reload.value).to eq('false')
      end
    end

    context 'boolean true' do
      let(:key) { 'display_capacity' }
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
