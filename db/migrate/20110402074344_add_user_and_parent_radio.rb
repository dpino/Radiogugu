class AddUserAndParentRadio < ActiveRecord::Migration
  def self.up
    change_table :radios do |t|
      t.integer :parent_id
      t.integer :user_id
    end
  end

  def self.down
    remove_column :radios, :parent_id
    remove_column :radios, :user_id
  end
end
