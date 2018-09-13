class RobotsController < ApplicationController
  def index
    robots = File.read(Rails.root + "config/robots/#{Rails.env}.txt")

    render text: robots, layout: false, content_type: 'text/plain'
  end
end