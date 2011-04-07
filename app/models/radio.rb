class Radio < ActiveRecord::Base
  acts_as_rateable
  validates :name, :presence => true
  validates :url, :presence => true

  belongs_to :location
  belongs_to :favorite
  belongs_to :user
  belongs_to :parent, :class_name => 'Radio'

  has_many :comments, :order => "updated_at desc"

  has_many :genders_radios
  has_many :genders, :through => :genders_radios

  # Fake properties (only used in Views)
  attr_accessor :location_str

end
