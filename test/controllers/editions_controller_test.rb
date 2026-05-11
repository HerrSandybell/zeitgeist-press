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

  test "masthead renders edition_type and price when present" do
    get newspaper_edition_url(editions(:two).newspaper, editions(:two))
    assert_select ".masthead-edition-type", text: "Extra Edition"
    assert_select ".masthead-price", text: "Two Pennies"
  end

  test "masthead omits meta row when edition_type and price are nil" do
    get newspaper_edition_url(editions(:one).newspaper, editions(:one))
    assert_select ".masthead-meta", count: 0
  end

  test "masthead renders tagline when present" do
    get newspaper_edition_url(editions(:two).newspaper, editions(:two))
    assert_select ".masthead-tagline"
  end

  test "masthead omits tagline when nil" do
    get newspaper_edition_url(editions(:one).newspaper, editions(:one))
    assert_select ".masthead-tagline", count: 0
  end

  test "masthead info row includes city when present" do
    get newspaper_edition_url(editions(:two).newspaper, editions(:two))
    assert_select ".masthead-info__date" do |nodes|
      assert_match(/Flint/, nodes.first.text)
    end
  end

  test "masthead info row omits city separator when city is nil" do
    get newspaper_edition_url(editions(:one).newspaper, editions(:one))
    assert_select ".masthead-info__date" do |nodes|
      assert_no_match(/ — /, nodes.first.text)
    end
  end

  test "masthead info row omits print_location when nil" do
    get newspaper_edition_url(editions(:one).newspaper, editions(:one))
    assert_select ".masthead-info__location", text: ""
  end
end
