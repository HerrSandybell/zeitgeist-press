require "application_system_test_case"

class MobileLayoutTest < ApplicationSystemTestCase
  MOBILE_WIDTH  = 375
  MOBILE_HEIGHT = 812

  setup do
    @edition    = editions(:one)
    @newspaper  = @edition.newspaper
    current_window.resize_to(MOBILE_WIDTH, MOBILE_HEIGHT)
    visit newspaper_edition_path(@newspaper, @edition)
  end

  teardown do
    current_window.resize_to(1400, 1400)
  end

  test "newspaper page fills the full viewport width on mobile" do
    page_width = page.evaluate_script(
      "document.querySelector('.newspaper-page').getBoundingClientRect().width"
    )
    viewport_width = page.evaluate_script("document.documentElement.clientWidth")
    assert_equal viewport_width.to_i, page_width.to_i
  end

  test "page-content has no padding on mobile" do
    padding = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('.page-content')).padding"
    )
    assert_equal "0px", padding
  end

  test "story grid is a flex column on mobile" do
    display = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('.front-page-grid')).display"
    )
    flex_direction = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('.front-page-grid')).flexDirection"
    )
    assert_equal "flex", display
    assert_equal "column", flex_direction
  end

  test "story cards are capped at 20rem on mobile" do
    max_height = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('.story')).maxHeight"
    )
    # 20rem = 320px at the default 16px root font size
    assert_equal "320px", max_height
  end

  test "long story shows the continued link on mobile" do
    long = stories(:long_major)
    assert_selector "article[data-story-id='#{long.id}'] a.story-continued-link",
                    visible: true, wait: 5
  end

  test "short story does not show the continued link on mobile" do
    short = stories(:tertiary_one)
    long  = stories(:long_major)
    # Wait for overflow detection to complete on the long story first
    assert_selector "article[data-story-id='#{long.id}'] a.story-continued-link",
                    visible: true, wait: 5
    within "article[data-story-id='#{short.id}']" do
      assert_no_selector "a.story-continued-link", visible: true
    end
  end

  test "story overlay cutout has no rotation on mobile" do
    long = stories(:long_major)
    within "article[data-story-id='#{long.id}']" do
      assert_selector "a.story-continued-link", visible: true, wait: 5
      find("a.story-continued-link").click
    end
    assert_selector ".overlay-frame--open", wait: 5

    transform = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('article.story-cutout')).transform"
    )
    # CSS 'transform: none' computes to 'none' or the identity matrix
    assert_includes ["none", "matrix(1, 0, 0, 1, 0, 0)"], transform
  end

  test "story overlay cutout body is single-column on mobile" do
    long = stories(:long_major)
    within "article[data-story-id='#{long.id}']" do
      assert_selector "a.story-continued-link", visible: true, wait: 5
      find("a.story-continued-link").click
    end
    assert_selector ".overlay-frame--open", wait: 5

    col_count = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('[data-newspaper] .story-cutout .story .story-body')).columnCount"
    )
    assert_equal "1", col_count
  end

  test "masthead info bar stacks in a single column on mobile" do
    col_count = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('.masthead-info')).gridTemplateColumns.split(' ').length"
    )
    assert_equal 1, col_count
  end

  test "masthead title wraps rather than overflowing on mobile" do
    white_space = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('.masthead-title')).whiteSpace"
    )
    assert_equal "normal", white_space
  end
end
