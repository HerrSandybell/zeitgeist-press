class StoryComponent < ViewComponent::Base
  def initialize(story:)
    @story = story
  end
end
