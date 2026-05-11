class StoryComponent < ViewComponent::Base
  def initialize(story:)
    @story = story
  end

  private

  def body_halves
    @body_halves ||= begin
      paragraphs = @story.body.split(/\n\n+/)
      midpoint   = (paragraphs.length / 2.0).ceil
      [
        paragraphs.first(midpoint).join("\n\n"),
        paragraphs.drop(midpoint).join("\n\n")
      ]
    end
  end
end
