require "test_helper"

class NavbarComponentTest < ViewComponent::TestCase
  test "renders site name" do
    render_inline(NavbarComponent.new(current_theme: nil))
    assert_selector ".site-navbar__name", text: "Zeitgeist Press"
  end

  test "renders a form posting to /theme" do
    render_inline(NavbarComponent.new(current_theme: nil))
    assert_selector "form[action='/theme']"
  end

  test "renders a theme select inside the form" do
    render_inline(NavbarComponent.new(current_theme: nil))
    assert_selector "form select[name='theme']"
  end

  test "selects Yellow Sheets when theme is nil" do
    render_inline(NavbarComponent.new(current_theme: nil))
    assert_selector "option[value=''][selected]"
    assert_no_selector "option[value='broadsheet'][selected]"
  end

  test "selects Broadsheet when theme is broadsheet" do
    render_inline(NavbarComponent.new(current_theme: "broadsheet"))
    assert_selector "option[value='broadsheet'][selected]"
  end
end
