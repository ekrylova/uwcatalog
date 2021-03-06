module UwCatalog
  class Item
    attr_accessor :id, :item_enum, :copy_number, :on_reserve, :item_status, 
                  :item_barcode, :item_type_id,   
                  :item_status_date, :current_due_date, :hold_recall_status_date

    def initialize(h=Hash.new)
      h.each {|k,v| send("#{k}=",v)}
    end

    def ==(another_item)
      self.id == another_item.id
    end

  end
end
