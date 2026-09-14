class Gender < ApplicationRecord
  has_many :genders_radios
  has_many :radios, through: :genders_radios
end
