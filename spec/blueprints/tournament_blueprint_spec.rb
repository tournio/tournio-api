require 'rails_helper'

describe TournamentBlueprint do
  describe 'configuration items exposed as top-level properties' do
    let(:config_keys) { %i(abbreviation display_capacity email_in_dev end_date entry_deadline location start_date team_size timezone website) }

    let(:tournament) { create(:tournament, :active, :one_small_shift) }
    let(:start_date) { (Date.today + 30.days).iso8601 }
    let(:end_date) { (Date.today + 32.days).iso8601 }
    let(:entry_deadline) { (Time.zone.today + 20.days).iso8601 }
    let(:location) { 'San Diego, CA' }
    let(:timezone) { 'America/Los_Angeles' }
    let(:website) { 'https://tourn.io' }
    let(:abbreviation) { 'QUART' }

    before do
      tournament.config_items += [
        ConfigItem.new(key: 'abbreviation', value: abbreviation),
        ConfigItem.new(key: 'start_date', value: start_date),
        ConfigItem.new(key: 'end_date', value: end_date),
        ConfigItem.new(key: 'entry_deadline', value: entry_deadline),
        ConfigItem.new(key: 'location', value: location),
        ConfigItem.new(key: 'timezone', value: timezone),
        ConfigItem.new(key: 'website', value: website),
      ]
    end

    subject { described_class.render_as_hash(tournament) }

    it 'includes all the expected keys' do
      result = subject
      expect(result.keys).to include(*config_keys)
    end
  end
end
