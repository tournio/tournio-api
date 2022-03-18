class CreateRegistrationSummarySends < ActiveRecord::Migration[7.0]
  def change
    create_table :registration_summary_sends do |t|
      t.references :tournament, null: false
      t.timestamp :last_sent_at, null: false
      t.integer :bowler_count, default: 0
    end
  end
end
