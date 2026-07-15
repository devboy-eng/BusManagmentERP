class QuickResponse < ApplicationRecord
  belongs_to :user, optional: true

  validates :title, presence: true
  validates :body, presence: true

  scope :shared, -> { where(user_id: nil) }
  scope :by_user, ->(user) { where(user_id: [nil, user.id]) }
  scope :search, ->(q) { where("title LIKE ? OR body LIKE ?", "%#{q}%", "%#{q}%") }

  def increment_usage!
    increment!(:usage_count)
  end
end
