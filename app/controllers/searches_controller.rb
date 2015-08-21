require 'net/http'
require 'htmlentities'
require 'httparty'
require 'billit_representers/models/bill_basic'
require 'billit_representers/models/bill_page'
require 'popit_representers/models/organization_collection'
require './app/models/bill'
require './app/models/bill_basic'

class SearchesController < ApplicationController
  def index
    @bills_query = Hash.new
    coder = HTMLEntities.new
    
    if !ENV['popit_persons'].blank? and !ENV['popit_organizations'].blank? and !ENV['billit_url'].blank? and !ENV['popit_search'].blank?
      response = HTTParty.get(ENV['popit_persons'])
      json_response = JSON.parse(response.body)
      authors_detail_list = json_response['result']

      @authors_list = []
      @persons_query = []
      authors_detail_list.map do |author|
        @authors_list.push(author['name'])
      end

      @organizations = Popit::OrganizationCollection.new
      @organizations.get ENV['popit_organizations'], 'application/json'

      @congressmen = PopitPersonCollection.new

      if !params.nil? && params.length > 3 # default have 3 keys {'action'=>'index', 'controller'=>'searchs', "locale"=>"xx"}
        
        if ! ( params[:bills] == '1' && params[:congressmen] == '2' ) # make a redirect in case of someone pick just one filter in main page
          # redirect to bills advanced search
          if params[:bills] == '1' || params[:congressmen] == ''
            redirect_to searches_bills_path(params)
          end
          # redirect to congressmen advanced search
          if params[:congressmen] == '2' || params[:bills] == ''
            redirect_to searches_congressmen_path(params)
          end
        end

        @keywords = String.new
        params.each do |key, value|
          if key != 'utf8' && key != 'commit' && key != 'format' && key != 'locale' && key != 'action' && key != 'controller'
            @keywords << key + '="' + coder.encode(value) + '"&'
          end
        end
        if params['authors'] != nil
          @authors_list = []
          authors_detail_list.map do |author|
            if params['authors'] == author['name']
              @persons_query.push(author)
            end
          end
        end
        @bills_query = Billit::BillPage.get(ENV['billit_url'] + "search.json/?#{URI.encode(@keywords)}per_page=3", 'application/json')
        @congressmen.get ENV['popit_search']+"#{URI.encode(@keywords)}per_page=3", 'application/json'
        @congressmen.result.each do |congressman|
          #monkey patch to solve bad design decisions
          congressman.images = Array.new
          congressman.images[0] = congressman.image
        end
        
      else
        @bills_query = Billit::BillPage.get(ENV['billit_url'] + "search.json/?per_page=3", 'application/json')
        @congressmen.get ENV['popit_search']+"per_page=3", 'application/json'
      end

      @title =  t('search.search_results') + ' - '
    end
  end
end
