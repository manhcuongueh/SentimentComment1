class AddHighestScoreToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :highestScore, :float
  end
end
