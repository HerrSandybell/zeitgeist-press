class Newspaper < ApplicationRecord
  has_many :editions, dependent: :destroy
end
