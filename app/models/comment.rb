class Comment < ApplicationRecord
  belongs_to :edition
  belongs_to :character

  validates :body, presence: true, length: { maximum: 280 }

  after_create_commit -> {
    broadcast_append_to [edition, :comments],
      target:  "edition_#{edition_id}_comments",
      partial: "comments/comment",
      locals:  { comment: self }
  }
end
