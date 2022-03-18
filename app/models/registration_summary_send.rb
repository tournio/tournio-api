# == Schema Information
#
# Table name: registration_summary_sends
#
#  id            :bigint           not null, primary key
#  bowler_count  :integer          default(0)
#  last_sent_at  :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_registration_summary_sends_on_tournament_id  (tournament_id)
#
class RegistrationSummarySend < ApplicationRecord
  belongs_to :tournament
end
