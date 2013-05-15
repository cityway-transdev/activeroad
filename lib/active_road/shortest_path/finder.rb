# This class find the shortest path between a departure and an arrival with : 
#   - weight functions
#   - tags to find selected physical roads 
#
# A classic result would be with a point for departure and arrival : 
# Paths ==> Path 1      : Access Link => Access Point
#       |=> Path 2      : Access Point => Junction
#       |=> Path ...    : Junction => Junction 
#       |=> Path n-1    : Junction => Access Point 
#       |=> Path n      : Access Point => Access Link 


require 'shortest_path/finder'

class ActiveRoad::ShortestPath::Finder < ShortestPath::Finder

  attr_accessor :road_kind, :tags

  def initialize(departure, arrival, tags = {}, road_kind = "road")
    super departure, arrival
    @road_kind = road_kind
    @tags = tags
  end

  def visited?(node)
    super(respond_to?(:arrival) ? node.arrival : node)
  end

  def visit(node)
    super(respond_to?(:arrival) ? node.arrival : node)
  end

  def destination_accesses 
    @destination_accesses ||= ActiveRoad::AccessPoint.to(destination, tags, road_kind)
  end

  def search_heuristic(node)
    shortest_distances[node] + distance_heuristic(node)
  end

  def follow_way?(node, destination, weight)
    search_heuristic(node) + weight < distance_heuristic(source) * 10
  end

  def distance_heuristic(node)
    if node.respond_to?(:arrival)
      node.arrival.to_geometry.spherical_distance(destination)
    else
      node.to_geometry.spherical_distance(destination)
    end
  end

  def ways(node)

    paths = 
      if GeoRuby::SimpleFeatures::Point === node
        ActiveRoad::AccessLink.from(node, tags, road_kind)
      else
        node.paths(tags, road_kind)
      end

    unless GeoRuby::SimpleFeatures::Point === node # For the first point to access physical roads
      destination_accesses.select do |destination_access|
        if node.access_to_road?(destination_access.physical_road)
          paths << ActiveRoad::Path.new(:departure => node.arrival, :arrival => destination_access, :physical_road => destination_access.physical_road)
        end
      end
    end    
    
    array = paths.collect do |path|
      [ path, path.respond_to?(:length) ? path.length : 0 ]
    end

    Hash[array]
  end

  def geometry
    @geometry ||= GeoRuby::SimpleFeatures::LineString.merge path.collect { |n| n.to_geometry }.select { |g| GeoRuby::SimpleFeatures::LineString === g }
  end

  # Use to profile code
  def self.example
    from = (ENV['FROM'] or "30.030238,-90.061541")
    to = (ENV['TO'] or "29.991739,-90.06918")
    kind = (ENV['KIND'] or "road")

    ActiveRoad::ShortestPath::Finder.new GeoRuby::SimpleFeatures::Point.from_lat_lng(from), GeoRuby::SimpleFeatures::Point.from_lat_lng(to), kind
  end

end
