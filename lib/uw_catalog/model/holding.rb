module UwCatalog
  class Holding
    @@date_format = "%d %B, %Y"
    attr_accessor :id, :call_number, :items

    def initialize(h=Hash.new)
      @items = Array.new
      h.each {|k,v| send("#{k}=",v)}
    end

    def  ==(another_holding)
      self.id == another_holding.id
    end

    def get_copies
      copies = items.collect {|c| c.copy_number}.uniq
    end

    def get_items_display
      copies = get_copies
      if (copies.size == items.size) 
        ret = one_item_per_copy
      else
        ret = multiple_items_per_copy(copies)
      end
    end

    def one_item_per_copy
      ret = Hash.new
      items.each do |item|
        status_code, status_text = get_status(item)
        ret[:status_available] = status_code unless status_code.nil?
        ret[:status_text] = status_text unless status_text.nil?
      end
      ret
    end

    def multiple_items_per_copy(copies)
      ret = Hash.new
      ret
    end

    def get_status(item)
      status_guide = VoyagerItemStatus.status_guide(item.item_status.to_i)
      status_code = status_guide[:available]
      status_text = status_guide[:forward_status]
      ret = status_text
      status_date = nil
      if status_guide[:display_date]
        if !item.current_due_date.nil? 
          status_date = item.current_due_date.strftime(@@date_format)
          status_text = "#{status_text}, Due on #{status_date}."
        end
      end
      return [status_code, status_text]
   end

  end
end
