class AddLabelToConfigItems < ActiveRecord::Migration[7.0]
  def change
    add_column :config_items, :label, :string
  end
end
