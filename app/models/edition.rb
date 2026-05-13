class Edition < ApplicationRecord
  belongs_to :newspaper
  has_many :stories, dependent: :destroy
  has_many :comments, dependent: :destroy

  enum :season, { spring: 0, summer: 1, autumn: 2, winter: 3 }

  validates :year, :season, :day, :volume, :issue_number, presence: true
  validates :day, numericality: { in: 1..90 }

  def label
    "#{day.ordinalize} of #{season.capitalize}, #{year}"
  end
end
