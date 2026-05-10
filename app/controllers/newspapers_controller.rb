class NewspapersController < ApplicationController
  def index
    @newspapers = Newspaper.all
  end
end
