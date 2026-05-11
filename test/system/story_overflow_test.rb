require "application_system_test_case"

class StoryOverflowTest < ApplicationSystemTestCase
  setup do
    @edition   = editions(:one)
    @newspaper = @edition.newspaper
    @long      = stories(:long_major)
  end

  test "clicking the continued link opens the overlay with the full story" do
    visit newspaper_edition_path(@newspaper, @edition)

    within "article[data-story-id='#{@long.id}']" do
      assert_selector "a.story-continued-link", visible: true, wait: 5
      find("a.story-continued-link").click
    end

    assert_selector "div.overlay-frame.overlay-frame--open", wait: 5
    assert_selector "turbo-frame#story-overlay article.story-cutout"
    assert_selector ".story-cutout__masthead", text: /page/i
    assert_text @long.headline
  end

  test "pressing ESC closes the overlay" do
    visit newspaper_edition_path(@newspaper, @edition)

    within "article[data-story-id='#{@long.id}']" do
      assert_selector "a.story-continued-link", visible: true, wait: 5
      find("a.story-continued-link").click
    end

    assert_selector ".overlay-frame--open", wait: 5
    find("body").send_keys(:escape)
    assert_no_selector ".overlay-frame--open"
  end

  test "clicking the backdrop closes the overlay" do
    visit newspaper_edition_path(@newspaper, @edition)

    within "article[data-story-id='#{@long.id}']" do
      assert_selector "a.story-continued-link", visible: true, wait: 5
      find("a.story-continued-link").click
    end

    assert_selector ".overlay-frame--open", wait: 5
    # Click on the backdrop element directly (the centered cutout sits on top of it).
    page.execute_script("document.querySelector('.overlay-frame').click()")
    assert_no_selector ".overlay-frame--open"
  end

  test "clicking the cutout itself does not close the overlay" do
    visit newspaper_edition_path(@newspaper, @edition)

    within "article[data-story-id='#{@long.id}']" do
      assert_selector "a.story-continued-link", visible: true, wait: 5
      find("a.story-continued-link").click
    end

    assert_selector ".overlay-frame--open", wait: 5
    find("article.story-cutout").click
    assert_selector ".overlay-frame--open"
  end

  test "short stories do not display the continued link" do
    short = stories(:tertiary_one)
    visit newspaper_edition_path(@newspaper, @edition)

    # Wait until the overflow controller has had a chance to run on all
    # stories on the page — the long_major's link surfaces, signaling
    # detection has completed for everyone.
    assert_selector "article[data-story-id='#{@long.id}'] a.story-continued-link",
                    visible: true, wait: 5

    within "article[data-story-id='#{short.id}']" do
      assert_no_selector "a.story-continued-link", visible: true
    end
  end
end
