module ActiveRoad
  class Boundary < ActiveRoad::Base
    acts_as_copy_target
    set_rgeo_factory_for_column(:geometry, RgeoExt.cartesian_factory)
    #attr_accessible :objectid, :geometry, :name, :admin_level, :postal_code, :insee_code   
    
    # Contains not take object equals on a boundary border!!
    def self.first_contains(other)
      where("ST_Contains(geometry, ST_GeomFromEWKT(E'#{other.as_hex_ewkb}'))").first
    end

    def self.all_intersect(other)
      where("ST_Intersects(geometry, ST_GeomFromEWKT(E'#{other.as_hex_ewkb}'))")
    end
    
  end  
end
