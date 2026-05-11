require "test_helper"

class SelectMenuComponentTest < ViewComponent::TestCase
  def theme_options
    [["Yellow Sheets", ""], ["Broadsheet", "broadsheet"]]
  end

  test "renders a select with the given name" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: "", name: "theme"))
    assert_selector "select[name='theme']"
  end

  test "renders all options" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: "", name: "theme"))
    assert_selector "option", count: 2
    assert_selector "option[value='']",            text: "Yellow Sheets"
    assert_selector "option[value='broadsheet']",  text: "Broadsheet"
  end

  test "marks the matching option as selected" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: "broadsheet", name: "theme"))
    assert_selector "option[value='broadsheet'][selected]"
    assert_no_selector "option[value=''][selected]"
  end

  test "selects empty-value option when selected is nil" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: nil, name: "theme"))
    assert_selector "option[value=''][selected]"
  end

  test "passes through html options" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: nil, name: "theme", class: "my-select"))
    assert_selector "select.my-select"
  end
end
