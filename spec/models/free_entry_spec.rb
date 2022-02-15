# frozen_string_literal: true

# == Schema Information
#
# Table name: free_entries
#
#  id            :bigint           not null, primary key
#  confirmed     :boolean          default(FALSE)
#  unique_code   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  bowler_id     :bigint
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_free_entries_on_bowler_id      (bowler_id)
#  index_free_entries_on_tournament_id  (tournament_id)
#

require 'rails_helper'

RSpec.describe FreeEntry, type: :model do
  describe 'validations' do
    let(:tournament) { create :tournament }
    subject { create :free_entry, tournament: tournament }
    it { is_expected.to validate_uniqueness_of(:unique_code).scoped_to(:tournament_id).with_message('already exists on this tournament') }
  end
end
