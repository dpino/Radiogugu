class Radio < ApplicationRecord
  acts_as_rateable

  validates :name, presence: true
  validates :url, presence: true

  belongs_to :location, optional: true
  belongs_to :user, optional: true
  belongs_to :parent, class_name: "Radio", optional: true

  has_many :comments, -> { order(updated_at: :desc) }
  has_many :transcripts

  has_many :genders_radios
  has_many :genders, through: :genders_radios

  # Fake property, only used in Views
  attr_accessor :location_str

  def fork(user)
    child = self.dup
    child.user = user
    child.parent = self
    child.save
    child
  end

  def exits_child(user)
    !get_child(user).nil?
  end

  def get_child(user)
    Radio.where(user_id: user.id, parent_id: self.id).first
  end
end
