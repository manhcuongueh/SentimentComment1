class AddLowestUrlToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :lowestUrl, :string
  end
end
