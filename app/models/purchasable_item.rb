# frozen_string_literal: true

# == Schema Information
#
# Table name: purchasable_items
#
#  id              :bigint           not null, primary key
#  category        :string           not null
#  configuration   :jsonb
#  determination   :string
#  enabled         :boolean          default(TRUE)
#  identifier      :string           not null
#  name            :string           not null
#  refinement      :string
#  user_selectable :boolean          default(TRUE), not null
#  value           :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_id       :bigint
#  tournament_id   :bigint
#
# Indexes
#
#  index_purchasable_items_on_tournament_id  (tournament_id)
#

class PurchasableItem < ApplicationRecord
  include ApparelDetails

  belongs_to :tournament
  has_many :purchases
  belongs_to :parent, class_name: 'PurchasableItem', inverse_of: :children, optional: true
  has_many :children, inverse_of: :parent, class_name: 'PurchasableItem', foreign_key: 'parent_id', dependent: :destroy
  has_many :signups
  has_many :waivers

  has_one :stripe_product, dependent: :destroy
  has_one :stripe_coupon, dependent: :destroy

  # has_one_attached :image

  enum category: {
    bowling: 'bowling', # optional bowling events
    ledger: 'ledger', # mandatory items, e.g., registration, late fee, early discount
    banquet: 'banquet', # uh, banquet
    product: 'product', #  Things like raffle ticket bundles, shirts, and other merchandise
    sanction: 'sanction', # Memberships such as IGBO and USBC
    raffle: 'raffle', # Raffle ticket packs, including multi-city
    bracket: 'bracket', # Single-event and megabracket entries, individual or team
  }

  enum determination: {
    entry_fee: 'entry_fee',
    late_fee: 'late_fee',
    early_discount: 'early_discount',
    bundle_discount: 'bundle_discount', # a ledger item

    # bowling items:
    single_use: 'single_use',
    multi_use: 'multi_use',
    event: 'event', # a selectable bowling event when bowlers can choose events, like singles or baker doubles

    # sanction items:
    igbo: 'igbo',
    usbc: 'usbc',

    # Product items:
    general: 'general', # For things that don't fit into the other groups
    apparel: 'apparel', # shirts and such

    # For brackets, and more!
    handicap: 'handicap',
    scratch: 'scratch',
  }

  enum refinement: {
    input: 'input',
    division: 'division',
    event_linked: 'event_linked', # on a ledger late_fee item, linked with an event (when event selection is permitted)
    single: 'single', # Used for events and brackets
    double: 'double', # Used for events and brackets
    team: 'team', # Used for events and brackets
    trio: 'trio', # Used for events

    sized: 'sized', # For apparel available in multiple sizes; marks the parent
  }

  validate :one_ledger_item_per_determination, if: proc { |pi| pi.ledger? }, on: :create
  validate :contains_applies_at, if: proc { |pi| pi.ledger? && pi.late_fee? }
  validate :contains_valid_until, if: proc { |pi| pi.ledger? && pi.early_discount? }
  validate :contains_input_label, if: proc { |pi| pi.input? }
  validate :contains_division, if: proc { |pi| pi.division? }

  before_create :generate_identifier

  scope :enabled, -> { where(enabled: true) }
  scope :user_selectable, -> { where(user_selectable: true) }
  scope :one_time, -> { where(category: %w(ledger sanction)).or(where(determination: %w(single_use event))) }

  def one_time?
    %w(ledger sanction).include?(category) || %w(single_use event).include?(determination)
  end

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

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end
