class Favorite < ActiveRecord::Base
  has_many :radios
  has_many :users
end
