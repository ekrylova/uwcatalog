module UwCatalog
  class Location

    attr_accessor :id, :location, :perm_location_id, :perm_location, :holdings

    def initialize(h=Hash.new)
      @holdings = Array.new
      h.each {|k,v| send("#{k}=",v)}
    end

    def ==(another_loc)
      self.id == another_loc.id
    end

    def display_location
      location
    end

    def add_holding(holding)
      idx = @holdings.index(holding)
      if idx.nil?
        holdings << holding
      end
    end

    def get_holding(holding)
      idx = @holdings.index(holding)
      if idx.nil?
        nil
      else
        @holdings.at(idx)
      end
    end

  end
end
