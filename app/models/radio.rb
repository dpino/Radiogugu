class Radio < ActiveRecord::Base
  acts_as_rateable
  validates :name, :presence => true
  validates :url, :presence => true

  belongs_to :location
  has_many :comments, :order => "updated_at desc"
  belongs_to :favorite
  # has_one :favorite
  # has_many :favorites
  has_and_belongs_to_many :genders

  # Fake properties (only used in Views)
  attr_accessor :location_str
end
