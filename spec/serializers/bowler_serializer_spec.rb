# frozen_string_literal: true

# == Schema Information
#
# Table name: bowlers
#
#  id                 :bigint           not null, primary key
#  identifier         :string
#  position           :integer
#  verified_data      :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  doubles_partner_id :bigint
#  person_id          :bigint
#  team_id            :bigint
#  tournament_id      :bigint
#
# Indexes
#
#  index_bowlers_on_created_at          (created_at)
#  index_bowlers_on_doubles_partner_id  (doubles_partner_id)
#  index_bowlers_on_identifier          (identifier)
#  index_bowlers_on_person_id           (person_id)
#  index_bowlers_on_team_id             (team_id)
#  index_bowlers_on_tournament_id       (tournament_id)
#

# belongs_to :doubles_partner, class_name: 'Bowler', optional: true
# belongs_to :person, dependent: :destroy
# belongs_to :team, optional: true
# belongs_to :tournament
#
# has_one :free_entry
#
# has_many :additional_question_responses, dependent: :destroy
# has_many :ledger_entries, dependent: :destroy
# has_many :purchases, dependent: :destroy
# has_many :stripe_checkout_sessions

require 'rails_helper'

RSpec.describe BowlerSerializer do
  let(:person) { create :person }
  let(:bowler) { create :bowler }

  # Ideally, we would not need to add :tournament as a testable association, since
  # it's the belongs-to side of a has-many relationship

  subject { BowlerSerializer.new(bowler).serialize }
  # subject { BowlerSerializer.new(bowler, within: {doubles_partner: :doubles_partner}).serialize }

  it 'parses as JSON' do
    expect(json_hash).to be_an_instance_of(HashWithIndifferentAccess)
  end

  it 'has the expected root key' do
    expect(json_hash).to have_key(:bowler)
  end

  describe 'model attributes' do
    let(:expected_attributes) { %w(identifier position) }

    it 'has the expected attributes' do
      expect(json_hash[:bowler].keys).to include(*expected_attributes)
    end
  end

  describe 'delegated attributes' do
    let(:expected_attributes) do
      %w(address1
        address2
        birthDay
        birthMonth
        city
        country
        email
        firstName
        lastName
        preferredName
        phone
        postalCode
        state)
    end

    it 'has the expected attributes delegated to the associated Person' do
      expect(json_hash[:bowler].keys).to include(*expected_attributes)
    end
  end

  describe 'other simple attributes' do
    let(:expected_attributes) { %w(registeredOn listName fullName usbcId teamName doublesPartner) }

    it 'has the expected attributes' do
      expect(json_hash[:bowler].keys).to include(*expected_attributes)
    end
  end

  describe 'associations' do
    let(:expected_keys) { %w(team) }

    it 'has the expected keys' do
      expect(json_hash[:bowler].keys).to include(*expected_keys)
    end

    it 'has nil values for those keys' do
      expected_keys.each do |attr|
        expect(json_hash[:bowler][attr]).to be_nil
      end
    end

    context 'a bowler on a team' do
      let(:bowler) { create :bowler, :with_team }

      it 'has something for the team' do
        expect(json_hash[:bowler][:team]).not_to be_nil
      end

      it 'gives the bowler a position' do
        expect(json_hash[:bowler][:position]).to be_a(Integer)
      end
    end
  end
end
