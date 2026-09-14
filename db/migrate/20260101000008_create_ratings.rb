class CreateRatings < ActiveRecord::Migration[7.1]
  def change
    create_table :ratings do |t|
      t.integer :rating, default: 0
      t.datetime :created_at, null: false
      t.string :rateable_type, limit: 15, default: "", null: false
      t.integer :rateable_id, default: 0, null: false
      t.integer :user_id, default: 0, null: false
    end

    add_index :ratings, [:user_id], name: "fk_ratings_user"
  end
end
