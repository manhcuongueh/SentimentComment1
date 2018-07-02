class AddDateToLink < ActiveRecord::Migration[5.2]
  def change
    add_column :links, :date, :string
  end
end
