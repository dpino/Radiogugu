class AddTranslatedTextToTranscripts < ActiveRecord::Migration[7.1]
  def change
    add_column :transcripts, :translated_text, :text
  end
end
