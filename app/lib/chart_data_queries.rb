module ChartDataQueries
  def self.last_week_registrations_by_day(tournament)
    return {} unless tournament.present?
    sql = <<-SQL
      SELECT 
        TO_CHAR(DATE_TRUNC('day', b.created_at), 'YYYY-MM-DD') AS created_on,
        COUNT(b.id)
      FROM bowlers b
      WHERE tournament_id = :id
      AND b.created_at >= CURRENT_DATE - INTERVAL '8 days'
      GROUP BY created_on
    SQL
    output = week_starter
    args = [
      sql,
      id: tournament.id,
      tz: tournament.time_zone,
    ]

    ActiveRecord::Base.connection.select_all(
      ActiveRecord::Base.send(:sanitize_sql_array, args)
    ).rows.each do |row|
      index = output[:dates].index(row[0])
      next unless index.present?
      output[:values][index] = row[1]
    end

    output
  end

  def self.last_week_payments_by_day(tournament)
    return {} unless tournament.present?
    sql = <<-SQL
      SELECT 
        TO_CHAR(DATE_TRUNC('day', ep.created_at), 'YYYY-MM-DD') AS created_on,
        COUNT(ep.id)
      FROM external_payments ep
      WHERE ep.tournament_id = :id
      AND ep.created_at >= CURRENT_DATE - INTERVAL '8 days'
      GROUP BY created_on
    SQL
    output = week_starter
    args = [
      sql,
      id: tournament.id,
      tz: tournament.time_zone,
    ]

    ActiveRecord::Base.connection.select_all(
      ActiveRecord::Base.send(:sanitize_sql_array, args)
    ).rows.each do |row|
      index = output[:dates].index(row[0])
      next unless index.present?
      output[:values][index] = row[1]
    end

    output
  end

  def self.last_week_registration_types_by_day(tournament)
    return {} unless tournament.present?
    sql = <<-SQL
      SELECT 
        TO_CHAR(DATE_TRUNC('day', dp.created_at), 'YYYY-MM-DD') AS created_on,
        dp.value,
        COUNT(dp.id) AS total
      FROM data_points dp
      WHERE dp.tournament_id = :id
      AND dp.key = :key
      AND dp.created_at >= CURRENT_DATE - INTERVAL '8 days'
      GROUP BY created_on, value
      ORDER BY created_on ASC
    SQL
    args = [
      sql,
      id: tournament.id,
      tz: tournament.time_zone,
      key: DataPoint.keys[:registration_type],
    ]

    output = week_starter
    output.delete(:values)
    size = output[:dates].count
    Shift::SUPPORTED_REGISTRATION_TYPES.each { |type| output[type.to_sym] = Array.new(size, 0) }

    ActiveRecord::Base.connection.select_all(
      ActiveRecord::Base.send(:sanitize_sql_array, args)
    ).rows.each do |row|
      date = row[0]
      type = row[1].to_sym
      amount = row[2]
      index = output[:dates].index(row[0])
      next unless index.present?
      output[type][index] = amount
    end

    output
  end

  def self.week_starter(starter_value = 0)
    today = Time.zone.today
    base_obj = {
      dates: [],
      values: [],
    }
    (0..7).map do |i|
      days_back = 7 - i
      day = today - days_back
      day.strftime('%F')
    end
      .each_with_object(base_obj) do |e, a|
      a[:dates] << e
      a[:values] << starter_value
    end
  end
end
