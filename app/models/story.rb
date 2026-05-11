class Story < ApplicationRecord
  belongs_to :edition, optional: true

  enum :story_type, { major: 0, secondary: 1, tertiary: 2, advertisement: 3 }

  validates :story_type, :headline, :body, presence: true

  scope :major,         -> { where(story_type: :major) }
  scope :secondary,     -> { where(story_type: :secondary) }
  scope :tertiary,      -> { where(story_type: :tertiary) }
  scope :advertisement, -> { where(story_type: :advertisement) }
end
