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

FactoryBot.define do
  factory :ledger_entry do
    trait :early_registration do
      credit { 10 }
      identifier { 'early registration' }
    end
    trait :entry_fee do
      debit { 100 }
      identifier { 'entry fee' }
    end
    trait :late_fee do
      debit { 15 }
      identifier { 'late registration' }
    end
    trait :free_entry do
      credit { 100 }
      identifier { 'free entry' }
      source { :free_entry }
    end
    trait :stripe do
      source { :stripe }
    end
  end
end
