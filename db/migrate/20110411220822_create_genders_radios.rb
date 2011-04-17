class CreateGendersRadios < ActiveRecord::Migration
  def self.up
    create_table :genders_radios do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :genders_radios
  end
end
