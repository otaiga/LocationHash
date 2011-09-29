class LocationController < ApplicationController
  require 'open-uri'
  require 'json'
  require 'httparty'
  
  layout "frontend"
  
  CLIENT_ID = ENV['CLIENT_ID']
  CLIENT_SECRET = ENV['CLIENT_SECRET']
  
  AUTH_SERVER = "https://hashblue.com"
  API_SERVER = "https://api.hashblue.com"
  
  
    def callback
        # assuming access is granted
        # Call server to get an access token
        response = HTTParty.post(access_token_url, :body => {
          :client_id => CLIENT_ID,
          :client_secret => CLIENT_SECRET,
          :redirect_uri => redirect_uri,
          :code => params["code"],
          :grant_type => 'authorization_code'}
        )
      
        session[:access_token] = response["access_token"]
         redirect_to '/'
        
  end
  
  
    
  def index
      myarray=Array.new
      hello = String.new
    # coordinates = []
     if session[:access_token]
        # authorized so request the messages from #blue
        @messages_response = get_with_access_token("/messages.json")
        case @messages_response.code
        when 200
          @messages = @messages_response["messages"]
           @messages.reverse.each {|message| if message["content"].last(10) == "#locations" 
             hello = message["content"] end
             }      
            hello.split(/\s/).each {|x| myarray << x} 
            
            coordinates = [myarray[0],myarray[1]]
            puts coordinates
            
            @map = GMap.new("map")
            @map.control_init(:large_map => true, :map_type => true)
            @map.center_zoom_init(coordinates,14)
            @map.overlay_init(GMarker.new(coordinates,:title => "Here I am", :info_window => "Here I Am"))  
                   
          # redirect_to '/messages'
        when 401
         redirect_to AUTH_SERVER + "/oauth/authorize?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&redirect_uri=http://falling-water-4664.heroku.com/callback"
        else
          "Got an error from the server (#{@messages_response.code.inspect}): #{CGI.escapeHTML(@messages_response.inspect)}"
        end
      else
        # No Access token therefore authorize this application and request an access token
        redirect_to "https://hashblue.com/oauth/authorize?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&redirect_uri=http://falling-water-4664.heroku.com/callback"
        puts "ERROR TOKEN #{CLIENT_SECRET}"
      end
    end

    def redirect_uri
      "http://" + request.host_with_port + "/callback"
    end

      def get_with_access_token(path)
        HTTParty.get(API_SERVER + path, :query => {:oauth_token => access_token})
      end

      def access_token
        session[:access_token]
      end

      def authorize_url
        puts "THIS IS THE AUTH URL"
        AUTH_SERVER + "/oauth/authorize?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&redirect_uri=#{redirect_uri}"
      end

      def access_token_url
        AUTH_SERVER + "/oauth/access_token"
      end
    
  end
