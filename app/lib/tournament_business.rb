# frozen_string_literal: true

module TournamentBusiness
  DEFAULT_TEAM_SIZE = 4

  # Tournament types
  IGBO_STANDARD = 'igbo_standard'
  IGBO_MULTI_SHIFT = 'igbo_multi_shift'
  IGBO_MIX_AND_MATCH = 'igbo_mix_and_match'
  # IGBO_NON_STANDARD = 'igbo_non_standard'

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

  def create_default_config
    self.config_items += [
      ConfigItem.new(key: 'display_capacity', value: 'false', label: 'Display Capacity'),
      ConfigItem.new(key: 'publicly_listed', value: 'true', label: 'Publicly Listed'), # applies to tournaments in the "active" state
      ConfigItem.new(key: 'accept_payments', value: 'true', label: 'Accept Payments'),
      ConfigItem.new(key: 'automatic_discount_voids', value: 'false', label: 'Automatically Void Early Discounts'),
      ConfigItem.new(key: 'automatic_late_fees', value: 'false', label: 'Automatically Charge Unpaid Bowlers the Late Fee'),
      ConfigItem.new(key: 'website', value: '', label: 'Website'),
      ConfigItem.new(key: 'stripe_receipts', value: 'true', label: 'Send Receipt Emails'),
      ConfigItem.new(key:'tournament_type', value: IGBO_STANDARD, label: 'Tournament Type'),
    ]

    if Rails.env.development?
      self.config_items += [
        ConfigItem.new(key: 'email_in_dev', value: 'false', label: '[dev] Send Emails'),
        ConfigItem.new(key: 'skip_stripe', value: 'true', label: 'Skip Stripe'),
      ]
    end
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

  def partial
    teams.where(id: Team.where(id: Team.left_outer_joins(:bowlers).distinct.where(tournament_id: id)
                                       .select('teams.id, COUNT(bowlers.team_id) AS bowlers_count')
                                       .group('teams.id')
                                       .having('COUNT(bowlers.team_id) < ?', team_size)
                                       .pluck(:id))
    )
  end

  def room_for_one_more?(team)
    partial.include?(team)
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
