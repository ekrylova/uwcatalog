module UwCatalog

  class VoyagerSql

    def self.get_bibliographic_sql()
      "select distinct bib_text.bib_id as bibid, bib_text.author as author, bib_text.title_brief as title, " + 
      "bib_text.edition, bib_text.pub_place, bib_text.publisher as publisher, bib_text.publisher_date as publish_date " +
      "from bib_text, bib_mfhd, mfhd_master, location " + 
      "where bib_text.bib_id=? " + 
      "and bib_text.bib_id=bib_mfhd.bib_id " + 
      "and bib_mfhd.mfhd_id=mfhd_master.mfhd_id " + 
      "and mfhd_master.location_id=location.location_id " + 
      "and location.suppress_in_opac='N'"
    end

    def self.get_holdings_with_items_sql()
      "select distinct mfhd_master.mfhd_id as holding_id," + 
      "mfhd_master.location_id, " +
      "hloc.location_display_name as location," +
      "item.temp_location as temp_location_id," +          
      "iloc.location_display_name as temp_location," +  
      "mfhd_master.display_call_no," + 
      "mfhd_item.item_enum," +     
      "item.item_id, " +
      "item.copy_number," +
      "item.on_reserve, " +
      "item.item_type_id," +
      "item_barcode.item_barcode, " +
      "item_status.item_status, " +
      "item_status.item_status_date," +
      "circ_transactions.current_due_date, " +
      "hold_recall_items.hold_recall_status_date " +
      "from bib_mfhd, mfhd_master, location hloc, location iloc, mfhd_item, item, item_status, item_barcode " +
      ", circ_transactions, hold_recall_items " +
      "where bib_mfhd.bib_id=? " + 
      "and bib_mfhd.mfhd_id=mfhd_master.mfhd_id " +
      "and mfhd_master.suppress_in_opac='N' " +
      "and mfhd_master.location_id=hloc.location_id " + 
      "and hloc.suppress_in_opac='N' " +
      "and mfhd_master.mfhd_id=mfhd_item.mfhd_id " +
      "and mfhd_item.item_id=item.item_id " +
      "and item.temp_location=iloc.location_id (+) " + 
      "and item.item_id=item_status.item_id " +
      "and item.item_id=item_barcode.item_id " + 
      "and item_barcode.barcode_status=1 " +
      "and item.item_id=circ_transactions.item_id (+) " +
      "and item.item_id=hold_recall_items.item_id (+) "
    end

    def self.get_holdings_without_items_sql()
      "select distinct mfhd_master.mfhd_id as holding_id," + 
      "mfhd_master.location_id, " +
      "location.location_display_name as location," + 
      "null as temp_location_id," +
      "null as temp_location," +  
      "mfhd_master.display_call_no," +  
      "null as item_enum, " +  
      "null as item_id, " +
      "null as copy_number, " +
      "null as perm_location, " +
      "null as temp_location, " +
      "null as on_reserve, " +
      "null as item_type_id," +
      "null as item_barcode, " +
      "null as item_status, " +
      "null as item_sequence_number," + 
      "null as item_status_date," +
      "null as current_due_date, " + 
      "null as hold_recall_status_date " + 
      "from bib_mfhd, mfhd_master, location " +
      "where bib_mfhd.bib_id=? " + 
      "and bib_mfhd.mfhd_id=mfhd_master.mfhd_id " +
      "and mfhd_master.location_id=location.location_id " + 
      "and mfhd_master.suppress_in_opac='N' " +
      "and location.suppress_in_opac='N' " +
      "and not exists (select 'x' from mfhd_item mi where mi.mfhd_id = mfhd_master.mfhd_id)"
    end

  end
end
