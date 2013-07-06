module UwCatalog
  class Holding
    @@date_format = "%B %d, %Y"
    attr_accessor :id, :call_number, :item_enum, :perm_location_id, :perm_location, :items

    def initialize(h=Hash.new)
      @items = Array.new
      h.each {|k,v| send("#{k}=",v)}
    end

    def  ==(another_holding)
      self.id == another_holding.id
    end

    def get_copies
      if items.nil?
	return Array.new
      end
      copies = items.collect {|c| c.copy_number}.uniq
    end
    
    def self.get_item_rank(item)
      status_guide = VoyagerItemStatus.status_guide(item.item_status.to_i)
      status_guide[:rank]
    end

    def self.override_status(item)
      (16 == item.item_status.to_i)
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

    def get_items_display(concise = false)
      ret = Hash.new
      return ret unless items.size > 0

      status_list = Array.new 

      items.each do |item|
        status_available, status_text = get_status(item)
        status_list <<  {:item_id => item.id, :status_text => status_text,
               :available => status_available, :copy_number=> item.copy_number, :item_enum => item.item_enum}
      end
      if (concise)
        total_count = status_list.size
        status_list.keep_if{|i| i[:available] == false}.compact
        if (total_count > 0 && status_list.size == 0)
          status_list << {:status_text => 'Available', :available => true}
        end
      end

      status_list.sort! {|a,b| a[:item_enum].to_s <=> b[:item_enum].to_s} unless status_list.size < 1
      ret[:status] = status_list
      ret
    end

    def get_status(item)
      status_guide = VoyagerItemStatus.status_guide(item.item_status.to_i)
      status_available = status_guide[:available]
      status_text = status_guide[:forward_status]
      ret = status_text
      status_date = nil
      if status_guide[:display_date]
        case item.item_status.to_i
        when 2, 3
          status_date = item.current_due_date.strftime(@@date_format) unless item.current_due_date.nil?
          if (!item.item_enum.nil?)
            status_text = "#{item.item_enum} Not Available - #{status_text}, Due on #{status_date}"
          else
            status_text = "Not Available - #{status_text}, Due on #{status_date}."
          end
        else  
          status_date = item.item_status_date.strftime(@@date_format) unless item.item_status_date.nil?
          if (!item.item_enum.nil?)
            status_text = "#{item.item_enum} Not Available - #{status_text} #{status_date}"
          else
            status_text = "#{status_text} #{status_date}."
          end
        end
      end
      return [status_available, status_text]
   end

  end
end
