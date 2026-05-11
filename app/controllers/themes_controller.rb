class ThemesController < ApplicationController
  VALID_THEMES = %w[broadsheet].freeze

  def update
    if VALID_THEMES.include?(params[:theme])
      session[:theme] = params[:theme]
    else
      session.delete(:theme)
    end

    redirect_back fallback_location: root_path
  end
end
