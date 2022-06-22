# frozen_string_literal: true

# == Schema Information
#
# Table name: tournaments
#
#  id         :bigint           not null, primary key
#  aasm_state :string           not null
#  identifier :string           not null
#  name       :string           not null
#  start_date :date
#  year       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tournaments_on_aasm_state  (aasm_state)
#  index_tournaments_on_identifier  (identifier)
#

class Tournament < ApplicationRecord
  include AASM
  include TournamentBusiness

  has_many :additional_questions, dependent: :destroy
  has_many :bowlers, dependent: :destroy
  has_many :config_items, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :extended_form_fields, through: :additional_questions
  has_many :free_entries, dependent: :destroy
  has_many :purchasable_items, dependent: :destroy
  has_many :shifts, -> { order(display_order: :asc)}, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_one :testing_environment, dependent: :destroy
  has_one :registration_summary_send
  has_one :payment_summary_send
  has_one :stripe_account

  accepts_nested_attributes_for :additional_questions, allow_destroy: true

  before_create :generate_identifier, if: -> { identifier.blank? }
  after_create :initiate_testing_environment

  scope :upcoming, ->(right_now = Time.zone.now) { where('start_date > ?', right_now) }
  scope :available, -> { upcoming.where(aasm_state: %w[active closed]) }

  aasm do
    state :setup, initial: true
    state :testing
    state :active
    state :closed
    state :demo

    event :test do
      transitions from: :setup, to: :testing
    end

    event :open do
      transitions from: %i[testing closed], to: :active
    end

    event :close do
      transitions from: :active, to: :closed
    end

    event :demonstrate do
      transitions from: :setup, to: :demo
    end

    event :reset do
      before do
        clear_data
      end
      after do
        reset_demo_basics
      end

      transitions from: :demo, to: :setup
    end
  end

  # This allows us to use the tournament's identifier instead of numeric ID as its helper parameter
  def to_param
    identifier
  end

  ###########################################

  private

  def generate_identifier
    require 'slugify'

    self.identifier = "#{name} #{year}".slugify
  end

  def initiate_testing_environment
    self.testing_environment = TestingEnvironment.new(conditions: TestingEnvironment.defaultConditions)
  end

  def clear_data
    return unless demo?
    teams.destroy_all
    bowlers.destroy_all
    free_entries.destroy_all
    purchasable_items.destroy_all
    additional_questions.destroy_all
  end

  def reset_demo_basics
    self.start_date = Date.today + 3.months
    self.year = start_date.year
    generate_identifier
    save
  end
end
