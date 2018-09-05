class AddMinScoreToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :minScore, :float
  end
end
