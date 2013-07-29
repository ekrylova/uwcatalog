module UwCatalog

  class UwCatalogError < RuntimeError; end
  class UwCatalogAccessError < UwCatalogError; end
  class UwCatalogTimeoutError < UwCatalogError; end
  class UwCatalogNotFoundError < UwCatalogError; end

  class Catalog
    def self.get_bibliographic_data(bibid)
      bibs = Array.new
      begin
        sql = VoyagerSql.get_bibliographic_sql
        data = DataLoader.get_data(:UW, sql, bibid)
        data.each do | d |
          bib = BibData.new
          DataLoader.load(d, bib)
          bibs << bib
        end
      rescue => e
        throw UwCatalogError.new("#{e.class}: #{e.message}") 
      end
      bibs
    end

    def self.get_item_from_hash(d)
     item = Item.new({:id => d[:item_id], :item_enum=>d[:item_enum], 
                     :copy_number=>d[:copy_number], :on_reserve=>d[:on_reserve], 
                     :item_status=>d[:item_status], :item_type_id=>d[:item_type_id],     
                     :item_barcode=>d[:item_barcode], 
                     :item_status_date=>d[:item_status_date], :current_due_date=>d[:current_due_date], 
                     :hold_recall_status_date=>d[:hold_recall_status_date]})
    end

    def self.get_availability_data_hash(bibid)
        data_hash = Catalog.get_items_data_hash(bibid)
    end

    def self.parse_availability_data_hash(data_hash)
      ret = Array.new
      data_hash.each do |d|
	loc_id = d[:location_id]
	location = d[:location]
        if !d[:temp_location].nil?
           loc_id = d[:temp_location_id]
	   location = d[:temp_location]
        end

        loc = Location.new({:id => loc_id, :location => location})
        idx = ret.index(loc)
        if (idx.nil?)
          ret << loc
        else
          loc = ret.at(idx)
        end
        h = Holding.new({:id=>d[:holding_id], :call_number => d[:display_call_no], 
                         :item_enum => d[:item_enum],
                         :perm_location_id => d[:location_id], :perm_location => d[:location]})
        holding = loc.get_holding(h)
        if (holding.nil?)
          loc.add_holding(h)
          holding = h
        end
        if (!d[:item_id].nil?)
          item = get_item_from_hash(d) 
	  holding.add_item(item)
        end
      end
      ret
    end

    def self.get_availability_data(bibid)
      ret = Array.new
      begin
        data_hash = get_availability_data_hash(bibid)
        parse_availability_data_hash(data_hash)
      rescue => e
        throw UwCatalogError.new("#{e.class}: #{e.message}") 
      end
    end

    def self.get_items_data_hash(bibid)
      data = Array.new
      begin
        sql = VoyagerSql.get_holdings_with_items_sql
        data = DataLoader.get_data(:UW, sql, bibid)

        sql = VoyagerSql.get_holdings_without_items_sql
        holdings_without_items_data = DataLoader.get_data(:UW, sql, bibid)
        data.concat(holdings_without_items_data)
      rescue => e
        throw UwCatalogError.new("#{e.class}: #{e.message}") 
      end
      data    
    end

  end

end
