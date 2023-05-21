class AddIdentifierToAdditionialQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :additional_questions, :identifier, :string
  end
end
