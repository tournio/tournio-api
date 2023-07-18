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

# belongs_to :doubles_partner, class_name: 'Bowler', optional: true
# belongs_to :person, dependent: :destroy
# belongs_to :team, optional: true
# belongs_to :tournament
#
# has_one :free_entry
# has_one :bowler_shift, dependent: :destroy
# has_one :shift, through: :bowler_shift
#
# has_many :additional_question_responses, dependent: :destroy
# has_many :ledger_entries, dependent: :destroy
# has_many :purchases, dependent: :destroy
# has_many :stripe_checkout_sessions

require 'rails_helper'

RSpec.describe Bowler, type: :model do
  let(:person) { create :person }
  let(:bowler) { create :bowler, person: person }

  # Ideally, we would not need to add :tournament as a testable association, since
  # it's the belongs-to side of a has-many relationship

  describe 'model attributes' do
    let(:expected_attributes) { %i(identifier position) }
  end
end
