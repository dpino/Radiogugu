class Favorite < ApplicationRecord
  belongs_to :radio
  belongs_to :user
end
