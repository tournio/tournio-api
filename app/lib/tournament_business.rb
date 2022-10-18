# frozen_string_literal: true

module TournamentBusiness
  DEFAULT_TEAM_SIZE = 4

  def entry_fee
    purchasable_items.entry_fee.first.value
  end

  def display_name
    "#{name} (#{year})"
  end

  def igbots_hash
  end

  def team_size
    config[:team_size] || DEFAULT_TEAM_SIZE
  end

  def max_bowlers_per_entry
    team_size
  end

  # This will allow us to change it later when it becomes a config item
  def currency
    'usd'
  end

  def config
    @config ||= TournamentConfig.new(config_items)
  end

  def late_fee_applies_at
    # Using &. because there may not be a late_fee item
    pi = purchasable_items.late_fee&.first
    return unless pi.present?
    timestamp = pi.configuration['applies_at']
    DateTime.parse(timestamp)
  end

  def early_registration_ends
    # Using &. because there may not be an early_discount item
    pi = purchasable_items.early_discount&.first
    return unless pi.present?
    timestamp = pi.configuration['valid_until']
    DateTime.parse(timestamp)
  end

  def available_to_join
    teams.where(id: Team.where(id: Team.left_outer_joins(:bowlers).distinct.where(tournament_id: id)
                                       .select('teams.id, COUNT(bowlers.team_id) AS bowlers_count')
                                       .group('teams.id')
                                       .having('COUNT(bowlers.team_id) < ?', team_size)
                                       .pluck(:id))
    )
  end

  def room_for_one_more?(team)
    available_to_join.include?(team)
  end

  def in_early_registration?(current_time = Time.zone.now)
    if (demo? || testing?) && testing_environment
      testing_environment.conditions['registration_period'] == TestingEnvironment::EARLY_REGISTRATION
    else
      end_time = early_registration_ends
      end_time.present? && current_time < end_time
    end
  end

  # Different events in the same tournament shouldn't have different applies_at times, but there's
  # nothing stopping it from happening at the moment...
  def in_late_registration?(current_time: Time.zone.now, event_linked_late_fee: nil)
    if (demo? || testing?) && testing_environment
      testing_environment.conditions['registration_period'] == TestingEnvironment::LATE_REGISTRATION
    elsif event_linked_late_fee.present?
      effective_time = event_linked_late_fee.configuration['applies_at']
      effective_time.present? && current_time > effective_time
    else
      effective_time = late_fee_applies_at
      effective_time.present? && current_time > effective_time
    end
  end
end
