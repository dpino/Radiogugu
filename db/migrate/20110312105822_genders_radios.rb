class GendersRadios < ActiveRecord::Migration
  def self.up
    create_table :genders_radios, :id => false do |t|
      t.integer  :gender_id
      t.integer  :radio_id
    end
  end

  def self.down
    drop_table :genders_radios
  end
end
