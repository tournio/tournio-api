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
      Time.zone = 'America/New_York'
      self.starting_time = Time.zone.now - 2.weeks
      self.interval = Time.zone.now.to_i - starting_time.to_i
    end

    def perform
      create_and_configure_tournament

      create_contacts
      create_purchasable_items

      create_teams
      create_solo_bowlers

      add_purchases_to_bowlers
      create_payments
    end

    def random_name
      names = [
        'These Punks Are Daft',
        'Big Bowling Fundraiser',
        'Gutterholics Anonymous',
        'No-Tap Generational',
        'Goofball Nationals',
        'IGBO Winter Formal',
        'IGBO Homecoming Invitational',
        'All Classics, No Filler',
        'Unity Fellowship Inclusion',
        'Fashion Faire',
        'Gathering of Avid Geeks',
        'The Quest for 300',
        'ABBA ABBA Do!',
      ]
      name = nil
      begin
        name = names.sample
      end until !Tournament.exists?(name: name)
      name
    end
    
    def create_and_configure_tournament
      location = locations_and_time_zones.sample
      name = random_name
      abbr = name.scan(/[[:upper:]]/).join unless name.nil?
      self.tournament = FactoryBot.create :tournament,
        :active,
        :one_shift,
        # :one_small_shift,
        :with_entry_fee,
        :with_scratch_competition_divisions,
        :with_extra_stuff,
        name: name,
        abbreviation: abbr,
        identifier: "#{abbr.downcase}-#{(Date.today + 90.days).year}",
        location: location[:location],
        timezone: location[:timezone]

      FactoryBot.create :config_item, tournament: tournament, key: 'team_size', value: 4, label: 'Team Size'
      FactoryBot.create :config_item, tournament: tournament, key: 'website', value: 'http://www.tourn.io', label: 'Website'
      FactoryBot.create :stripe_account, tournament: tournament, onboarding_completed_at: 2.months.ago

      image_path = Rails.root.join('spec', 'support', 'images').children.sample
      tournament.logo_image.attach(io: File.open(image_path), filename: 'digital.jpg')

      FactoryBot.create :purchasable_item,
        :early_discount,
        tournament: tournament,
        value: Random.rand(10) + 5,
        configuration: {
          valid_until: 3.days.ago,
        }
      # tournament.purchasable_items.each do |pi|
      #   FactoryBot.create :stripe_product, purchasable_item: pi
      # end
    end

    def create_contacts
      FactoryBot.create :contact, tournament: tournament, email: 'director@igbo-factory.org', name: 'Kylie Minogue', role: :director
      FactoryBot.create :contact, tournament: tournament, email: 'secretary@igbo-factory.org', name: 'Dorothy Gale', role: :secretary
      FactoryBot.create :contact, tournament: tournament, email: 'treasurer@igbo-factory.org', name: 'Stevie Nicks', role: :treasurer
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
          # :with_stripe_product,
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
      count = Random.rand(tournament.team_size) + 1

      place_with_others = count < tournament.team_size ? Random.rand(2) > 0 : false
      team = FactoryBot.create :team,
        tournament: tournament,
        name: team_name,
        options: { place_with_others: place_with_others }

      registration_time = Time.zone.at(starting_time + (interval * Random.rand(1.0)).to_i)
      count.times do |i|
        create_bowler(team: team, position: i + 1, registered_at: registration_time)
      end

      assign_doubles_partners(team: team) unless count == 1
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

      DataPoint.create(
        key: :registration_type,
        value: registration_type,
        tournament_id: tournament.id,
        created_at: registered_at
      )

      TournamentRegistration.purchase_entry_fee(bowler)
      TournamentRegistration.add_early_discount_to_ledger(bowler, registered_at)

      bowler
    end

    # pre-req: team.bowlers.count > 1
    def assign_doubles_partners(team:)
      bowlers = team.bowlers.to_a.shuffle!

      while bowlers.count > 1 do
        b1 = bowlers.shift
        b2 = bowlers.shift
        b1.update(doubles_partner_id: b2.id)
        b2.update(doubles_partner_id: b1.id)
      end
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

    def add_purchases_to_bowlers
      single_items = tournament.purchasable_items.bowling.where(refinement: nil)
      division_items = tournament.purchasable_items.bowling.where(refinement: :division)
      non_bowling_items = tournament.purchasable_items.where.not(category: %i(ledger bowling))

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

        # how about multi_use items?
        count = Random.rand(non_bowling_items.count)
        if (count > 0)
          items_for_bowler += non_bowling_items.sample(count)
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
        # make_payment = Random.rand(3) > 0 # we should have payments about 2/3 of the time
        # create_payment(bowler: b) unless make_payment

        # Let's have payments for all purchases. That reflects current reality.
        create_payment(bowler: b)
      end
    end

    def create_payment(bowler: )
      window = Time.zone.now.to_i - bowler.created_at.to_i
      paid_at = Time.zone.at(bowler.created_at.to_i + (window * Random.rand(1.0)).to_i)

      # No external payments needed, since we're skipping Stripe in development
      #
      # payment = FactoryBot.create :external_payment,
      #   :from_stripe,
      #   tournament: tournament,
      #   created_at: paid_at

      # ledger entry for entry fee (minus early discount)
      purchases = bowler.purchases.unpaid
      # multiplying the discount by 2 since it's included in the first sum, but still need to subtract it
      total = purchases.sum(&:value) - purchases.early_discount.sum(&:value) * 2

      purchases.update_all(paid_at: paid_at)

      # ledger entries for extra purchases
      bowler.ledger_entries << LedgerEntry.new(
        credit: total,
        source: :stripe,
        # identifier: payment.identifier
        identifier: "pretend_payment_#{SecureRandom.uuid}"
      )
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

    def locations_and_time_zones
      @locations ||= [
        {
          location: 'Atlanta, GA',
          timezone: 'America/New_York',
        },
        {
          location: 'Seattle, WA',
          timezone: 'America/Los_Angeles',
        },
        {
          location: 'Honolulu',
          timezone: 'Pacific/Honolulu',
        },
        {
          location: 'Anchorage, AK',
          timezone: 'America/Anchorage',
        },
        {
          location: 'San Diego, CA',
          timezone: 'America/Los_Angeles',
        },
        {
          location: 'Denver, CO',
          timezone: 'America/Denver',
        },
        {
          location: 'Chicago, IL',
          timezone: 'America/Chicago',
        },
        {
          location: 'Austin, TX',
          timezone: 'America/Chicago',
        },
        {
          location: 'Dallas, TX',
          timezone: 'America/Chicago',
        },
        {
          location: 'Fort Lauderdale, FL',
          timezone: 'America/New_York',
        },
        {
          location: 'Phoenix, AZ',
          timezone: 'America/Phoenix',
        },
        {
          location: 'Boston, MA',
          timezone: 'America/New_York',
        },
        {
          location: 'Palm Springs, CA',
          timezone: 'America/Los_Angeles',
        },
        {
          location: 'San Francisco, CA',
          timezone: 'America/Los_Angeles',
        },
        {
          location: 'Nashville, TN',
          timezone: 'America/Chicago',
        },
        {
          location: 'Minneapolis, MN',
          timezone: 'America/Chicago',
        },
      ]
    end
  end
end
