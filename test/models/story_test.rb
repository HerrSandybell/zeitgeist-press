require "test_helper"

class StoryTest < ActiveSupport::TestCase
  test "story_type enum defines all four values" do
    assert_equal({ "major" => 0, "secondary" => 1, "tertiary" => 2, "advertisement" => 3 }, Story.story_types)
  end

  test "invalid story_type raises ArgumentError" do
    assert_raises(ArgumentError) { Story.new(story_type: :invalid_type) }
  end

  test "is valid without an edition" do
    assert_predicate stories(:orphan), :valid?
  end

  test "orphan fixture has nil edition_id" do
    assert_nil stories(:orphan).edition_id
  end

  test "is invalid without story_type" do
    story = stories(:one)
    story.story_type = nil
    assert_not story.valid?
    assert_includes story.errors[:story_type], "can't be blank"
  end

  test "is invalid without headline" do
    story = stories(:one)
    story.headline = nil
    assert_not story.valid?
    assert_includes story.errors[:headline], "can't be blank"
  end

  test "is invalid without body" do
    story = stories(:one)
    story.body = nil
    assert_not story.valid?
    assert_includes story.errors[:body], "can't be blank"
  end
end
