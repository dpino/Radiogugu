class Rating < ApplicationRecord
  belongs_to :rateable, polymorphic: true
  belongs_to :user, optional: true
end
