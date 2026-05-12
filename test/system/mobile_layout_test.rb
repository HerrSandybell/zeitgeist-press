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
end
