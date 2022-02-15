# frozen_string_literal: true

class LedgerEntryBlueprint < Blueprinter::Base
  identifier :identifier
  fields :credit, :debit, :notes, :source, :created_at
end
