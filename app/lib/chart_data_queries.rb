module ChartDataQueries
  def self.last_week_registrations_by_day(tournament)
    return [] unless tournament.present?
    sql = <<-SQL
      SELECT 
        TO_CHAR(DATE_TRUNC('day', b.created_at AT TIME ZONE :tz), 'YYYY-MM-DD') AS created_on,
        COUNT(b.id)
      FROM bowlers b
      WHERE tournament_id = :id
      AND b.created_at > CURRENT_DATE - 7
      GROUP BY created_on
      ORDER BY created_on ASC
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
      output[row[0]] = row[1]
    end

    output
  end

  def self.last_week_payments_by_day(tournament)
    return [] unless tournament.present?
    sql = <<-SQL
      SELECT 
        TO_CHAR(DATE_TRUNC('day', ep.created_at AT TIME ZONE :tz), 'YYYY-MM-DD') AS created_on,
        COUNT(ep.id)
      FROM external_payments ep
      WHERE ep.tournament_id = :id
      AND ep.created_at > CURRENT_DATE - 7
      GROUP BY created_on
      ORDER BY created_on ASC
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
      output[row[0]] = row[1]
    end

    output
  end

  def self.week_starter
    today = Time.zone.today
    (0..7).map do |i|
      days_back = 7 - i
      day = today - days_back
      day.strftime('%F')
    end
      .each_with_object({}) { |e, a| a[e] = 0 }
  end
end
