class Favorite < ActiveRecord::Base
  belongs_to :radio
  has_many :users
end
