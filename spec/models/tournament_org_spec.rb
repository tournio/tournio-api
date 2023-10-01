# == Schema Information
#
# Table name: tournament_orgs
#
#  id         :bigint           not null, primary key
#  identifier :string           not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tournament_orgs_on_identifier  (identifier) UNIQUE
#
require 'rails_helper'

RSpec.describe TournamentOrg, type: :model do
end
