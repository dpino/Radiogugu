class CreateTranscripts < ActiveRecord::Migration[7.1]
  def change
    create_table :transcripts do |t|
      t.references :radio, null: false, foreign_key: true
      t.text :text
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
