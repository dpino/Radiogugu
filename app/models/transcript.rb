class Transcript < ApplicationRecord
  belongs_to :radio

  validates :text, presence: true
end
