class NewspapersController < ApplicationController
  def index
    @newspapers = Newspaper.includes(:editions).all
  end
end
