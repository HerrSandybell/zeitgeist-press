require "test_helper"

class StoriesControllerTest < ActionDispatch::IntegrationTest
  test "show_full returns 200 for an existing story" do
    get full_story_url(stories(:one))
    assert_response :success
  end

  test "show_full returns 404 for a missing story" do
    get full_story_url(id: 999_999)
    assert_response :not_found
  end

  test "show_full renders the cutout wrapper containing the full story" do
    story = stories(:one)
    get full_story_url(story)

    assert_select "turbo-frame#story-overlay" do
      assert_select "article.story-cutout.story-cutout--major"
      assert_select ".story-cutout__masthead", text: /Page 1/
      assert_select ".story-cutout__footer"
      assert_select ".story", text: /#{story.headline}/
    end
  end

  test "show_full does not render the application layout" do
    get full_story_url(stories(:one))
    assert_no_match(/<body/, response.body)
  end

  test "show_full carries the newspaper slug for theme scoping" do
    get full_story_url(stories(:one))

    assert_select "article.story-cutout[data-newspaper='the-daily-chronicle']"
  end

  test "show_full renders masthead without newspaper name for orphan stories" do
    get full_story_url(stories(:orphan))

    assert_select ".story-cutout__masthead", text: /\APage 1\z/
  end
end
