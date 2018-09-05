class AddMaxScoreToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :maxScore, :float
  end
end
