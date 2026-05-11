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
end
