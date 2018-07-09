class CreatePosts < ActiveRecord::Migration[5.2]
  def change
    create_table :posts do |t|
      t.string :link
      t.string :image
      t.string :date

      t.timestamps
    end
  end
end
