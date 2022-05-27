# frozen_string_literal: true

class TournamentBlueprint < Blueprinter::Base
  identifier :identifier

  fields :name, :year, :id
  field :image_path do |t, _|
    t.config[:image_path]
  end

  view :list do
    field :aasm_state, name: :state
    field :start_date, datetime_format: '%B %-d, %Y'
    field :location do |t, options|
      t.config[:location]
    end
    field :status do |t, _|
      TournamentRegistration.display_status(t)
    end
    field :late_fee_applies_at do |t, _|
      datetime_with_timezone(t.late_fee_applies_at, t)
    end
    field :entry_deadline do |t, _|
      datetime_with_timezone(t.entry_deadline, t)
    end
  end

  view :detail do
    include_view :list

    association :contacts, blueprint: ContactBlueprint
    association :shifts, blueprint: ShiftBlueprint
    association :config_items, blueprint: ConfigItemBlueprint
    transform ConfigItemsFilter

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
    field :website do |t, _|
      t.config[:website]
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
    field :aasm_state, name: :state
    field :start_date, datetime_format: '%B %-d, %Y'
    field :status do |t, _|
      TournamentRegistration.display_status(t)
    end
  end

  view :director_detail do
    include_view :director_list

    field :image_path do |t, _|
      t.config[:image_path]
    end

    # throw everything in here
    association :config_items, blueprint: ConfigItemBlueprint
    transform ConfigItemsFilter
    association :contacts, blueprint: ContactBlueprint
    association :testing_environment, blueprint: TestingEnvironmentBlueprint
    association :shifts, blueprint: ShiftBlueprint
    association :stripe_account, blueprint: StripeAccountBlueprint

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
      if t.active?
        organized_purchasable_items(tournament: t)
      else
        PurchasableItemBlueprint.render_as_hash(t.purchasable_items)
      end
    end
  end

  private

  def self.datetime_with_timezone(datetime, tournament)
    return unless datetime.present?
    time_zone = tournament.config[:time_zone]
    datetime.in_time_zone(time_zone).strftime('%b %-d, %Y %l:%M%P %Z')
  end

  def self.organized_purchasable_items(tournament:)
    ledger_items = tournament.purchasable_items.ledger
    division_items = tournament.purchasable_items.division
    other_bowling_items = tournament.purchasable_items.bowling.where(refinement: nil).order(name: :asc)
    banquet = tournament.purchasable_items.banquet.order(name: :asc)
    product = tournament.purchasable_items.product.order(name: :asc)

    determination_order = {
      entry_fee: 0,
      early_discount: 1,
      late_fee: 2,
      discount_expiration: 3,
      single_use: 4,
      multi_use: 5,
    }

    {
      ledger: PurchasableItemBlueprint.render_as_hash(ledger_items.sort_by { |li| determination_order[li.determination.to_sym] }),
      division: PurchasableItemBlueprint.render_as_hash(division_items.sort_by { |di| di.configuration['division'] }),
      bowling: PurchasableItemBlueprint.render_as_hash(other_bowling_items),
      banquet: PurchasableItemBlueprint.render_as_hash(banquet),
      product: PurchasableItemBlueprint.render_as_hash(product),
    }
  end
end
