class AddAverageScoreToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :averageScore, :float
  end
end
