# frozen_string_literal: true

module DirectorUtilities
  def self.clear_test_data(tournament:)
    return unless tournament.testing? || tournament.demo?

    tournament.teams.destroy_all
    tournament.reload.bowlers.destroy_all
    tournament.free_entries.destroy_all
    tournament.data_points.destroy_all
  end

  def self.reassign_bowler(bowler:, to_team:)
    tournament = bowler.tournament
    team_size_cap = tournament.team_size

    return false unless to_team.bowlers.count < team_size_cap

    # remove their original doubles-partner connection
    original_partner = bowler.doubles_partner
    if original_partner.present?
      original_partner.update(doubles_partner_id: nil)
      bowler.update(doubles_partner: nil)
    end

    # link up doubles partner, if someone on the destination team doesn't have one already
    new_partner = to_team.bowlers.where(doubles_partner_id: nil).first
    if new_partner.present?
      bowler.update(doubles_partner: new_partner)
      new_partner.update(doubles_partner: bowler)
    end

    # assign their position
    new_position = (to_team.bowlers.collect(&:position).max || 0) + 1
    bowler.update(position: new_position)

    # put them on the new team
    bowler.update(team: to_team)
  end

  def self.assign_partner(bowler: , new_partner:)
    tournament = bowler.tournament
    return unless tournament.purchasable_items.event.double.any?

    original_partner = bowler.doubles_partner
    if (original_partner.present?)
      original_partner.update(doubles_partner_id: nil)
    end

    bowler.update(doubles_partner: new_partner)
    new_partner.update(doubles_partner: bowler)
  end

  def self.igbots_hash(tournament:)
    {
      peoples: igbots_people(tournament: tournament),
    }
  end

  # <ID>SFGG2015-THATR109A1</ID>
  #
  # <LAST_NAME>THATCHER</LAST_NAME>
  # <FIRST_NAME>RUSS</FIRST_NAME>
  # <MIDDLE_INITIAL></MIDDLE_INITIAL>
  # <SUFFIX></SUFFIX>
  # <NICKNAME>RUSS</NICKNAME>
  #
  # <BIRTH_DAY>15</BIRTH_DAY>
  # <BIRTH_MONTH>04</BIRTH_MONTH>
  #
  # <ADDRESS1>4510 GREGORY WAY</ADDRESS1>
  # <ADDRESS2></ADDRESS2>
  # <CITY>EL SOBRANTE</CITY>
  # <STATE>CA</STATE>
  # <PROVINCE></PROVINCE>
  # <COUNTRY>USA</COUNTRY>
  # <POSTAL_CODE>94803</POSTAL_CODE>
  # <PHONE1>5207800212</PHONE1>
  # <PHONE2>5109647197</PHONE2>
  # <EMAIL>azbearcub@msn.com</EMAIL>
  #
  # <USBC_NUMBER>9005-22099</USBC_NUMBER>
  # <IGBOTSID>TR-6784</IGBOTSID>
  # <DATE_REGISTERED>01/07/2015</DATE_REGISTERED>
  #
  # <BOOK_AVERAGE games="153" verified="">211</BOOK_AVERAGE>
  # <CURRENT_AVERAGE games="39" verified="">202</CURRENT_AVERAGE>
  # <IGBO_AVERAGE games="70" verified="">202</IGBO_AVERAGE>
  # <EXTRA_AVERAGE_1 games="0" verified="">0</EXTRA_AVERAGE_1>
  # <EXTRA_AVERAGE_2 games="0" verified="">0</EXTRA_AVERAGE_2>
  #
  # <LEAGUE_NAME>Bay Alarm 805</LEAGUE_NAME>
  # <LEAGUE_CITY_STATE></LEAGUE_CITY_STATE>
  # <SECRETARY_NAME>Mike Richards</SECRETARY_NAME>
  # <SECRETARY_PHONE>510-526-8818</SECRETARY_PHONE>
  # <SECRETARY_EMAIL></SECRETARY_EMAIL>
  #
  # <TEAM_ID>SFGG2015-THATR109</TEAM_ID>
  # <TEAM_CAPTAIN>YES</TEAM_CAPTAIN>
  # <TEAM_NUMBER></TEAM_NUMBER>
  # <TEAM_NAME>THEY HATE US CAUSE THEY AINT US</TEAM_NAME>
  # <TEAM_ORDER>1</TEAM_ORDER>
  #
  # <DOUBLES_EXTERNAL_ID></DOUBLES_EXTERNAL_ID>
  # <DOUBLES_LAST_NAME></DOUBLES_LAST_NAME>
  # <DOUBLES_FIRST_NAME></DOUBLES_FIRST_NAME>
  # <DOUBLES_MIDDLE_INITIAL></DOUBLES_MIDDLE_INITIAL>
  # <DOUBLES_SUFFIX></DOUBLES_SUFFIX>
  # <DOUBLES_BIRTH_DAY></DOUBLES_BIRTH_DAY>
  # <DOUBLES_BIRTH_MONTH></DOUBLES_BIRTH_MONTH>

  def self.igbots_people(tournament:)
    tournament.bowlers.collect do |bowler|
      t = bowler&.team
      team_deets = if t.present?
                     team_export(bowler: bowler)
                   else
                     {}
                   end
      d = bowler.doubles_partner
      doubles_deets = if d.present?
                        doubles_partner_info(partner: d)
                      else
                        {}
                      end

      bowler_export(bowler: bowler).merge(team_deets).merge(doubles_deets)
    end
  end

  def self.bowler_export(bowler:)
    {
      id: bowler_identifier(bowler),

      last_name: bowler.last_name,
      first_name: bowler.first_name,
      nickname: bowler.nickname.present? ? bowler.nickname : '',

      birth_day: bowler.birth_day,
      birth_month: bowler.birth_month,
      birth_year: bowler.birth_year,

      address1: bowler.address1,
      address2: bowler.address2.present? ? bowler.address2 : '',
      city: bowler.city,
      state: bowler.state,
      country: bowler.country,
      postal_code: bowler.postal_code,
      phone1: bowler.phone,
      email: bowler.email,

      usbc_number: bowler.usbc_id,
      average: bowler.verified_data['verified_average'] || '',
      handicap: bowler.verified_data['handicap'],
    }
  end

  def self.doubles_partner_info(partner:, name_only: false)
    deets = {
      doubles_last_name: partner&.last_name,
      doubles_first_name: partner&.first_name,
    }
    unless name_only
      deets.merge!(
        doubles_external_id: bowler_identifier(partner),
        doubles_birth_day: partner&.birth_day,
        doubles_birth_month: partner&.birth_month,
      )
    end
    deets
  end

  def self.team_export(bowler:)
    team = bowler.team
    if team.present?
      {
        team_id: team.id, # team.identifier,
        team_name: team.name,
        team_order: bowler.position,
        preferred_shift: team.shifts.collect(&:name).join(', '),
      }
    else
      {
        team_id: 'n/a',
        team_name: 'n/a',
        team_order: 'n/a',
        preferred_shift: 'n/a',
      }
    end
  end

  def self.csv_hash(tournament:)
    require 'csv'

    csv_data = csv_bowlers(tournament: tournament)

    headers = csv_data.first.keys
    people = csv_data.map(&:values)

    CSV.generate do |csv|
      csv << headers
      people.each { |p| csv << p }
    end
  end

  def self.csv_bowlers(tournament:)
    tournament.bowlers.collect do |bowler|
      team_deets = team_export(bowler: bowler)
      d = bowler.doubles_partner
      doubles_deets = doubles_partner_info(partner: d, name_only: true)
      bowler_data = bowler_export(bowler: bowler)

      # CSV wants phone, not phone1, which is what the IGBOTS export wants
      bowler_data[:phone] = bowler_data.delete(:phone1)

      bowler_data.merge(team_deets).merge(doubles_deets).merge(csv_specific_data(bowler: bowler))
    end
  end

  def self.csv_specific_data(bowler:)
    t = bowler.tournament
    timezone = t.present? ? t.timezone : 'America/Los_Angeles'
    {
      entry_fee_paid: bowler.purchases.entry_fee.first&.paid_at.present? ? 'Y' : 'N',
      registered_at: bowler.created_at.in_time_zone(timezone).strftime('%Y %b %-d %l:%M%P %Z'),
    }.merge(csv_additional_questions(bowler: bowler))
      .merge(csv_purchases(bowler: bowler))
  end

  def self.csv_purchases(bowler:)
    t = bowler.tournament
    pi = t.purchasable_items.division
    purchased_item_identifiers = bowler.purchases.collect { |p| p.purchasable_item.identifier }

    # put the division-based items in alphabetical order first
    division_items = pi.sort do |a,b|
      if a.name == b.name
        a.configuration["division"] <=> b.configuration["division"]
      else
        a.name <=> b.name
      end
    end

    # put them in a hash, marking the purchased one with X
    output = division_items.each_with_object({}) do |item, result|
      signed_up_key = "Signed up: #{item.name}: #{item.configuration['division']}"
      paid_key = "Paid: #{item.name}: #{item.configuration['division']}"

      signup = bowler.signups.find_by_purchasable_item_id(item.id)
      result[signed_up_key] = signup.requested? || signup.paid? ? 'X' : ''
      result[paid_key] = purchased_item_identifiers.include?(item.identifier) ? 'X' : ''
    end

    # put the remaining optional items in alphabetical order
    optional_items = (t.purchasable_items.bowling - division_items).sort

    # mark the purchased ones with an X in the result
    optional_items.each do |item|
      signed_up_key = "Signed up: #{item.name}"
      signup = bowler.signups.find_by_purchasable_item_id(item.id)
      output[signed_up_key] = signup.requested? || signup.paid? ? 'X' : ''
      paid_key = "Paid: #{item.name}"
      output[paid_key] = if purchased_item_identifiers.include?(item.identifier)
                           item.single_use? ? 'X' : purchased_item_identifiers.count(item.identifier)
                         else
                           ''
                         end
    end

    # Add multi-use items, with the number of each
    multiuse_items = t.purchasable_items - t.purchasable_items.bowling - t.purchasable_items.one_time - t.purchasable_items.apparel
    multiuse_items.each do |item|
      key = item.name
      quantity = purchased_item_identifiers.count(item.identifier)
      output[key] = quantity > 0 ? quantity : ''
    end

    # any sanction items, such as IGBO membership
    sanction_items = t.purchasable_items.sanction
    sanction_items.each do |item|
      key = item.name
      output[key] = purchased_item_identifiers.include?(item.identifier) ? 'X' : ''
    end

    # Now for the apparel items: include the size and quantity of each
    apparel_items = t.purchasable_items.apparel
    apparel_output = {}
    apparel_items.each do |item|
      key = item.name
      unless apparel_output[key].present?
        apparel_output[key] = []
      end

      size = item.configuration['size']
      quantity = purchased_item_identifiers.count(item.identifier)

      if quantity > 0
        apparel_output[key] << "#{ApparelDetails.humanize_size(size)} (#{quantity})"
      end
    end
    apparel_output.each_pair do |key, counts|
      output[key] = counts.join('; ')
    end

    # et voila!
    output
  end

  def self.bowler_identifier(bowler)
    bowler.identifier
  end

  def self.csv_additional_questions(bowler:)
    t = bowler.tournament
    responses = bowler.additional_question_responses.index_by(&:extended_form_field_id)
    aqs = t.additional_questions.order(:order)
    aqs.each_with_object({}) do |aq, result|
      key = aq.name
      response = responses[aq.extended_form_field_id]&.response || ''
      result[key] = response
    end
  end

  ################################################
  # This CSV method is separate from the above one
  # ##############################################

  # What do we want the end result headers to be?
  # ...
  # usbc_id, name, item name, division, size, price, payment identifier

  def self.financial_csv(tournament_id:)
    require 'csv'

    purchases = Purchase.includes(:purchasable_item, :external_payment, bowler: [:person])
                        .where(purchasable_item: { tournament_id: tournament_id })
                        .where.not(external_payment_id: nil)
                        .order('people.last_name ASC')

    csv_data = purchases.map do |purchase|
      {
        'Bowler': TournamentRegistration.person_list_name(purchase.bowler.person),
        'USBC ID': purchase.bowler.usbc_id,
        'Item Name': purchase.name,
        'Division': purchase.purchasable_item.division? ? purchase.configuration['division'] : '',
        'Size': purchase.purchasable_item.apparel? ? ApparelDetails.humanize_size(purchase.configuration['size']) : '',
        'Amount': "$#{purchase.amount}",
        'Payment Identifier': purchase.external_payment&.identifier,
      }
    end

    return '' unless csv_data.any?

    headers = csv_data.first.keys
    data = csv_data.map(&:values)

    CSV.generate do |csv|
      csv << headers
      data.each { |p| csv << p }
    end
  end
end
