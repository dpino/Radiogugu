class Comment < ActiveRecord::Base
  belongs_to :radio
  belongs_to :user
end
