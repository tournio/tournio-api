class UpdateShiftsFor2024 < ActiveRecord::Migration[7.0]
  def up
    drop_table :bowlers_shifts
    remove_column :shifts, :confirmed, if_exists: true
    add_column :shifts, :is_full, :boolean, default: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
