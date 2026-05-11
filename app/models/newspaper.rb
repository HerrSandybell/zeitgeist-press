class Newspaper < ApplicationRecord
  has_many :editions, dependent: :destroy

  validates :name, presence: true

  def slug
    name.parameterize
  end
end
