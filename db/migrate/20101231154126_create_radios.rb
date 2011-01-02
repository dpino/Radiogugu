class CreateRadios < ActiveRecord::Migration
  def self.up
    create_table :radios do |t|
      t.string :name
      t.string :website
      t.string :url
      t.string :gender
      t.string :location
      t.string :country

      t.timestamps
    end

	change_column :url, :url, :string, :limit => 1024
	change_column :location, :location, :references
  end

  def self.down
    drop_table :radios
  end
end
