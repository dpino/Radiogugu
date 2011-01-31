class Radio < ActiveRecord::Base
	acts_as_rateable
	validates :name, :presence => true
	validates :url, :presence => true

	belongs_to :location
end
