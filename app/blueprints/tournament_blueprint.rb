# frozen_string_literal: true

class TournamentBlueprint < Blueprinter::Base
  identifier :identifier

  fields :name, :year

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

    field :additional_questions do |t, _|
      t.additional_questions.order(:order).each_with_object({}) { |aq, obj| obj[aq.name] = AdditionalQuestionBlueprint.render_as_hash(aq) }
    end

    association :testing_environment, blueprint: TestingEnvironmentBlueprint, if: ->(_field_name, tournament, options) { tournament.testing? }
    field :registration_deadline do |t, _|
      datetime_with_timezone(t.config['entry_deadline'], t)
    end
    field :early_registration_ends do |t, _|
      t.early_registration_ends.present? ? datetime_with_timezone(t.early_registration_ends, t) : nil
    end
    field :image_path do |t, _|
      t.config[:image_path]
    end
    field :website do |t, _|
      t.config[:website]
    end
    field :max_bowlers_per_entry, name: :max_bowlers
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
    association :purchasable_items, blueprint: PurchasableItemBlueprint
    association :testing_environment, blueprint: TestingEnvironmentBlueprint

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

    field :bowler_count do |t, _|
      t.bowlers.count
    end

    field :team_count do |t, _|
      t.teams.count
    end

    field :free_entry_count do |t, _|
      t.free_entries.count
    end
  end

  private

  def self.datetime_with_timezone(datetime, tournament)
    return unless datetime.present?
    time_zone = tournament.config[:time_zone]
    datetime.in_time_zone(time_zone).strftime('%b %-d, %Y %l:%M%P %Z')
  end
end
