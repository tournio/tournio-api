# frozen_string_literal: true

class LedgerEntryBlueprint < Blueprinter::Base
  identifier :identifier
  fields :notes, :source, :created_at

  field :credit do |le, _|
    le.credit.to_i
  end

  field :debit do |le, _|
    le.debit.to_i
  end
end
