module MainsHelper
  def congressmen_profile(name)
    #query = sprintf('select * from data where name = "%s" limit 1', I18n.transliterate(name))
    #query = URI::escape(query) 
    response = RestClient.get(ENV['popit_search']+'q=name:'+URI::escape(name), :content_type => :json, :accept => :json)
    #response = RestClient.get(ENV['congressmen_helper_url'] + query, :content_type => :json, :accept => :json, :"x-api-key" => ENV['morph_io_api_key'])
    response = JSON.parse(response)
    result = response['result'][0]

    if !response.nil?
      return {'id' => result['id'], 'name' => result['name'], 'image' => result['image']}
    else
      return {'id' => 0, 'name' => name, 'image' => nil}
    end
  end

  def congressmen_pic(name, img)

    fantasy_name = Rack::Utils.escape(I18n.transliterate(name.gsub("'", "")))
    url_image = open('app/assets/images/default-profile.png')
    
    if !File.exist?('app/assets/images/congressman/'+fantasy_name+'.jpg')
      image = Magick::ImageList.new
      begin
        Timeout.timeout(5) do
          #puts "Imagen: " << img
          url_image = open('app/assets/images/congressman/'+fantasy_name+'.jpg')
        end
      rescue Timeout::Error
        url_image = open('app/assets/images/default-profile.png')
      end
      image.from_blob(url_image.read)
      crop = image.crop(ENV['congressman_pic_x'].to_i,ENV['congressman_pic_y'].to_i,ENV['congressman_pic_w'].to_i,ENV['congressman_pic_h'].to_i)
      crop.write('app/assets/images/congressman/'+fantasy_name+'.jpg')
    end
    return fantasy_name
  end
end
