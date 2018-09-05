class AddTotalCommentToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :totalComment, :integer
  end
end
