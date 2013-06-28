module UwCatalog
  class Holding
    @@date_format = "%d %B, %Y"
    attr_accessor :id, :call_number, :item_enum, :items

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

    def get_items_display
      return Hash.new unless items.size > 0

      copies = get_copies
      if (copies.size == items.size) 
        ret = one_item_per_copy
      else
        ret = multiple_items_per_copy(copies)
      end
    end

    def one_item_per_copy
      ret = Hash.new 
      if (items.nil?)
        return ret
      end

      status_list = Array.new 
      items.each do |item|
        status_available, status_text = get_status(item)
        status_list <<  {:item_id => item.id, :status_text => status_text, 
                 :available => status_available, :copy_number=> item.copy_number, :item_enum => item.item_enum}
      end

      status_list.sort! {|a,b| a[:item_enum].to_s <=> b[:item_enum].to_s} unless status_list.size ==0
      ret[:status] = status_list
      ret
    end

    def multiple_items_per_copy(copies)
      one_item_per_copy
    end

    def get_status(item)
      status_guide = VoyagerItemStatus.status_guide(item.item_status.to_i)
      status_available = status_guide[:available]
      status_text = status_guide[:forward_status]
      ret = status_text
      status_date = nil
      if status_guide[:display_date]
        if !item.current_due_date.nil? 
          status_date = item.current_due_date.strftime(@@date_format)
          status_text = "#{status_text}, Due on #{status_date}."
        elsif !item.hold_recall_status_date.nil?
          status_date = item.hold_recall_status_date.strftime(@@date_format)
          status_text = "#{status_text} #{status_date}."
        end
      end
      return [status_available, status_text]
   end

  end
end
