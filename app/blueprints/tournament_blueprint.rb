# frozen_string_literal: true

class TournamentBlueprint < Blueprinter::Base
  identifier :identifier

  fields :name, :year, :abbreviation, :start_date, :end_date, :location, :timezone
  field :aasm_state, name: :state
  field :image_url do |t, options|
    if options[:host].present? && t.logo_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(t.logo_image, options)
    end
  end

  field :entry_deadline do |t, _|
    # datetime_with_timezone(t.entry_deadline, t)
    t&.entry_deadline&.strftime('%FT%R')
  end

  field :team_size do |t,_|
    t.team_size
  end

  field :display_capacity do |t,_|
    t.config[:display_capacity]
  end
  field :email_in_dev do |t,_|
    t.config[:email_in_dev]
  end
  field :website do |t,_|
    t.config[:website]
  end

  view :list do
    field :status do |t, _|
      TournamentRegistration.display_status(t)
    end
    field :late_fee_applies_at do |t, _|
      datetime_with_timezone(t.late_fee_applies_at, t)
    end
  end

  view :detail do
    include_view :list

    association :contacts, blueprint: ContactBlueprint
    association :shifts, blueprint: ShiftBlueprint
    association :config_items, blueprint: ConfigItemBlueprint

    field :additional_questions do |t, _|
      t.additional_questions.order(:order).each_with_object({}) { |aq, obj| obj[aq.name] = AdditionalQuestionBlueprint.render_as_hash(aq) }
    end

    field :available_shifts do |t, _|
      ShiftBlueprint.render_as_hash(t.shifts.available)
    end

    association :testing_environment, blueprint: TestingEnvironmentBlueprint, if: ->(_field_name, tournament, options) { tournament.testing? || tournament.demo? }
    field :registration_deadline do |t, _|
      datetime_with_timezone(t.config['entry_deadline'], t)
    end
    field :early_registration_ends do |t, _|
      t.early_registration_ends.present? ? datetime_with_timezone(t.early_registration_ends, t) : nil
    end
    field :registration_deadline do |t, _|
      datetime_with_timezone(t.entry_deadline, t)
    end
    field :max_bowlers_per_entry, name: :max_bowlers
    field :registration_fee do |t, _|
      t.purchasable_items.entry_fee.take&.value
    end
    field :late_registration_fee do |t, _|
      t.purchasable_items.late_fee.take&.value
    end
    field :early_registration_discount do |t, _|
      t.purchasable_items.early_discount.take&.value
    end
  end

  view :director_list do
    field :id
    field :status do |t, _|
      TournamentRegistration.display_status(t)
    end
  end

  view :director_detail do
    include_view :director_list

    # throw everything in here
    association :config_items, blueprint: ConfigItemBlueprint
    association :contacts, blueprint: ContactBlueprint
    association :testing_environment, blueprint: TestingEnvironmentBlueprint
    association :shifts, blueprint: ShiftBlueprint
    association :stripe_account, blueprint: StripeAccountBlueprint
    association :scratch_divisions, blueprint: ScratchDivisionBlueprint
    association :events, blueprint: EventBlueprint

    field :available_conditions do |t, _|
      output = {}
      TestingConditions.available_conditions.each_pair do |key, options|
        output[key] = {
          display_name: key.to_s.humanize,
          options: options.values.collect do |opt|
            {
              value: opt,
              display_value: opt.humanize,
            }
          end
        }
      end
      output
    end

    field :additional_questions do |t, _|
      t.additional_questions.order(:order).each_with_object([]) { |aq, obj| obj << AdditionalQuestionBlueprint.render_as_hash(aq) }
    end

    field :available_questions do |t, _|
      if t.setup? || t.testing? || t.demo?
        ExtendedFormField.where.not(id: t.additional_questions.select(:extended_form_field_id)).collect do |eff|
          ExtendedFormFieldBlueprint.render_as_hash(eff)
        end
      else
        []
      end
    end

    field :bowler_count do |t, _|
      t.bowlers.count
    end

    field :team_count do |t, _|
      t.teams.count
    end

    field :free_entry_count do |t, _|
      t.free_entries.count
    end

    field :purchasable_items do |t, _|
      if t.active? || t.closed?
        organized_purchasable_items(tournament: t)
      else
        PurchasableItemBlueprint.render_as_hash(t.purchasable_items)
      end
    end

    field :chart_data do |t, _|
      {
        last_week_registrations: ChartDataQueries.last_week_registrations_by_day(t),
        last_week_payments: ChartDataQueries.last_week_payments_by_day(t),
        last_week_registration_types: ChartDataQueries.last_week_registration_types_by_day(t),
        last_week_purchases_by_day: ChartDataQueries.last_week_item_purchases_by_day(t),
      }
    end
  end

  private

  def self.datetime_with_timezone(datetime, tournament)
    return unless datetime.present?
    timezone = tournament.timezone
    datetime.in_time_zone(timezone).strftime('%b %-d, %Y %l:%M%P %Z')
  end

  def self.organized_purchasable_items(tournament:)
    ledger_items = tournament.purchasable_items.ledger
    division_items = tournament.purchasable_items.division
    other_bowling_items = tournament.purchasable_items.bowling.where(refinement: nil).order(name: :asc)
    banquet = tournament.purchasable_items.banquet.order(name: :asc)
    product = tournament.purchasable_items.product.order(name: :asc)
    sanction = tournament.purchasable_items.sanction.order(name: :asc)

    determination_order = {
      entry_fee: 0,
      early_discount: 1,
      late_fee: 2,
      discount_expiration: 3,
      igbo: 4,
      single_use: 5,
      multi_use: 6,
    }

    {
      ledger: PurchasableItemBlueprint.render_as_hash(ledger_items.sort_by { |li| determination_order[li.determination.to_sym] }),
      division: PurchasableItemBlueprint.render_as_hash(division_items.sort_by { |di| di.configuration['division'] }),
      bowling: PurchasableItemBlueprint.render_as_hash(other_bowling_items),
      banquet: PurchasableItemBlueprint.render_as_hash(banquet),
      product: PurchasableItemBlueprint.render_as_hash(product),
      sanction: PurchasableItemBlueprint.render_as_hash(sanction),
    }
  end
end
