class Character < ApplicationRecord
  has_many :comments, dependent: :nullify

  validates :name, :emoji, presence: true
end
