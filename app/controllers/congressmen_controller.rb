require 'popit_representers/models/organization_collection'
require 'billit_representers/models/bill_page'
require './app/models/bill'
require './app/models/bill_basic'
require 'RMagick'
require 'open-uri'
require 'popit_representers/models/personmembership'
require 'popit_representers/models/organization'

class CongressmenController < ApplicationController
  caches_page :index, :show
  
  # GET /congressmen
  def index
    @congressmen =  Hash.new
    @organizations = Hash.new

    if !ENV['popit_url'].blank? and !ENV['popit_persons'].blank? and !ENV['popit_search'].blank? and !ENV['popit_organizations'].blank? and !ENV['popit_organizations_search'].blank?
      @congressmen = PopitPersonCollection.new
      begin
        @congressmen.get ENV['popit_persons']+'?per_page=200', 'application/json'
        @congressmen.persons.sort! { |x,y| x.name <=> y.name }
        #@organizations = get_organizations
        @organizations = get_parties
        @chambers =  get_chambers
      rescue => e
        @message = e.response
      end
      
    end
    @title = t('congressmen.title') + ' - '
  end

  # GET /congressmen/1
  def show
    
    @congressmen =  Hash.new
    @organizations = Hash.new
    @message = Hash.new

    if !ENV['billit_url'].blank? and !ENV['popit_url'].blank? and !ENV['popit_persons'].blank? and !ENV['popit_search'].blank? and !ENV['popit_organizations'].blank? and !ENV['popit_organizations_search'].blank?
      @congressman = PopitPerson.new
      @congressman.get ENV['popit_persons']+params[:id]+'?include_root=false', 'application/json'
      
      if !@congressman.name.blank?

        @bills = (Billit::BillPage.get ENV['billit_url']+'search.json?authors='+URI::escape(@congressman.name)+ '&per_page=3', 'application/json').bills
        @congressman.commissions = Array.new
        orgs_querystring = ''
        @congressman.memberships.each do |membership|
          if orgs_querystring == ''
            orgs_querystring += 'q=id:'+membership.organization_id
          else
            orgs_querystring += '+and+'+membership.organization_id
          end
        end
        @organizations = Popit::OrganizationCollection.new
        @organizations.get ENV['popit_organizations_search']+orgs_querystring, 'application/json'
        @organizations.result.each do |org|  
          if org.classification == 'Party'
            @congressman.party = {'id' => org.id, 'name' => org.name}
          #remove party from list
          elsif org.classification == 'Chamber'
            @congressman.chamber = org
          else #org.classification == 'Comision'
            #append to commisions list
            @congressman.commissions.push(org)
          end
        end
       
        @congressman.commissions = @congressman.commissions.uniq
        #setup the title page
        @title = @congressman.name + " - "
     
        @el_twitter = ''
        @congressman.links.each do | link |
          case link.note.downcase
          when 'twitter'
            @el_twitter = URI(link.url).path.sub! '/', '@'
          end
        end

        @district = ''
        @region = ''
        @congressman.represent.each do | r |
          if ! r.district.blank?
            @district = r.district
          end
          if ! r.region.blank?
            @region = r.region
          end
        end
        
        if !ENV['writeit_base_url'].blank? and !ENV['writeit_url'].blank? and !ENV["writeit_username"].blank? and !ENV["writeit_api_key"].blank? and !ENV["writeit_messages_per_page"].blank?
          messages = LegislativeMessageCollection.new
          messages.get(person: @congressman)
          @message = messages.objects[0]
        end
      else
        flash[:notice] = t('bill.bill_dont_exist')
        redirect_to url_for :controller => 'congressmen', :action => 'searches'
      end
    end
  end

  # GET /congressmen/new
  def new
  end

  # GET /congressmen/1/edit
  def edit
  end

  # POST /congressmen
  def create
  end

  # PATCH/PUT /congressmen/1
  def update
  end

  # DELETE /congressmen/1
  def destroy
  end

  def searches
    
    if !ENV['popit_organizations'].blank?
      @organizations = get_parties
      @chambers = get_chambers
      @title = t('congressmen.title_search') + ' - '
      if !params.nil? && params.length > 3
        keywords = Hash.new
        params.each do |key, value|
          if key != 'utf8' && key != 'congressmen' && key != 'locale' && key != 'format' && key != 'controller' && key != 'action'
            keywords.merge!(key => value)
          end
        end
        keywords.delete_if { |k, v| v.empty? }
      else
      end
      get_author_results keywords
    end
  end

  # GET organizations from Popit
  def get_organizations
    organizations = Popit::OrganizationCollection.new
    organizations.get ENV['popit_organizations'], 'application/json'
    organizations = organizations.result.sort! { |x,y| x.name <=> y.name }
    return organizations
  end

  # GET parties from Popit, we don't assume there's only parties as popit organization
  def get_parties
    organizations = Popit::OrganizationCollection.new
    organizations.get ENV['popit_organizations_search'] + 'q=classification:party',
                      'application/json'
    organizations = organizations.result.sort! { |x,y| x.name <=> y.name }
    return organizations
  end

  #TODO get chambers
  def get_chambers
    organizations = Popit::OrganizationCollection.new
    organizations.get ENV['popit_organizations_search'] + 'q=classification:chamber',
                      'application/json'
    organizations = organizations.result.sort! { |x,y| x.name <=> y.name }
    return organizations
  end
    
  def get_author_results keywords
    @congressmen = PopitPersonCollection.new
#    @congressmen.get ENV['popit_persons']+'?per_page=200', 'application/json'
    
    if keywords.has_key? 'congressman'
      #if keywords has congressma then get only that member
      c = PopitPerson.new
      c.get ENV['popit_persons']+keywords['congressman']+'?include_root=false', 'application/json'
      @congressmen.result = [c]
      
    elsif keywords.has_key? 'chambers' or keywords.has_key? 'organizations'
      url = nil
      if keywords.has_key? 'chambers'
        url = ENV['popit_organizations'] + keywords['chambers']
      elsif keywords.has_key? 'organizations'
        url = ENV['popit_organizations'] + keywords['organizations']
      else
        url = ENV['popit_organizations']
      end
      
      congressmen_tmp = PopitPersonCollection.new
      congressmen_tmp.result = Array.new
      congressmen_tmp.get ENV['popit_persons']+'?per_page=200', 'application/json'
      
      raw_response = RestClient.get url
      response = JSON.parse(raw_response)
      @congressmen = PopitPersonCollection.new
      @congressmen.result = Array.new
      
      if !response.blank?
        response['result']['memberships'].each do |mem|
          congressmen_tmp.persons.each do |congressman|
            if mem['person_id'] == congressman.id
              record = congressman
              # record = PopitPerson.new
              # record.id = congressman.uid
              # record.name = congressman.name
              # record.title = congressman.chamber
              # record.images = Array.new
              # record.images[0] = Popit::Personimage.new
              # record.images[0].url = congressman.image
              # record.represent = Array.new
              # record.represent[0] = Popit::Personrepresent.new
              # record.represent[0].region = congressman["region"]
              @congressmen.persons.push record
              @congressmen.persons.sort! { |x,y| x.name <=> y.name }
              break
            end 
          end
        end
      end
    end
  end
end
