module ChartDataQueries
  def self.last_week_registrations_by_day(tournament)
    return [] unless tournament.present?
    sql = <<-SQL
      SELECT 
        TO_CHAR(DATE_TRUNC('day', b.created_at), 'YYYY-MM-DD') AS created_on,
        COUNT(b.id)
      FROM bowlers b
      WHERE tournament_id = :id
      AND b.created_at > CURRENT_DATE - 7
      GROUP BY created_on
      ORDER BY created_on ASC
    SQL
    output = {}

    ActiveRecord::Base.connection.select_all(
      ActiveRecord::Base.send(:sanitize_sql_array, [sql, id: tournament.id])
    ).rows.each do |row|
      output[Time.parse(row[0]).to_i] = row[1]
    end
    output
  end
end
