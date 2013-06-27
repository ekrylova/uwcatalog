module UwCatalog
  class ItemsListing
    attr_accessor :holding_id, :location_id, :location_display_name, :display_call_no, :item_id, :item_status,
                :item_status_date, :current_due_date, :hold_recall_status_date, :item_barcode, :on_reserve
  end
end
