class MediaController < ApplicationController
  before_action :set_table, only: [:show, :edit, :update, :destroy]
  caches_page :index
  
  # GET /
  def index
    render "app/views/media/index.html.haml"
  end
end


