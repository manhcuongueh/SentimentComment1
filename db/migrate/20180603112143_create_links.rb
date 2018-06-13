class CreateLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :links, :id => false do |t|
      t.integer :id
      t.string :link

      t.timestamps
    end
  end
end
