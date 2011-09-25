class LocationController < ApplicationController
  layout "frontend"
  
  def index
    coordinates = [51.518784,-0.628209]

    @map = GMap.new("map")
    @map.control_init(:large_map => true, :map_type => true)
    @map.center_zoom_init(coordinates,14)
    @map.overlay_init(GMarker.new(coordinates,:title => "Navy Pier", :info_window => "Navy Pier"))
    
  end

end
