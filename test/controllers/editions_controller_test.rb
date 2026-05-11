require "test_helper"

class EditionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @edition = editions(:one)
    @newspaper = @edition.newspaper
  end

  test "show responds with 200" do
    get newspaper_edition_url(@newspaper, @edition)
    assert_response :success
  end

  test "show renders all stories for the edition" do
    get newspaper_edition_url(@newspaper, @edition)
    @edition.stories.each do |story|
      assert_includes response.body, story.headline,
        "Expected response to include headline #{story.headline.inspect}"
    end
  end

  test "show renders stories ordered by story_type ascending" do
    get newspaper_edition_url(@newspaper, @edition)
    major         = stories(:one)
    secondary     = stories(:secondary_one)
    tertiary      = stories(:tertiary_one)
    advertisement = stories(:ad_one)

    positions = [major, secondary, tertiary, advertisement].map do |s|
      response.body.index(s.headline)
    end
    assert positions.all?, "Expected all four headlines to appear in response body"
    assert_equal positions, positions.sort,
      "Expected story_type order: major < secondary < tertiary < advertisement"
  end
end
