module UwCatalog
  class Holding
    attr_accessor :id, :call_number, :item_enum, :perm_location_id, :perm_location, :items

    def initialize(h=Hash.new)
      @items = Array.new
      h.each {|k,v| send("#{k}=",v)}
    end

    def  ==(another_holding)
      self.id == another_holding.id
    end

    def library_has
      ret = Hash.new
      marc = HoldingMarc.new(@id)
      val = marc.bound_copies
      ret[:bound_copies] = val unless (val.nil? or val.empty?) 
      val = marc.indexes
      ret[:indexes] = val unless (val.nil? or val.empty?) 
      val = marc.supplements
      ret[:supplements] = val unless (val.nil? or val.empty?) 
      ret
    end

    def get_items_display(concise = false)
      ret = Hash.new
      return ret unless items.size > 0

      status_list = item_statuses(concise) 
      ret[:status] = status_list 

      ret
    end
    
    def add_item(item)
      idx = items.index(item)
      if idx.nil?
        items << item
      else
        item_in_list = items.fetch(idx)
        if Holding.override_status(item_in_list)
        elsif Holding.override_status(item)
            items.delete_at(idx)
            items << item
        else 
          if Holding.get_item_rank(item_in_list) > Holding.get_item_rank(item)
            items.delete_at(idx)
            items << item
          end
        end
      end
    end

    private 
    
    def get_copies
      if items.nil?
        return Array.new
      end
      copies = items.collect {|c| c.copy_number}.uniq
    end
    
    def self.override_status(item)
      (16 == item.item_status.to_i)
    end
    
    def self.get_item_rank(item)
      status_guide = VoyagerItemStatus.status_guide(item.item_status.to_i)
      status_guide[:rank]
    end

    def item_statuses(concise)
      status_list = Array.new
      return status_list unless items.size > 0

      items.each do |item|
        status_available, status_text = get_status(item)
        status_list <<  {:item_id => item.id, :status_text => status_text,
               :available => status_available, :copy_number=> item.copy_number,
               :item_enum => item.item_enum,  :item_type_id => item.item_type_id,  
               :noloan => (item.item_type_id == 2)}
      end

      if (concise)
        total_count = status_list.size
        status_list.keep_if{|i| i[:available] == false}.compact
        if (total_count > 0 && status_list.size == 0)
          #reset status list to aggregated view with no specific item data
          status_list << {:status_text => 'Available', :available => true}
          status_list[0][:noloan] = (items.select{|i| i.item_type_id ==2 }.size == items.size)          
        end
      end

      status_list.sort! {|a,b| a[:item_enum].to_s <=> b[:item_enum].to_s} unless status_list.size < 1
    end

    def get_status(item)
      status_guide = VoyagerItemStatus.status_guide(item.item_status.to_i)
      status_available = status_guide[:available]
      status_text = status_guide[:forward_status]
     
      ret = status_text
      status_date = nil
      date_format = "%B %d, %Y"
      
      if status_guide[:display_date]
        case item.item_status.to_i
        when 2, 3
          status_date = item.current_due_date.strftime(date_format) unless item.current_due_date.nil?
          status_text = "#{status_text}, Due on #{status_date}"
        else  
          status_date = item.item_status_date.strftime(date_format) unless item.item_status_date.nil?
          status_text = "#{status_text} #{status_date}"
        end
      end
      return [status_available, status_text]
   end

  end
end
