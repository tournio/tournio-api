class RemoveRequestedFromShifts < ActiveRecord::Migration[7.0]
  def up
    remove_column :shifts, :requested
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
