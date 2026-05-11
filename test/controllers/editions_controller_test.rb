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

  test "show renders all non-advertisement stories" do
    get newspaper_edition_url(@newspaper, @edition)
    @edition.stories.where.not(story_type: :advertisement).each do |story|
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

  test "show caps advertisements at four" do
    get newspaper_edition_url(@newspaper, @edition)

    assert_includes response.body, stories(:ad_one).headline
    assert_includes response.body, stories(:ad_two).headline
    assert_includes response.body, stories(:ad_three).headline
    assert_includes response.body, stories(:ad_four).headline
    assert_not_includes response.body, stories(:ad_five).headline
  end

  test "show_current renders the first published edition at root" do
    get root_url
    assert_response :success
    assert_select "h1.masthead-title", text: editions(:two).newspaper.name
  end

  test "show_current returns 404 when no published edition exists" do
    Edition.update_all(published: false)
    get root_url
    assert_response :not_found
  end
end
