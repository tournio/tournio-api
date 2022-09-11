class AddIdentifierToContacts < ActiveRecord::Migration[7.0]
  def up
    add_column :contacts, :identifier, :string

    Contact.where(identifier: nil).each do |c|
      c.update(identifier: SecureRandom.uuid)
    end

    add_index :contacts, :identifier, unique: true
  end

  def down
    remove_index :contacts, :identifier
    remove_column :contacts, :identifier
  end
end
