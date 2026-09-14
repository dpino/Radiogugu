class CreateGendersRadios < ActiveRecord::Migration[7.1]
  def change
    create_table :genders_radios do |t|
      t.integer :gender_id
      t.integer :radio_id
      t.integer :user_id
    end
  end
end
