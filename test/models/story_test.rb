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

  test "major scope returns only major stories" do
    assert_equal Story.where(story_type: :major).sort, Story.major.sort
    assert Story.major.all? { |s| s.major? }
  end

  test "secondary scope returns only secondary stories" do
    assert_equal Story.where(story_type: :secondary).sort, Story.secondary.sort
    assert Story.secondary.all? { |s| s.secondary? }
  end

  test "tertiary scope returns only tertiary stories" do
    assert_equal Story.where(story_type: :tertiary).sort, Story.tertiary.sort
    assert Story.tertiary.all? { |s| s.tertiary? }
  end

  test "advertisement scope returns only advertisement stories" do
    assert_equal Story.where(story_type: :advertisement).sort, Story.advertisement.sort
    assert Story.advertisement.all? { |s| s.advertisement? }
  end

  test "continued_page returns position + 1" do
    story = stories(:one)
    story.position = 0
    assert_equal 1, story.continued_page

    story.position = 7
    assert_equal 8, story.continued_page
  end

  test "continued_page treats nil position as 0" do
    story = stories(:one)
    story.position = nil
    assert_equal 1, story.continued_page
  end
end
