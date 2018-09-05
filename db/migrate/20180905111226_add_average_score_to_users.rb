class AddAverageScoreToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :averageScore, :float
  end
end
