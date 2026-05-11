class NavbarComponent < ViewComponent::Base
  def initialize(current_theme:)
    @current_theme = current_theme
  end

  def theme_options
    [["Yellow Sheets", ""], ["Broadsheet", "broadsheet"]]
  end
end
