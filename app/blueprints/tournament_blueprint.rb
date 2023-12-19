# frozen_string_literal: true

class TournamentBlueprint < Blueprinter::Base
  identifier :identifier
  field :id, if: ->(_field_name, tournament, _options) { _options[:director?] }

  fields :name, :year, :abbreviation, :start_date, :end_date, :location, :timezone
  field :aasm_state, name: :state
  field :image_url do |t, options|
    if options[:host].present? && t.logo_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(t.logo_image, options)
    end
  end

  field :entry_deadline do |t, _|
    # datetime_with_timezone(t.entry_deadline, t)
    t&.entry_deadline&.strftime('%FT%R%:z')
  end

  field :team_size do |t,_|
    t.team_size
  end

  field :display_capacity do |t,_|
    t.config[:display_capacity]
  end
  field :publicly_listed do |t,_|
    t.config[:publicly_listed]
  end
  field :email_in_dev do |t,_|
    t.config[:email_in_dev]
  end
  field :accepting_payments do |t,_|
    t.config[:accept_payments]
  end

  field :website do |t,_|
    t.config[:website]
  end

  association :testing_environment, blueprint: TestingEnvironmentBlueprint, if: ->(_field_name, tournament, options) { tournament.testing? || tournament.demo? }

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

    field :registration_options do |t, _|
      types = {}
      Tournament::SUPPORTED_REGISTRATION_OPTIONS.each do |o|
        types[o] = t.details['enabled_registration_options'].include?(o)
      end
      types
    end

    field :event_items do |t, _|
      organized_event_items(tournament: t)
    end

    field :shifts_by_event do |t, _|
      shifts_by_events(tournament: t)
    end
  end

  view :director_detail do
    include_view :detail

    # throw everything in here
    association :testing_environment, blueprint: TestingEnvironmentBlueprint
    association :stripe_account, blueprint: StripeAccountBlueprint
    association :scratch_divisions, blueprint: ScratchDivisionBlueprint
    association :events, blueprint: EventBlueprint
    association :users, blueprint: UserBlueprint

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

    # field :direct_upload_url do |t, options|
    #   if options[:host].present?
    #     Rails.application.routes.url_helpers.rails_direct_uploads_url(options)
    #   end
    # end
  end

  private

  def self.datetime_with_timezone(datetime, tournament)
    return unless datetime.present?
    timezone = tournament.timezone
    datetime.in_time_zone(timezone).strftime('%b %-d, %Y %l:%M%P %Z')
  end

  def self.organized_purchasable_items(tournament:)
    ledger_items = tournament.purchasable_items.ledger
    event_items = tournament.purchasable_items.event
    division_items = tournament.purchasable_items.division
    other_bowling_items = tournament.purchasable_items.bowling.where(refinement: nil).order(name: :asc)
    banquet = tournament.purchasable_items.banquet.order(name: :asc)
    raffle = tournament.purchasable_items.raffle.order(name: :asc)
    product = tournament.purchasable_items.product.order(determination: :desc, refinement: :desc, name: :asc)
    sanction = tournament.purchasable_items.sanction.order(name: :asc)

    determination_order = {
      entry_fee: 0,
      early_discount: 1,
      late_fee: 2,
      event: 4,
      igbo: 5,
      single_use: 6,
      multi_use: 7,
      bundle_discount: 8,
      apparel: 9,
      general: 10,
      handicap: 11,
      scratch: 12,
    }

    {
      ledger: PurchasableItemBlueprint.render_as_hash(ledger_items.sort_by { |li| determination_order[li.determination.to_sym] }),
      event: PurchasableItemBlueprint.render_as_hash(event_items),
      division: PurchasableItemBlueprint.render_as_hash(division_items.sort_by { |di| di.configuration['division'] }),
      bowling: PurchasableItemBlueprint.render_as_hash(other_bowling_items),
      banquet: PurchasableItemBlueprint.render_as_hash(banquet),
      raffle: PurchasableItemBlueprint.render_as_hash(raffle),
      product: PurchasableItemBlueprint.render_as_hash(product),
      sanction: PurchasableItemBlueprint.render_as_hash(sanction),
    }
  end

  def self.organized_event_items(tournament:)
    event_items = tournament.purchasable_items.event
    ledger_items = tournament.purchasable_items.ledger

    determination_order = {
      entry_fee: 0,
      early_discount: 1,
      late_fee: 2,
      event: 4,
      bundle_discount: 8,
    }

    event_refinement_order = {
      single: 1,
      double: 2,
      trio: 3,
      team: 4,
    }

    {
      ledger: PurchasableItemBlueprint.render_as_hash(ledger_items.sort_by { |li| determination_order[li.determination.to_sym] }),
      event: PurchasableItemBlueprint.render_as_hash(event_items.sort_by { |ei| event_refinement_order[ei.refinement.to_sym] }),
    }
  end

  def self.shifts_by_events(tournament:)
    tournament.shifts.each_with_object({}) do |shift, collector|
      event_string = shift.event_string
      if collector[event_string].blank?
        collector[event_string] = []
      end
      collector[event_string] << ShiftBlueprint.render_as_hash(shift)
    end
  end
end
