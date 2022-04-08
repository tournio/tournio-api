# frozen_string_literal: true

class BowlerBlueprint < Blueprinter::Base
  identifier :identifier
  fields :first_name, :last_name, :position
  field :nickname, name: :preferred_name

  association :tournament, blueprint: TournamentBlueprint

  field :amount_due do |b, _|
    TournamentRegistration.amount_due(b).to_i
  end

  view :detail do
    field :team_identifier do |b, _|
      # using &. because there may not be a team, if we're doing a singles tournament, say
      b.team&.identifier
    end

    field :amount_billed do |b, _|
      billed = TournamentRegistration.amount_billed(b).to_i
      ActionController::Base.helpers.number_to_currency(billed, precision: 0)
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
  end

  view :director_list do
    field :amount_billed do |b, _|
      billed = TournamentRegistration.amount_billed(b).to_i
      ActionController::Base.helpers.number_to_currency(billed, precision: 0)
    end

    field :has_free_entry do |b, _|
      b.free_entry&.unique_code.present?
    end

    field :team_name do |b, _|
      TournamentRegistration.team_display_name(b.team)
    end

    field :team_identifier do |b, _|
      b.team.identifier
    end

    field :created_at, name: :date_registered, datetime_format: "%F"
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
           :city,
           :country,
           :email,
           :nickname,
           :phone,
           :postal_code,
           :state,
           :igbo_id,
           :usbc_id

    field :display_name do |bowler, _|
      TournamentRegistration.bowler_full_name(bowler)
    end
    field :doubles_partner do |b, _|
      if b.doubles_partner.present?
        TournamentRegistration.bowler_full_name(b.doubles_partner)
      else
        ''
      end
    end
    field :created_at, name: :date_registered, datetime_format: "%F"

    field :amount_billed do |b, _|
      TournamentRegistration.amount_billed(b)
    end
    field :amount_paid do |b, _|
      TournamentRegistration.amount_paid(b)
    end
    field :amount_due do |b, _|
      TournamentRegistration.amount_due(b)
    end

    association :team, blueprint: TeamBlueprint, view: :director_list
    association :free_entry, blueprint: FreeEntryBlueprint
    association :ledger_entries, blueprint: LedgerEntryBlueprint

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
  end
end

