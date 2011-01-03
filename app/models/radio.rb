class Radio < ActiveRecord::Base
	validates :name, :presence => true
	validates :url, :presence => true

	belongs_to :location
end
