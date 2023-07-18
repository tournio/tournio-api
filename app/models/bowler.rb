# frozen_string_literal: true

# == Schema Information
#
# Table name: bowlers
#
#  id                 :bigint           not null, primary key
#  identifier         :string
#  position           :integer
#  verified_data      :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  doubles_partner_id :bigint
#  person_id          :bigint
#  team_id            :bigint
#  tournament_id      :bigint
#
# Indexes
#
#  index_bowlers_on_created_at          (created_at)
#  index_bowlers_on_doubles_partner_id  (doubles_partner_id)
#  index_bowlers_on_identifier          (identifier)
#  index_bowlers_on_person_id           (person_id)
#  index_bowlers_on_team_id             (team_id)
#  index_bowlers_on_tournament_id       (tournament_id)
#

class Bowler < ApplicationRecord
  belongs_to :doubles_partner, class_name: 'Bowler', optional: true
  belongs_to :person, dependent: :destroy
  belongs_to :team, optional: true
  belongs_to :tournament
  has_one :free_entry
  has_one :bowler_shift, dependent: :destroy
  has_one :shift, through: :bowler_shift
  has_many :additional_question_responses, dependent: :destroy
  has_many :ledger_entries, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :stripe_checkout_sessions

  attr_accessor :doubles_partner_num

  validates :position,
            numericality: {
              only_integer: true,
              greater_than: 0,
            },
            if: -> { team.present? }

  delegate :address1,
           :address2,
           :birth_day,
           :birth_month,
           :city,
           :country,
           :email,
           :first_name,
           :last_name,
           :nickname,
           :phone,
           :postal_code,
           :preferred_name,
           :state,
           :igbo_id,
           :usbc_id, to: :person

  scope :without_doubles_partner, -> { where(doubles_partner_id: nil) }

  accepts_nested_attributes_for :person, :free_entry, :additional_question_responses, :bowler_shift

  before_create :generate_identifier
  before_destroy :unlink_free_entry, :unlink_doubles_partner

  def unlink_free_entry
    return unless free_entry.present?

    free_entry.update(confirmed: false, bowler_id: nil)
  end

  def unlink_doubles_partner
    doubles_partner.update(doubles_partner_id: nil) if doubles_partner.present?
  end

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end
