class Story < ApplicationRecord
  belongs_to :edition

  enum :story_type, { major: 0, secondary: 1, tertiary: 2, advertisement: 3 }
end
