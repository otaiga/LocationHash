class LocationController < ApplicationController
  require 'open-uri'
  require 'json'
  require 'httparty'
  require 'bluevia'
    include Bluevia
  
  layout "frontend"
  
  CLIENT_ID = ENV['CLIENT_ID']
  CLIENT_SECRET = ENV['CLIENT_SECRET']
  
  #Blue Via stuff......
  CONSUMER_KEY = ENV['BLUEVIA_KEY']
  CONSUMER_SECRET = ENV['BLUEVIA_SECRET']
  
  #......
  
  
  AUTH_SERVER = "https://hashblue.com"
  API_SERVER = "https://api.hashblue.com"
  
  
    #Blue Via stuff......
   def bluevia
     puts "Bluevia bit:"
     
     #trying something here: 
     
     puts "key =" + CONSUMER_KEY
     puts "secret =" + CONSUMER_SECRET
     
     bc = BlueviaClient.new(
               { :consumer_key   => CONSUMER_KEY,
                 :consumer_secret=> CONSUMER_SECRET,
                 :uri            => "https://api.bluevia.com"
               })
               
                 
     service = bc.get_service(:oAuth)
     token, secret, url = service.get_request_token({:callback =>"http://" + request.host_with_port + "/callbackblue"})
     
      puts "Token= " +token 
      puts "Secrect =" +secret
      puts "url = " + url
          
      response.set_cookie(:token, "#{token}|#{secret}")
      
      redirect_to url 
     
    end

  
  def callbackblue
    oauth_verifier = params[:oauth_verifier]
      get_token_from_cookie

      @bc = BlueviaClient.new(
               { :consumer_key   => CONSUMER_KEY,
                 :consumer_secret=> CONSUMER_SECRET
               })

       @bc.set_commercial

      @service = @bc.get_service(:oAuth)
      @token, @token_secret = @service.get_access_token(@request_token, @request_secret, oauth_verifier)
      
      session[:token] = @token
       session[:token_secret] = @token_secret
      
      redirect_to  '/calllocation'
    end

   
   def calllocation

     @bc = BlueviaClient.new(
               { :consumer_key   => CONSUMER_KEY,
                 :consumer_secret=> CONSUMER_SECRET,
                 :token          => session[:token],
                 :token_secret   => session[:token_secret],
                 :uri            => "https://api.bluevia.com"
               })
   
       @bc.set_commercial
   
     @service = @bc.get_service(:Location)
     location = @service.get_location
   
     latlong = location['terminalLocation']['currentLocation']['coordinates']
   
     @lat = latlong['latitude']
     @lon = latlong['longitude']
     
     
     puts @lat
     puts @lon
     
     session[:lat] = @lat
     session[:lon] = @lon
     
     redirect_to '/' 
   end


   def update
      @bc = BlueviaClient.new(
                { :consumer_key   => CONSUMER_KEY,
                  :consumer_secret=> CONSUMER_SECRET,
                  :token          => session[:token],
                  :token_secret   => session[:token_secret],
                  :uri            => "https://api.bluevia.com"
                })

        @bc.set_commercial

      @service = @bc.get_service(:Location)
      location = @service.get_location

      latlong = location['terminalLocation']['currentLocation']['coordinates']

      @lat = latlong['latitude']
      @lon = latlong['longitude']


      puts @lat
      puts @lon

      session[:lat] = @lat
      session[:lon] = @lon

   end
 #......
  
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
      
     if session[:access_token]
        # authorized so request the messages from #blue
        @messages_response = get_with_access_token("/messages.json")
        case @messages_response.code
        when 200
          @messages = @messages_response["messages"]
           @messages.reverse.each {|message| if message["content"].last(10) == "Where r u?" 
             
             @bc = BlueviaClient.new(
                       { :consumer_key   => CONSUMER_KEY,
                         :consumer_secret=> CONSUMER_SECRET,
                         :token          => session[:token],
                         :token_secret   => session[:token_secret],
                         :uri            => "https://api.bluevia.com"
                       })

               @bc.set_commercial

             @service = @bc.get_service(:Location)
             location = @service.get_location

             latlong = location['terminalLocation']['currentLocation']['coordinates']

             @lat = latlong['latitude']
             @lon = latlong['longitude']

             session[:lat] = @lat
             session[:lon] = @lon
             
           end
         }
            coordinates = [session[:lat], session[:lon]]
            puts coordinates
            
            @map = GMap.new("map")
            @map.control_init(:large_map => true, :map_type => true)
            @map.center_zoom_init(coordinates,14)
            @map.overlay_init(GMarker.new(coordinates,:title => "Here I am", :info_window => "Here I Am")) 
            
            #HASHBLUE STUFF HERE!
            
            
            
            
            
            
             
                   
        when 401
         redirect_to AUTH_SERVER + "/oauth/authorize?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&redirect_uri=http://" + request.host_with_port + "/callback"
        else
          "Got an error from the server (#{@messages_response.code.inspect}): #{CGI.escapeHTML(@messages_response.inspect)}"
        end
      else
        # No Access token therefore authorize this application and request an access token
        redirect_to "https://hashblue.com/oauth/authorize?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&redirect_uri=http://" + request.host_with_port + "/callback"
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
    
    
    def get_token_from_cookie

      cookie_token = request.cookies['token']
      cookie_token = cookie_token.split("|")
      if cookie_token.size != 2
           raise SyntaxError, "The cookie is not valid"
         end     
       @request_token = cookie_token[0]
       @request_secret = cookie_token[1]

    end
    
  end
  

 
