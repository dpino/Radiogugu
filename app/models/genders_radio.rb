class GendersRadio < ActiveRecord::Base
    belongs_to :radio
    belongs_to :gender
end
