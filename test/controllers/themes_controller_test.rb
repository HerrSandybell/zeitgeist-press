require "test_helper"

class ThemesControllerTest < ActionDispatch::IntegrationTest
  test "stores broadsheet in session" do
    patch theme_url, params: { theme: "broadsheet" }
    assert_equal "broadsheet", session[:theme]
  end

  test "clears session for empty string" do
    patch theme_url, params: { theme: "" }
    assert_nil session[:theme]
  end

  test "clears session for unrecognised theme" do
    patch theme_url, params: { theme: "hacker" }
    assert_nil session[:theme]
  end

  test "clears existing session value when default requested" do
    patch theme_url, params: { theme: "broadsheet" }
    patch theme_url, params: { theme: "" }
    assert_nil session[:theme]
  end

  test "redirects back to root" do
    patch theme_url, params: { theme: "broadsheet" }
    assert_redirected_to root_url
  end
end
