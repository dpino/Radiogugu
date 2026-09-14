class CreateFavorites < ActiveRecord::Migration[7.1]
  def change
    create_table :favorites do |t|
      t.references :radio
      t.references :user

      t.timestamps
    end
  end
end
