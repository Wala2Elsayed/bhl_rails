require 'spec_helper'

describe BooksController do
  render_views
  include BooksHelper
  describe "GET 'index'" do

    before(:each) do
      truncate_table(ActiveRecord::Base.connection, "books", {})
      truncate_table(ActiveRecord::Base.connection, "volumes", {})

      @name1 = Name.gen(:string => "sci1")
      @name2 = Name.gen(:string => "sci2")
      @name3 = Name.gen(:string => "sci3")

      doc_test_first = {:vol_jobid => "123", :bok_bibid => "456"}
      doc_test_first[:bok_title] = "Test Book First"
      doc_test_first[:name] = ["Name1","Name2"]
      doc_test_first[:author] = "Author"
      doc_test_first[:bok_language]="English"
      doc_test_first[:geo_location]="Egypt"
      doc_test_first[:subject]="subject"

      solr = RSolr.connect :url => SOLR_BOOKS_METADATA
      # remove this book if exists
      solr.delete_by_query('vol_jobid:123')
      solr.commit
      solr.add doc_test_first
      solr.commit

      @book_test_first = Book.gen(:title => 'Test Book second', :bibid => '456')
      @vol_first = Volume.gen(:book => @book_test_first, :job_id => '123', :get_thumbnail_fail => 0)
      @page_first = Page.gen(:volume => @vol_first )

      doc_test_second = {:vol_jobid => "238233", :bok_bibid => "456"}
      doc_test_second[:bok_title] = "Test Book Second"
      doc_test_second[:name] = ["Name2","Name3"]
      doc_test_second[:author] = "Author"
      doc_test_second[:bok_language]="English"
      doc_test_second[:geo_location]="Egypt"
      doc_test_second[:subject]="subject"

      solr = RSolr.connect :url => SOLR_BOOKS_METADATA
      # remove this book if exists
      solr.delete_by_query('vol_jobid:238233')
      solr.commit
      solr.add doc_test_second
      solr.commit

      @book_test_second = Book.gen(:title => 'Test Book second', :bibid => '456')
      @vol_second = Volume.gen(:book => @book_test_second, :job_id => '238233', :get_thumbnail_fail => 0)
      @page_second = Page.gen(:volume => @vol_second )

      PageName.gen(:page => @page_second, :name => @name2, :namestring => "Name2")
      PageName.gen(:page => @page_second, :name => @name3, :namestring => "Name3")
      PageName.gen(:page => @page_first, :name => @name1, :namestring => "Name1")
      PageName.gen(:page => @page_first, :name => @name2, :namestring => "Name2")
    end

    # check for existance of image for each book in gallery view
    it "should have an image for each book in list view" do
      get :index, :view => "list"
      response.should have_selector('a>img', :src => "/volumes/123/thumb.jpg")
      response.should have_selector('a>img', :src => "/volumes/238233/thumb.jpg")
    end

    # check for existance of image for each book in gallery view
    it "should have an image for each book in gallery view" do
      get :index, :view => "gallery"
      response.should have_selector('a>img', :src => "/volumes/123/thumb.jpg")
      response.should have_selector('a>img', :src => "/volumes/238233/thumb.jpg")
    end

    # check for books count
    it "should return item count equal to the total number of books" do
      get :index
      response.should have_selector("div", :class => "count", :content => 2.to_s)
    end

    it "returns http success" do
      get :index
      response.should be_success
    end

    # check for existance of detail link for each book in list view
    it "should return detail link for each book in list view" do
      get :index, :view => "list"
      response.should have_selector('a', :href => "/books/123" ,:content => "Test Book First")
      response.should have_selector('a', :href => "/books/238233", :content => "Test Book Second")
    end

    # check for existance of detail link for each book in gallery view
    it "should return detail link for each book in gallery view" do
      get :index, :view => "gallery"
      response.should have_selector('a', :href => "/books/123" ,:content => "Test Book First")
      response.should have_selector('a', :href => "/books/238233", :content => "Test Book Second")
    end

    # check for existance of read and detail links for each book in list view
    it "should return read and detail links for each book in list view" do
      get :index, :view => "list"
      response.should have_selector('a', :href => "/books/123/read")
      response.should have_selector('a', :href => "/books/123")
      response.should have_selector('a', :href => "/books/238233/read")
      response.should have_selector('a', :href => "/books/238233")
    end

    # check for existance of read and detail images for each book in list view
    it "should return read and detail images for each book in list view" do
      get :index, :view => "list"
      response.should have_selector('img', :src => "/images_en/read.png")
      response.should have_selector('img', :src => "/images_en/learn.png")
    end

    # check for existance of open link for each author with the count of books for each author
    it "should have open links for authors" do
      get :index
      response.should have_selector('a', :href => "/books?_author=Author", :content => "Author [2]")
    end

    # check for existance of open link for each names with the count of books for each name
    it "should have open links for names" do
      get :index
      response.should have_selector('a', :href => "/books?_name=Name1", :content => "Name1 [1]")
      response.should have_selector('a', :href => "/books?_name=Name2", :content => "Name2 [2]")
      response.should have_selector('a', :href => "/books?_name=Name3", :content => "Name3 [1]")
    end

    # check for existance of open link for each language with the count of books for each language
    it "should have open links for languages" do
      get :index
      response.should have_selector('a', :href => "/books?_language=English", :content => "English [2]")
    end

    # check for existance of open link for each location with the count of books for each location
    it "should have open links for geo locations" do
      get :index
      response.should have_selector('a', :href => "/books?_geo_location=Egypt", :content => "Egypt [2]")
    end

    # check for existance of open link for each subject with the count of books for each subject
    it "should have open links for subjects" do
      get :index
      response.should have_selector('a', :href => "/books?_subject=subject", :content => "subject [2]")
    end

    # check for existance of the search bar
    it "should have a search bar" do
      get :index
      response.should have_selector("div", :class => "searchtitle")
    end

    # check for existance of the pagination bar
    it "should have a pagination bar" do 
      truncate_table(ActiveRecord::Base.connection, "books", {})
      truncate_table(ActiveRecord::Base.connection, "volumes", {})
      solr = RSolr.connect :url => SOLR_BOOKS_METADATA
      22.times{ |i|
            doc_test = {:vol_jobid => i.to_s, :bok_bibid => "456"}
            doc_test[:bok_title] = "Test Book"
            #doc_test_first[:name] = "Test Name"
            doc_test[:author] = "Author"
            doc_test[:bok_language]="English"
            doc_test[:geo_location]="Egypt"
            doc_test[:subject]="subject"
            
            # remove this book if exists
            solr.delete_by_query('vol_jobid:'+i.to_s)
            solr.commit
            solr.add doc_test
            solr.commit  
            @book_test = Book.gen(:title => 'Test Book', :bibid => '456')
            Volume.gen(:book => @book_test, :job_id => i.to_s, :get_thumbnail_fail => 0)
      }
      get :index
      response.should have_selector("ul", :id => "pagination") 
      solr = RSolr.connect :url => SOLR_BOOKS_METADATA
      solr.delete_by_query('*:*')
      22.times{ |i| Volume.delete(i) }
    end

    # check for existance of gallery and list view options
    it "should have links for gallery and list views" do
      get :index
      response.should have_selector("a", :href => "/books?view=gallery")
      response.should have_selector("a", :href => "/books?view=list")
    end

    it "should have images for gallery and list views" do
      get :index
      response.should have_selector("img", :src => "/images_en/list.png")
      response.should have_selector("img", :src => "/images_en/gallery.png")
    end

    # check for existance of the right column
    it "should have the right column" do
      get :index
      response.should have_selector("h3", :content => "TAGGED SPECIES")
      response.should have_selector("h3", :content => "LANGUAGES")
      response.should have_selector("h3", :content => "AUTHORS")
      response.should have_selector("h3", :content => "REGIONAL AFFILIATION")
      response.should have_selector("h3", :content => "GENRE")
    end

    # check for existance of By:authors label in list view
    it "should have by author" do
      get :index, :view => "list"
      response.should have_selector("div", :class => "description", :content => "By")
    end

    # check for existance div.gallery in gallery view
    it "should have gallery div" do
      get :index, :view => "gallery"
      response.should have_selector("div", :class => "gallery")
    end

  end
end
