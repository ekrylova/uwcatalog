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
                     :item_status=>d[:item_status],     
                     :item_barcode=>d[:item_barcode], :item_sequence_number=>d[:item_sequence_number],
                     :item_status_date=>d[:item_status_date], :current_due_date=>d[:current_due_date], 
                     :hold_recall_status_date=>d[:hold_recall_status_date]})
    end

    def self.get_items(bibid)
      ret = Array.new
      begin
        data_hash = Catalog.get_items_data_hash(bibid)
        data_hash.each do |d|
          loc = Location.new({:id => d[:location_id], :location => d[:location], 
                              :temp_location_id => d[:temp_location_id], :temp_location => d[:temp_location]})
          idx = ret.index(loc)
          if (idx.nil?)
            ret << loc
          else
            loc = ret.at(idx)
          end
          h = Holding.new({:id=>d[:holding_id], :call_number => d[:display_call_no]})
          holding = loc.get_holding(h)
          if (holding.nil?)
            loc.add_holding(h)
            holding = h
          end
          if (!d[:item_id].nil?)
puts d[:item_id]
            item = get_item_from_hash(d) 
            holding.items << item
          end
        end
        ret
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
