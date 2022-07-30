require 'factory_bot'

module Fixtures
  class TournamentGenerator
    include Sidekiq::Job

    attr_accessor :tournament,
      :email_sequence,
      :team_sequence,
      :person_first_names,
      :person_surnames,
      :starting_time,
      :interval,
      :usbc_sequence

    def initialize
      super
      self.email_sequence = 0
      self.team_sequence = 0
      self.usbc_sequence = 100
      Time.zone = 'America/Chicago'
      self.starting_time = Time.zone.now - 2.weeks
      self.interval = Time.zone.now.to_i - starting_time.to_i
    end

    def perform
      t = FactoryBot.create :tournament,
        :active,
        :one_shift,
        # :one_small_shift,
        :with_entry_fee,
        :with_scratch_competition_divisions,
        :with_extra_stuff,
        name: 'Random Access Tournament',
        start_date: Time.zone.today + 30,
        year: (Time.zone.today + 30).year
      self.tournament = t

      FactoryBot.create :config_item, tournament: t, key: 'team_size', value: 4
      FactoryBot.create :config_item, tournament: t, key: 'image_path', value: '/images/retro_pins.jpg'
      FactoryBot.create :config_item, tournament: t, key: 'time_zone', value: 'America/Chicago'
      FactoryBot.create :stripe_account, tournament: t, onboarding_completed_at: 2.months.ago
      FactoryBot.create :purchasable_item,
        :early_discount,
        :with_stripe_coupon,
        tournament: t,
        value: Random.rand(10) + 5,
        configuration: {
          valid_until: 3.days.ago,
        }
      t.purchasable_items.each do |pi|
        FactoryBot.create :stripe_product, purchasable_item: pi
      end

      create_contacts
      create_purchasable_items

      create_teams
      create_solo_bowlers
      create_joining_bowlers

      add_purchases_to_bowlers
      create_payments
    end

    def create_contacts
      FactoryBot.create :contact, tournament: tournament, display_order: 1, email: 'director@igbo-factory.org', name: 'Director Person', role: :director
      FactoryBot.create :contact, tournament: tournament, display_order: 2, email: 'secretary@igbo-factory.org', name: 'Secretary Person', role: :secretary
      FactoryBot.create :contact, tournament: tournament, display_order: 3, email: 'treasurer@igbo-factory.org', name: 'Treasurer Person', role: :treasurer
    end

    def create_purchasable_items
      items = [
        {
          name: 'Mystery Doubles',
        },
        {
          name: 'Best 3 of 9',
        },
        {
          name: 'Optional Scratch',
        },
        {
          name: 'Optional Handicap',
        },
      ]

      items.each_with_index do |item, index|
        FactoryBot.create :purchasable_item,
          :optional_event,
          :with_stripe_product,
          tournament: tournament,
          name: item[:name],
          value: Random.rand(15) + 10,
          configuration: { order: index + 1 }
      end
    end

    def create_teams
      max_teams = tournament.shifts.first.capacity / tournament.team_size
      min_teams = max_teams - 15
      teams_to_create = min_teams + Random.rand(11)
      # teams_to_create = tournament.shifts.first.capacity / tournament.team_size
      teams_to_create.times do |i|
        create_team
      end
    end

    def create_team
      self.team_sequence += 1
      team_name = "Team #{team_sequence}"
      team = FactoryBot.create :team, tournament: tournament, name: team_name
      count = Random.rand(tournament.team_size) + 1
      # count = tournament.team_size

      registration_time = Time.zone.at(starting_time + (interval * Random.rand(1.0)).to_i)
      count.times do |i|
        create_bowler(team: team, position: i + 1, registered_at: registration_time)
      end
    end

    def create_bowler (team: nil, position: nil, registration_type: 'new_team', registered_at: )
      first_name_index = Random.rand(100)
      surname_index = Random.rand(100)
      usbc_id = "111-#{usbc_sequence}"
      self.usbc_sequence += 1
      person = FactoryBot.create :person,
        first_name: person_first_names[first_name_index],
        last_name: person_surnames[surname_index],
        email: email_address,
        usbc_id: usbc_id
      bowler = FactoryBot.create :bowler,
        tournament: tournament,
        team: team,
        position: position,
        person: person,
        created_at: registered_at
      FactoryBot.create :bowler_shift, bowler: bowler, shift: tournament.shifts.first

      DataPoint.create(
        key: :registration_type,
        value: registration_type,
        tournament_id: tournament.id,
        created_at: registered_at
      )

      TournamentRegistration.purchase_entry_fee(bowler)
      TournamentRegistration.add_early_discount_to_ledger(bowler, registered_at)
    end

    def create_solo_bowlers
      remaining_capacity = tournament.shifts.first.capacity - tournament.bowlers.count
      return unless remaining_capacity.positive?

      solo_bowler_quantity = Random.rand(remaining_capacity)
      solo_bowler_quantity.times do |i|
        registration_time = Time.zone.at(starting_time + (interval * Random.rand(1.0)).to_i)
        create_bowler(registered_at: registration_time, registration_type: 'solo')
      end
    end

    def create_joining_bowlers
      remaining_capacity = tournament.shifts.first.capacity - tournament.bowlers.count
      return unless remaining_capacity.positive?

      joining_bowler_quantity = Random.rand(remaining_capacity)
      joining_bowler_quantity.times do |i|
        unless tournament.available_to_join.empty?
          team = tournament.available_to_join.sample
          registration_time = Time.zone.at(starting_time + (interval * Random.rand(1.0)).to_i)
          create_bowler(
            team: team,
            position: team.bowlers.count,
            registered_at: registration_time,
            registration_type: 'join_team'
          )
        end
      end
    end

    def add_purchases_to_bowlers
      single_items = tournament.purchasable_items.bowling.where(refinement: nil)
      division_items = tournament.purchasable_items.bowling.where(refinement: :division)

      tournament.bowlers.each do |b|
        items_for_bowler = []
        # do they want a division item?
        index = Random.rand(division_items.count)
        if index > 0
          items_for_bowler << division_items.sample
        end

        # which of the single items do they want?
        count = Random.rand(single_items.count)
        if count > 0
          items_for_bowler += single_items.sample(count)
        end

        add_purchases_to_bowler(bowler: b, items: items_for_bowler) unless items_for_bowler.empty?
      end
    end

    def add_purchases_to_bowler(bowler:, items:)
      items.each do |item|
        FactoryBot.create :purchase,
          purchasable_item: item,
          bowler: bowler,
          amount: item.value

        bowler.ledger_entries << LedgerEntry.new(
          debit: item.value,
          source: :purchase,
          identifier: item.name
        )
      end
    end

    def create_payments
      tournament.bowlers.each do |b|
        make_payment = Random.rand(3) > 0 # we should have payments about 2/3 of the time
        create_payment(bowler: b) unless make_payment
      end
    end

    def create_payment(bowler: )
      window = Time.zone.now.to_i - bowler.created_at.to_i
      paid_at = Time.zone.at(bowler.created_at.to_i + (window * Random.rand(1.0)).to_i)

      payment = FactoryBot.create :external_payment,
        :from_stripe,
        tournament: tournament,
        created_at: paid_at

      # ledger entry for entry fee (minus early discount)
      purchases = bowler.purchases.unpaid
      # multiplying the discount by 2 since it's included in the first sum, but still need to subtract it
      total = purchases.sum(&:value) - purchases.early_discount.sum(&:value) * 2

      purchases.update_all(paid_at: paid_at)

      # ledger entries for extra purchases
      bowler.ledger_entries << LedgerEntry.new(
        credit: total,
        source: :stripe,
        identifier: payment.identifier
      )

      TournamentRegistration.try_confirming_bowler_shift(bowler)
    end

    def person_first_names
      @person_first_names ||= %w(Olivia Emma Amelia Ava Sophia Isabella Luna Mia Charlotte Evelyn Harper Aurora Scarlett Ella Gianna Nova Aria Mila Sofia Ellie Violet Willow Layla Camila Lily Hazel Avery Chloe Penelope Elena Eliana Isla Eleanor Elizabeth Abigail Riley Nora Ivy Paisley Grace Emily Stella Zoey Emilia Maya Everly Leilani Athena Naomi Kinsley Noah Liam Oliver Gold Elijah Lucas Mateo Levi Asher Ethan Luca Grayson James Leo Ezra Aiden Benjamin Wyatt Henry Sebastian Owen Jackson Daniel Mason Jack Alexander Hudson Kai Gabriel Carter Muhammad William Maverick Logan Michael Samuel Ezekiel Jayden Luke Lincoln Josiah Theo David Elias Jacob Julian Waylon Theodore Matthew John)
    end

    def person_surnames
      @person_surnames ||= %w(Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez Hernandez Lopez Gonzales Wilson Anderson Thomas Taylor Moore Jackson Martin Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson Walker Young Allen King Wright Scott Torres Nguyen Hill Flores Green Adams Nelson Baker Hall Rivera Campbell Mitchell Carter Roberts Gomez Phillips Evans Turner Diaz Parker Cruz Edwards Collins Reyes Stewart Morris Morales Murphy Cook Rogers Gutierrez Ortiz Morgan Cooper Peterson Bailey Reed Kelly Howard Ramos Kim Cox Ward Richardson Watson Brooks Chavez Wood James Bennet Gray Mendoza Ruiz Hughes Price Alvarez Castillo Sanders Patel Myers Long Ross Foster Jimenez)
    end

    def email_address
      self.email_sequence += 1
      "bowler_#{email_sequence}@example.org"
    end
  end
end
