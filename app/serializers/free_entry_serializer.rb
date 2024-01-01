# frozen_string_literal: true

#  confirmed     :boolean          default(FALSE)
#  identifier    :string
#  unique_code   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  bowler_id     :bigint
#  tournament_id :bigint           not null
#
class FreeEntrySerializer < JsonSerializer
  attributes :unique_code,
    :confirmed,
    :identifier
end
