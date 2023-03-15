class RemoveDetailsFromShifts < ActiveRecord::Migration[7.0]
  def change
    remove_column :shifts, :details, if_exists: true, default: {"events"=>[], "registration_types"=>["new_team", "solo", "join_team"]}
  end
end
