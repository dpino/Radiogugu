class Gender < ActiveRecord::Base
  has_many :genders_radios
  has_many :radios, :through => :genders_radios
end
