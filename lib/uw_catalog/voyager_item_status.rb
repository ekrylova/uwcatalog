module UwCatalog
  class VoyagerItemStatus
    ITEM_STATUSES = 
      {
        0 => { :voyager_identifer => 0, :available => false, :forward_status => "Unknown", :display_date => false, :rank => 25 },
        1 => { :voyager_identifer => 1, :available => true, :forward_status => "Available", :display_date => false, :rank => 20 },
        2 => { :voyager_identifer => 2, :available => false, :forward_status => "Checked Out", :display_date => true, :rank => 7 },
        3 => { :voyager_identifer => 3, :available => false, :forward_status => "Checked Out", :display_date => true, :rank => 8 },
        4 => { :voyager_identifer => 4, :available => false, :forward_status => "Overdue", :display_date => true, :rank => 9 },
        5 => { :voyager_identifer => 5, :available => false, :forward_status => "Recalled", :display_date => true, :rank => 14 },
        6 => { :voyager_identifer => 6, :available => false, :forward_status => "Requested", :display_date => true, :rank => 15 },
        7 => { :voyager_identifer => 7, :available => false, :forward_status => "On Hold", :display_date => true, :rank => 10 },
        8 => { :voyager_identifer => 8, :available => false, :forward_status => "In Transit", :display_date => true, :rank => 11 },
        9 => { :voyager_identifer => 9, :available => false, :forward_status => "In Transit", :display_date => true, :rank => 12 },
        10 => { :voyager_identifer => 10, :available => false, :forward_status => "In Transit", :display_date => true, :rank => 13 },
        11 => { :voyager_identifer => 11, :available => true, :forward_status => "Available", :display_date => false, :rank => 19 },
        12 => { :voyager_identifer => 12, :available => false, :forward_status => "Missing", :display_date => true, :rank => 5 },
        13 => { :voyager_identifer => 13, :available => false, :forward_status => "Lost", :display_date => true, :rank => 4 },
        14 => { :voyager_identifer => 14, :available => false, :forward_status => "Lost", :display_date => true, :rank => 3 },
        15 => { :voyager_identifer => 15, :available => false, :forward_status => "Missing", :display_date => true, :rank => 23 },
        16 => { :voyager_identifer => 16, :available => false, :forward_status => "Damaged", :display_date => true, :rank => 24 },
        17 => { :voyager_identifer => 17, :available => false, :forward_status => "Withdrawn", :display_date => true, :rank => 25 },
        18 => { :voyager_identifer => 18, :available => false, :forward_status => "At Bindery", :display_date => true, :rank => 6 },
        19 => { :voyager_identifer => 19, :available => true, :forward_status => "Needed By Circulation Staff", :display_date => false, :rank => 21 },
        20 => { :voyager_identifer => 20, :available => true, :forward_status => "Needed By Cataloging Staff", :display_date => false, :rank => 22 },
        21 => { :voyager_identifer => 21, :available => false, :forward_status => "Scheduled", :display_date => true, :rank => 1 },
        22 => { :voyager_identifer => 22, :available => false, :forward_status => "In Process", :display_date => true, :rank => 2 },
        23 => { :voyager_identifer => 23, :available => false, :forward_status => "Requested", :display_date => true, :rank => 18 },
        24 => { :voyager_identifer => 24, :available => false, :forward_status => "Requested", :display_date => true, :rank => 16 },
        25 => { :voyager_identifer => 25, :available => false, :forward_status => "Requested", :display_date => true, :rank => 17 }
      }
    def self.status_guide(status_code)
      ITEM_STATUSES[status_code]
    end

    def available?(itemStatusCode)
      item_statuses[itemStatusCode][:available]
    end
    
    def forward_status
      item_statuses[itemStatusCode][:forward_status]
    end
    
    def display_date?
      item_statuses[itemStatusCode][:display_date]
    end
    
  end
end
