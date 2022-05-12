# == Schema Information
#
# Table name: payment_summary_sends
#
#  id            :bigint           not null, primary key
#  bowler_count  :integer          default(0)
#  last_sent_at  :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_payment_summary_sends_on_tournament_id  (tournament_id)
#
require 'rails_helper'

RSpec.describe PaymentSummarySend, type: :model do
  # pending "add some examples to (or delete) #{__FILE__}"
end
