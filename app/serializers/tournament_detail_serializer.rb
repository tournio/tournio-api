# frozen_string_literal: true

class TournamentDetailSerializer < TournamentSerializer
  # attributes :testing_environment

  many :additional_questions, resource: AdditionalQuestionSerializer
  many :contacts, resource: ContactSerializer
  many :purchasable_items,
    proc { |purchasable_items, params, tournament|
      purchasable_items.ledger
    },
    key: 'fees_and_discounts',
    resource: PurchasableItemSerializer
  many :shifts, resource: ShiftSerializer

  attribute :registration_options do |tournament|
    types = {}
    Tournament::SUPPORTED_REGISTRATION_OPTIONS.each do |o|
      types[o] = tournament.details['enabled_registration_options'].include?(o)
    end
    types
  end

  attribute :testing_environment do |tournament|
    {
      registration_period: tournament.testing_environment.conditions['registration_period'],
    }
  end
end
