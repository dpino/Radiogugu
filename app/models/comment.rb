class Comment < ApplicationRecord
  belongs_to :radio
  belongs_to :user
end
