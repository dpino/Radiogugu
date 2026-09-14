# Ported from the old vendor/plugins/acts_as_rateable Rails 2/3 plugin
# (vendor/plugins support was removed in Rails 4). Loaded as an initializer,
# rather than an autoloaded app/models/concerns file, so the ClassMethods
# are available on ActiveRecord::Base before Radio's `acts_as_rateable` call
# is evaluated at boot.
module ActsAsRateable
  module ClassMethods
    def acts_as_rateable
      has_many :ratings, as: :rateable, dependent: :destroy
      include ActsAsRateable::InstanceMethods
    end
  end

  module InstanceMethods
    def add_rating(rating)
      ratings << rating
    end

    def rating
      return 0.0 if ratings.empty?

      ratings.sum(&:rating).to_f / ratings.size
    end

    def rated_by_user?(user)
      return false unless user

      ratings.any? { |r| r.user_id == user.id }
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend ActsAsRateable::ClassMethods
end
