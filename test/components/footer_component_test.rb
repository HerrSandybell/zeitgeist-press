require "test_helper"

class FooterComponentTest < ViewComponent::TestCase
  test "renders a footer element with the site-footer class" do
    render_inline(FooterComponent.new)
    assert_selector "footer.site-footer"
  end
end
