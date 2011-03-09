class AddJoinTableRadioGender < ActiveRecord::Migration
  def self.up
    create_table :radios_genders, :id => false do |t|
      t.integer :radio_id
      t.integer :gender_id
    end
  end

  def self.down
    drop_table :radios_genders
  end
end
