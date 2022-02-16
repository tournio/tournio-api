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
    ledger: 'ledger',   # mandatory items, e.g., registration, late fee, early discount
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
    discount_expiration: 'discount_expiration',
  }

  enum refinement: {
    input: 'input',
    division: 'division',
    denomination: 'denomination',
    # add other refinements here as support them, e.g., size, classification
  }

  validate :contains_applies_at, if: proc { |pi| pi.ledger? && pi.late_fee? }
  validate :contains_valid_until, if: proc { |pi| pi.ledger? && pi.early_discount? }
  validate :contains_input_label, if: proc { |pi| pi.input? }
  validate :contains_division, if: proc { |pi| pi.division? }

  before_create :generate_identifier

  scope :user_selectable, -> { where(user_selectable: true) }

  ###################################
  # Validation methods
  ###################################

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