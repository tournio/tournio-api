# frozen_string_literal: true

# == Schema Information
#
# Table name: purchasable_items
#
#  id              :bigint           not null, primary key
#  category        :string           not null
#  configuration   :jsonb
#  determination   :string           not null
#  identifier      :string           not null
#  name            :string           not null
#  refinement      :string
#  user_selectable :boolean          default(TRUE), not null
#  value           :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tournament_id   :bigint
#
# Indexes
#
#  index_purchasable_items_on_tournament_id  (tournament_id)
#

class PurchasableItem < ApplicationRecord
  belongs_to :tournament
  has_many :purchases

  enum category: {
    bowling: 'bowling', # optional bowling events
    ledger: 'ledger', # mandatory items, e.g., registration, late fee, early discount
    banquet: 'banquet', # uh, banquet
    product: 'product', #  Thing like raffle ticket bundles, shirts, and other merchandise
    # add other categories here as we support them, e.g., program
  }

  enum determination: {
    entry_fee: 'entry_fee',
    late_fee: 'late_fee',
    early_discount: 'early_discount',
    single_use: 'single_use',
    multi_use: 'multi_use',

    event: 'event', # a selectable bowling event when bowlers can choose events, like singles or baker doubles
    bundle_discount: 'bundle_discount', # a ledger item

    # this allows directors to cancel out an early-registration discount when
    # a bowler has failed to complete their registration, e.g., pay fees, before
    # the deadline.
    # Currently only available to use by superusers via console.
    discount_expiration: 'discount_expiration',
  }

  enum refinement: {
    input: 'input',
    division: 'division',
    denomination: 'denomination',
    event_linked: 'event_linked', # on a ledger late_fee item, linked with an event (when event selection is permitted)
    singles: 'singles', # for events
    doubles: 'doubles', # for events
    team: 'team',       # for events
    trios: 'trios',     # for events
  }

  validate :one_ledger_item_per_determination, if: proc { |pi| pi.ledger? }, on: :create
  validate :contains_applies_at, if: proc { |pi| pi.ledger? && pi.late_fee? }
  validate :contains_valid_until, if: proc { |pi| pi.ledger? && pi.early_discount? }
  validate :contains_input_label, if: proc { |pi| pi.input? }
  validate :contains_division, if: proc { |pi| pi.division? }
  validate :contains_denomination, if: proc { |pi| pi.denomination? }

  before_create :generate_identifier

  scope :user_selectable, -> { where(user_selectable: true) }

  ###################################
  # Validation methods
  ###################################

  # does not apply to event-linked late fees, since there can be one for each defined event
  # hence the "refinement: nil" condition
  def one_ledger_item_per_determination
    unless PurchasableItem.where(
      tournament_id: tournament_id,
      category: 'ledger',
      determination: determination,
      refinement: nil).empty?
      errors.add(:determination, 'already present')
      return
    end
  end

  def contains_applies_at
    unless configuration['applies_at'].present?
      errors.add(:configuration, 'needs an applies_at date/time')
      return
    end
    begin
      time = configuration['applies_at'].to_time
      if time.nil?
        raise ArgumentError
      end
    rescue ArgumentError
      errors.add(:configuration, 'needs a valid date/time string for applies_at')
    end
  end

  def contains_valid_until
    unless configuration['valid_until'].present?
      errors.add(:configuration, 'needs a valid_until date/time')
      return
    end
    begin
      time = configuration['valid_until'].to_time
      if time.nil?
        raise ArgumentError
      end
    rescue ArgumentError
      errors.add(:configuration, 'needs a valid date/time string for valid_until')
    end
  end

  def contains_input_label
    unless configuration['input_label'].present?
      errors.add(:configuration, 'needs a label for the input field')
    end
  end

  def contains_division
    unless configuration['division'].present?
      errors.add(:configuration, 'needs a division indicator')
    end
  end

  def contains_denomination
    unless configuration['denomination'].present?
      errors.add(:configuration, 'needs a denomination indicator')
    end
  end

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end
