class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.string :username
      t.string :image
      t.text :body
      t.float :score

      t.timestamps
    end
  end
end
