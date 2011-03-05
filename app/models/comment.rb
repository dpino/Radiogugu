class Comment < ActiveRecord::Base
  belongs_to :radio, :user
end
