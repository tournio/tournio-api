# frozen_string_literal: true

# == Schema Information
#
# Table name: ledger_entries
#
#  id         :bigint           not null, primary key
#  credit     :decimal(, )      default(0.0)
#  debit      :decimal(, )      default(0.0)
#  identifier :string
#  notes      :string
#  source     :integer          default("registration"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  bowler_id  :bigint           not null
#
# Indexes
#
#  index_ledger_entries_on_bowler_id   (bowler_id)
#  index_ledger_entries_on_identifier  (identifier)
#

# identifier: free entry code, paypal id, etc.
# notes: added by director on edit
class LedgerEntry < ApplicationRecord
  belongs_to :bowler

  enum :source, %i[registration free_entry manual purchase stripe void automatic]

  accepts_nested_attributes_for :bowler
end
