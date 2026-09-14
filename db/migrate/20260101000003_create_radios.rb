class CreateRadios < ActiveRecord::Migration[7.1]
  def change
    create_table :radios do |t|
      t.string :name
      t.string :website
      t.string :gender
      t.string :url, limit: 1024
      t.references :location
      t.references :user
      t.integer :parent_id

      t.timestamps
    end
  end
end
