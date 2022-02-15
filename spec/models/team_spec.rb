# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id            :bigint           not null, primary key
#  identifier    :string           not null
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint
#
# Indexes
#
#  index_teams_on_identifier     (identifier) UNIQUE
#  index_teams_on_tournament_id  (tournament_id)
#

require 'rails_helper'

RSpec.describe Team, type: :model do
  let(:team) { create :team, tournament: create(:tournament) }

  describe 'creation callbacks' do
    subject { team.save }

    context 'on a new team' do
      let(:team) { build(:team, tournament: create(:tournament)) }

      it 'generates an identifier upon initial save' do
        expect { subject }.to change(team, :identifier).from(nil).to(anything)
      end
    end

    context 'on an existing team' do
      it 'does not change the identifier, even if the name has changed' do
        team.name = team.name + ' for real'
        expect { subject }.not_to change(team, :identifier)
      end
    end
  end
end
