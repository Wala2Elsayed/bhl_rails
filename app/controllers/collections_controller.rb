class CollectionsController < ApplicationController
  include BHL::Login
  
  def index
  end
  
  def show
  end
  
  def create_collection
  end
  
  def destroy_collection
  end
  
  def add_book
    @bok_col = BookCollection.new
#    debugger
  end
  
  def delete_book
  end
  
end