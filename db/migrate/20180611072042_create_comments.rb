class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments,:id => false do |t|
      t.integer :id
      t.string :username
      t.text :body
      t.float :score

      t.timestamps
    end
  end
end
