module UwCatalog
  class Location

    attr_accessor :id, :location, :temp_location_id, :temp_location, :holdings

    def initialize(h=Hash.new)
      @holdings = Array.new
      h.each {|k,v| send("#{k}=",v)}
    end

    def ==(another_loc)
      self.id == another_loc.id
    end

    def display_location
      if !temp_location.nil?
         temp_location
      else
         location
      end
    end

    def add_holding(holding)
      idx = @holdings.index(holding)
      puts "#{idx}"
      if idx.nil?
        holdings << holding
      end
      puts holdings.inspect
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
