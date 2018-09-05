class AddHighestUrlToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :highestUrl, :string
  end
end
