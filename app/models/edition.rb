class Edition < ApplicationRecord
  belongs_to :newspaper
  has_many :stories, dependent: :destroy

  enum :season, { spring: 0, summer: 1, autumn: 2, winter: 3 }
end
