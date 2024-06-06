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
      self.interval = 2.weeks.to_i
    end

    def perform
      create_and_configure_tournament

      create_contacts
      create_optional_bowling_items
      create_scratch_division_items

      # Create non-bowling purchasable items

      # Need to limit these based on tournanent type
      # create_teams
      # create_solo_bowlers

      # At this point, all signups are created, and ready for use

      tournament.reload.bowlers.each do |bowler|
        window = Time.zone.now.to_i - bowler.created_at.to_i
        paid_at = Time.zone.at(bowler.created_at.to_i + (window * Random.rand(1.0)).to_i)

        # 33% chance: Create some unpaid signups
        # 33% chance: Create some paid ones, with purchases to go along with
        # 33% chance: nothing
        signup_decision = Random.rand(3)
        if signup_decision == 1
          sign_bowler_up_for_some(bowler: bowler)
        elsif signup_decision == 2
          purchase_some_signupables(bowler: bowler, paid_at: paid_at)
        end

        # 50% chance: Create some purchases of non-bowling extras
        extra_decision = Random.rand(2)
        if extra_decision == 1
          purchase_some_extras(bowler: bowler, paid_at: paid_at)
        end

        # 50% chance: Pay entry fee
        entry_fee_decision = Random.rand(2)
        if entry_fee_decision == 1
          purchase_entry_fee(bowler: bowler, paid_at: paid_at)
        end

        pay_off_balance(bowler: bowler, paid_at: paid_at)
      end

      ap "Tournament: #{tournament.name}"
      ap "Bowlers: #{tournament.bowlers.count}"
      ap "Teams: #{tournament.teams.count}"
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
        'Totally Invitational Tournament of Scotland',
        'Big Old Online Bowling Seminar',
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
      org = TournamentOrg.all.sample

      self.tournament = FactoryBot.create :one_shift_standard_tournament,
      # self.tournament = FactoryBot.create :two_shift_standard_tournament,
      # self.tournament = FactoryBot.create :mix_and_match_standard_tournament,
      # self.tournament = FactoryBot.create :one_shift_singles_tournament,
      # self.tournament = FactoryBot.create :two_shift_singles_tournament,
      #   :active,
        :testing,
        :with_entry_fee,
        :with_extra_stuff, # creates banquet and raffle ticket bundle
        name: name,
        abbreviation: abbr,
        start_date: Date.today + 120.days,
        end_date: Date.today + 122.days,
        entry_deadline: Date.today + 110.days,
        year: (Date.today + 120.days).year,
        identifier: "#{abbr.downcase}-#{(Date.today + 120.days).year}",
        location: location[:location],
        timezone: location[:timezone],
        tournament_org: org

      extended_fields = ExtendedFormField.where(name: %w(comment pronouns standings_link))
      extended_fields.each_with_index do |extended_field, i|
        FactoryBot.create(:additional_question,
          extended_form_field: extended_field,
          tournament: tournament,
          order: i + 1,
          validation_rules: {}
        )
      end

      # set form fields to include DOB and city
      tournament.config_items.find_by_key('bowler_form_fields').update(value: 'usbc_id date_of_birth city')

      image_path = Rails.root.join('spec', 'support', 'images').children.sample
      tournament.logo_image.attach(io: File.open(image_path), filename: 'digital.jpg')
    end

    def create_contacts
      FactoryBot.create :contact, tournament: tournament, email: 'director@igbo-factory.org', name: 'Kylie Minogue', role: :director
      FactoryBot.create :contact, tournament: tournament, email: 'secretary@igbo-factory.org', name: 'Dorothy Gale', role: :secretary
      FactoryBot.create :contact, tournament: tournament, email: 'treasurer@igbo-factory.org', name: 'Stevie Nicks', role: :treasurer
    end

    def create_optional_bowling_items
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

    def create_scratch_division_items
      params = [
        {
          value: 60,
          configuration: { division: 'Alpha', note: '205+', order: 1 },
        },
        {
          value: 55,
          configuration: { division: 'Bravo', note: '190-204', order: 2 },
        },
        {
          value: 50,
          configuration: { division: 'Charlie', note: '175-189', order: 3 },
        },
        {
          value: 45,
          configuration: { division: 'Delta', note: '160-174', order: 4 },
        },
        {
          value: 40,
          configuration: { division: 'Echo', note: 'up to 159', order: 5 },
        },
      ]

      params.each do |p|
        FactoryBot.create :purchasable_item,
          :scratch_competition,
          tournament: tournament,
          **p
      end
    end

    def create_teams
      return unless tournament.events.team.any?

      tournament.shifts.each do |shift|
        max_teams = shift.capacity
        min_teams = max_teams - 15
        teams_to_create = min_teams + Random.rand(11)

        teams_to_create.times do |i|
          create_team(shifts: [shift])
        end
      end
    end

    def create_team(shifts:)
      self.team_sequence += 1
      team_name = "Team #{team_sequence}"
      count = Random.rand(tournament.team_size) + 1

      place_with_others = count < tournament.team_size ? Random.rand(2) > 0 : false
      team = FactoryBot.create :team,
        tournament: tournament,
        name: team_name,
        options: { place_with_others: place_with_others },
        shifts: shifts

      registration_time = Time.zone.at(starting_time + (interval * Random.rand(1.0)).to_i)
      count.times do |i|
        create_bowler(team: team, position: i + 1, registered_at: registration_time)
      end

      assign_doubles_partners(team: team) unless count == 1
    end

    def create_bowler (team: nil, position: nil, registration_type: 'new_team', registered_at:, shifts: [])
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
        created_at: registered_at,
        shifts: shifts

      DataPoint.create(
        key: :registration_type,
        value: registration_type,
        tournament_id: tournament.id,
        created_at: registered_at
      )

      tournament.purchasable_items.bowling.each do |pi|
        Signup.create(
          bowler: bowler,
          purchasable_item: pi
        )
      end

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
      tournament.shifts.each do |shift|
        minimum = 15
        remaining_capacity = shift.capacity
        if tournament.events.team.any?
          minimum = 0
          remaining_capacity =
            (shift.capacity - shift.teams.count) * tournament.team_size
        end

        return unless remaining_capacity.positive?

        r = Random.rand(remaining_capacity)
        solo_bowler_quantity = minimum > r ? minimum : r
        solo_bowler_quantity.times do |i|
          registration_time = Time.zone.at(starting_time + (interval * Random.rand(1.0)).to_i)
          create_bowler(registered_at: registration_time, registration_type: 'solo', shifts: [shift])
        end
      end
    end

    def sign_bowler_up_for_some(bowler:)
      bowler.signups.each do |signup|
        # First, make sure we aren't signing up for the same event in a different division
        division_items = tournament.purchasable_items.division
        signed_up = bowler.signups.requested.where(purchasable_item: division_items)
        if signed_up.any?
          next
        end

        # Flip a coin to decide whether to request this one
        yes = Random.rand(2) > 0
        if yes
          signup.request!
        end
      end
    end

    def purchase_some_signupables(bowler:, paid_at:)
      bowler.signups.each do |signup|
        # First, make sure we aren't paying for the same event in a different division
        division_items = tournament.purchasable_items.division
        signed_up = bowler.signups.paid.where(purchasable_item: division_items)
        if signed_up.any?
          next
        end

        yes = Random.rand(2) > 0
        if yes
          signup.pay!

          # create a purchase and a payment (easier that way)
          pi = signup.purchasable_item
          FactoryBot.create(:purchase,
            :paid,
            bowler: bowler,
            purchasable_item: pi,
            amount: pi.value,
            paid_at: paid_at
          )
          bowler.ledger_entries << LedgerEntry.new(
            debit: pi.value,
            source: :purchase,
            identifier: pi.name,
            created_at: paid_at
          )
        end
      end
    end

    def purchase_some_extras(bowler:, paid_at:)
      eligible_items = tournament.purchasable_items.where(category: %i(banquet product sanction raffle bracket))
      eligible_items.each do |pi|
        yes = Random.rand(2) > 0
        if yes
          bowler.purchases << Purchase.new(
            purchasable_item: pi,
            amount: pi.value,
            paid_at: paid_at
          )
          bowler.ledger_entries << LedgerEntry.new(
            debit: pi.value,
            source: :purchase,
            identifier: pi.name,
            created_at: paid_at
          )
        end
      end
    end

    def purchase_entry_fee(bowler:, paid_at:)
      entry_fee_item = tournament.purchasable_items.entry_fee.first
      bowler.purchases << Purchase.new(
        purchasable_item: entry_fee_item,
        amount: entry_fee_item.value,
        paid_at: paid_at
      )
      bowler.ledger_entries << LedgerEntry.new(
        debit: entry_fee_item.value,
        source: :purchase,
        identifier: entry_fee_item.name,
        created_at: paid_at
      )
    end

    def pay_off_balance(bowler:, paid_at:)
      amount = bowler.purchases.sum(&:amount)
      bowler.ledger_entries << LedgerEntry.new(
        credit: amount,
        source: :stripe,
        created_at: paid_at,
        identifier: "Payment: pretend_#{SecureRandom.alphanumeric(5)}"
      ) unless amount == 0
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
