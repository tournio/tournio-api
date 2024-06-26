# frozen_string_literal: true

class BowlerBlueprint < Blueprinter::Base
  identifier :identifier
  fields :first_name, :last_name, :position
  field :nickname, name: :preferred_name
  field :created_at, name: :date_registered, datetime_format: "%F"
  field :full_name do |b, _|
    TournamentRegistration.person_list_name(b.person)
  end
  field :amount_due do |b, _|
    TournamentRegistration.amount_due(b).to_i
  end
  field :doubles_partner_name do |b, _|
    b.doubles_partner.present? ? TournamentRegistration.person_list_name(b.doubles_partner.person) : 'n/a'
  end
  field :amount_paid do |b, _|
    paid = TournamentRegistration.amount_paid(b).to_i
  end

  association :tournament, blueprint: TournamentBlueprint

  view :list do
    association :events, blueprint: PurchaseBlueprint do |bowler, _|
      bowler.purchases.event
    end

    association :doubles_partner, blueprint: BowlerBlueprint
  end

  view :detail do
    include_view :list

    field :team_identifier do |b, _|
      # using &. because there may not be a team, if we're doing a singles tournament, say
      b.team&.identifier
    end

    field :team_name do |b, _|
      TournamentRegistration.team_display_name(b.team)
    end

    field :amount_paid do |b, _|
      paid = TournamentRegistration.amount_paid(b).to_i
      ActionController::Base.helpers.number_to_currency(paid, precision: 0)
    end

    field :has_free_entry do |b, _|
      b.free_entry&.unique_code.present?
    end

    field :free_entry_code do |b, _|
      b.free_entry&.unique_code.present? && b.free_entry&.confirmed ? b.free_entry&.unique_code : nil
    end

    association :unpaid_purchases, blueprint: PurchaseBlueprint do |bowler, _|
      bowler.purchases.includes(:purchasable_item).unpaid.order(amount: :desc)
    end

    association :paid_purchases, blueprint: PurchaseBlueprint do |bowler, _|
      bowler.purchases.includes(:purchasable_item).paid.order(paid_at: :asc)
    end

    association :shifts, blueprint: ShiftBlueprint
  end

  view :director_list do
    field :email

    field :has_free_entry do |b, _|
      b.free_entry&.unique_code.present?
    end

    field :team_name do |b, _|
      b.team.present? ? TournamentRegistration.team_display_name(b.team) : 'n/a'
    end

    field :team_identifier do |b, _|
      b.team.present? ? b.team.identifier : 'n/a'
    end

    field :igbo_member do |b, _|
      b.verified_data['igbo_member'] || false
    end

    field :paid do |b, _|
      TournamentRegistration.amount_due(b) == 0
    end
  end

  view :director_team_detail do
    include_view :director_list

    fields :id, :doubles_partner_id

    field :name do |bowler, _|
      TournamentRegistration.bowler_full_name(bowler)
    end
    association :free_entry, blueprint: FreeEntryBlueprint
  end

  view :director_detail do
    fields :address1,
      :address2,
      :birth_day,
      :birth_month,
      :birth_year,
      :city,
      :country,
      :email,
      :nickname,
      :phone,
      :postal_code,
      :state,
      # :igbo_id,
      :usbc_id

    field :display_name do |bowler, _|
      TournamentRegistration.bowler_full_name(bowler)
    end
    association :doubles_partner, blueprint: BowlerBlueprint
    field :created_at, name: :date_registered, datetime_format: "%F"

    field :amount_paid do |b, _|
      TournamentRegistration.amount_paid(b)
    end
    field :amount_due do |b, _|
      TournamentRegistration.amount_due(b)
    end

    association :team, blueprint: TeamBlueprint, view: :director_list
    association :free_entry, blueprint: FreeEntryBlueprint
    association :ledger_entries, blueprint: LedgerEntryBlueprint
    association :waivers, blueprint: WaiverBlueprint
    association :shifts, blueprint: ShiftBlueprint

    field :additional_question_responses do |b, _|
      b.additional_question_responses.each_with_object({}) { |aqr, obj| obj[aqr.name] = AdditionalQuestionResponseBlueprint.render_as_hash(aqr) }
    end

    field :verified_average do |b, _|
      b.verified_data['verified_average']
    end

    field :handicap do |b, _|
      b.verified_data['handicap']
    end

    field :igbo_member do |b, _|
      b.verified_data['igbo_member'] || false
    end

    field :purchases do |b, _|
      sorted = b.purchases.to_a.sort_by! { |p| TournamentRegistration.purchasable_item_sort(p) }
      PurchaseBlueprint.render_as_hash(sorted)
    end

    field :signups do |b, _|
      b.signups.map { |s| SignupSerializer.new(s).as_json }
    end
  end
end

