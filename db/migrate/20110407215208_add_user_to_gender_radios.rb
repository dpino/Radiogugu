class AddUserToGenderRadios < ActiveRecord::Migration
  def self.up
    change_table :genders_radios do |t|
      t.references :user
    end
  end

  def self.down
    remove_column :genders_radios, :user_id
  end
end
