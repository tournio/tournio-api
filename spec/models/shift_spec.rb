# == Schema Information
#
# Table name: shifts
#
#  id            :bigint           not null, primary key
#  capacity      :integer          default(40), not null
#  confirmed     :integer          default(0), not null
#  description   :string           not null
#  details       :jsonb
#  display_order :integer          default(1), not null
#  identifier    :string           not null
#  name          :string           not null
#  requested     :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_shifts_on_identifier     (identifier) UNIQUE
#  index_shifts_on_tournament_id  (tournament_id)
#
require 'rails_helper'

RSpec.describe Shift, type: :model do
  # pending "add some examples to (or delete) #{__FILE__}"
end
