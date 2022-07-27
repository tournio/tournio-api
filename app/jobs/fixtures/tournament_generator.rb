require 'factory_bot'

module Fixtures
  class TournamentGenerator
    include Sidekiq::Job

    MAX_TEAMS = 40
    MIN_TEAMS = 30

    attr_accessor :tournament,
      :email_sequence,
      :team_sequence,
      :person_first_names,
      :person_surnames

    def initialize
      super
      self.email_sequence = 0
      self.team_sequence = 0
    end

    def perform
      t = FactoryBot.create :tournament,
        :active,
        :one_shift,
        :with_entry_fee,
        :with_scratch_competition_divisions,
        :with_extra_stuff,
        start_date: Date.today + 30.days,
        year: (Date.today + 30.days).year
      self.tournament = t

      FactoryBot.create :config_item, tournament: t, key: 'team_size', value: 4
      FactoryBot.create :config_item, tournament: t, key: 'image_path', value: '/images/retro_pins.jpg'
      FactoryBot.create :stripe_account, tournament: t, onboarding_completed_at: 2.months.ago
      FactoryBot.create :purchasable_item,
        :early_discount,
        :with_stripe_coupon,
        tournament: t,
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
      teams_to_create = MIN_TEAMS + Random.rand(MAX_TEAMS - MIN_TEAMS)
      teams_to_create.times do |i|
        create_team
      end
    end

    def create_team
      self.team_sequence += 1
      team_name = "Team #{team_sequence}"
      team = FactoryBot.create :team, tournament: tournament, name: team_name
      count = Random.rand(tournament.team_size) + 1
      count.times do |i|
        create_bowler(team: team, position: i + 1)
      end
    end

    def create_bowler (team: nil, position: nil)
      first_name_index = Random.rand(100)
      surname_index = Random.rand(100)
      person = FactoryBot.create :person,
        first_name: person_first_names[first_name_index],
        last_name: person_surnames[surname_index],
        email: email_address
      bowler = FactoryBot.create :bowler, tournament: tournament, team: team, position: position, person: person
      FactoryBot.create :bowler_shift, bowler: bowler, shift: tournament.shifts.first
      TournamentRegistration.purchase_entry_fee(bowler)
      # TournamentRegistration.add_early_discount_to_ledger(bowler, registered_at)
    end

    def create_solo_bowlers
      remaining_capacity = MAX_TEAMS * tournament.team_size - tournament.bowlers.count
      return unless remaining_capacity.positive?

      solo_bowler_quantity = Random.rand(remaining_capacity)
      solo_bowler_quantity.times do |i|
        create_bowler
      end
    end

    def create_joining_bowlers
      remaining_capacity = MAX_TEAMS * tournament.team_size - tournament.bowlers.count
      return unless remaining_capacity.positive?

      joining_bowler_quantity = Random.rand(remaining_capacity)
      joining_bowler_quantity.times do |i|
        unless tournament.available_to_join.empty?
          team = tournament.available_to_join.sample
          create_bowler(team: team, position: team.bowlers.count)
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
      # paid_at = Random.rand(2) > 0 ? create_payment(...).created_at : nil
      items.each do |item|
        FactoryBot.create :purchase,
          purchasable_item: item,
          bowler: bowler,
          amount: item.value
          # paid_at: paid_at

        bowler.ledger_entries << LedgerEntry.new(
          debit: item.value,
          source: :purchase,
          identifier: item.name
        )
      end
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
