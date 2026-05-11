class SelectMenuComponent < ViewComponent::Base
  def initialize(options:, selected:, name:, **html_options)
    @options      = options
    @selected     = selected.to_s
    @name         = name
    @html_options = html_options
  end
end
