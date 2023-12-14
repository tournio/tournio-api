class ChangePersonFieldsToNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :people, :address1, true
    change_column_null :people, :birth_day, true
    change_column_null :people, :birth_month, true
    change_column_null :people, :city, true
    change_column_null :people, :country, true
    change_column_null :people, :postal_code, true
    change_column_null :people, :state, true

    remove_column :people, :igbo_id, :string

    add_column :people, :birth_year, :integer
  end
end
