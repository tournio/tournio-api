class AddVerifiedDataToBowlers < ActiveRecord::Migration[7.0]
  def change
    change_table :bowlers do |t|
      t.jsonb :verified_data, default: {}
    end
  end
end
