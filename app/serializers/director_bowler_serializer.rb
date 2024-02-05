# frozen_string_literal: true

class DirectorBowlerSerializer < BowlerSerializer
  # attributes :identifier,
  #   :email,
  #   :first_name,
  #   :last_name,
  #   :phone,
  #   :preferred_name,
  #   :usbc_id
  #
  # attribute :registered_on do |b|
  #   b.created_at.strftime('%F')
  # end
  # attribute :list_name do |b|
  #   TournamentRegistration.person_list_name(b.person)
  # end
  # attribute :full_name do |b|
  #   TournamentRegistration.person_display_name(b.person)
  # end

  attributes :address1,
    :address2,
    :birth_day,
    :birth_month,
    :birth_year,
    :city,
    :created_at,
    :state,
    :country,
    :postal_code

  one :free_entry, resource: FreeEntrySerializer
  many :additional_question_responses, resource: AdditionalQuestionResponseSerializer
  many :purchases, resource: PurchaseSerializer
  many :ledger_entries, resource: LedgerEntrySerializer
  many :signups, resource: SignupSerializer
  # many :signups, proc { |signups, params, bowler|
  #   bowler.signups.requested + bowler.signups.paid
  # }, resource: :SignupSerializer

  attribute :doubles_partner do |b|
    b.doubles_partner.present? ? TournamentRegistration.person_list_name(b.doubles_partner) : 'n/a'
  end
  attribute :amount_paid do |b|
    TournamentRegistration.amount_paid(b)
  end
  attribute :amount_due do |b|
    TournamentRegistration.amount_due(b)
  end
  attribute :amount_outstanding do |b|
    TournamentRegistration.amount_outstanding(b)
  end
  attribute :team_name do |b|
    b.team.present? ? b.team.name : 'n/a'
  end
  attribute :position do |b|
    b.position.present? ? b.position : ''
  end
  attribute :verified_average do |b|
    b.verified_data['verified_average']
  end
  attribute :handicap do |b|
    b.verified_data['handicap']
  end
  attribute :igbo_member do |b|
    b.verified_data['igbo_member'] || false
  end
end
