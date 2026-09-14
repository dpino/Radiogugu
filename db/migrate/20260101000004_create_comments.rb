class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.text :body
      t.references :radio
      t.references :user

      t.timestamps
    end
  end
end
