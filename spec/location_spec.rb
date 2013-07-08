require File.join(File.dirname(__FILE__), "/spec_helper" )
module UwCatalog

  describe Location do
    def load_data_from_file(fname)
        f = File.read("test/data/#{fname}")
        data = YAML::load(f)
        availability_data = UwCatalog::Catalog.parse_availability_data_hash(data) 
    end

    it "non-circulating holding should have no items" do
      availability_data = load_data_from_file('non_circulating_9256425.dat')
      availability_data[0].holdings[0].items.size.should  == 0
      availability_data[0].holdings[0].get_items_display.size.should  == 0
    end

    it "dvd holding should have no items" do
      availability_data = load_data_from_file('dvd_7636968.dat')
      availability_data[0].holdings[0].items.size.should  == 1
      availability_data[0].holdings[0].get_items_display[:status].size.should  == 1
    end


    it "two volume holding with one volume renewed should have due date of that item" do
      availability_data = load_data_from_file('two_volume_holding_with_one_volume_renewed_2755020.dat')
      availability_data.size.should  == 1
      availability_data[0].holdings.size.should  == 1
      availability_data[0].holdings[0].items.size.should  == 2
      items_status_data = availability_data[0].holdings[0].get_items_display[:status]
      items_status_data.size.should  == 2
      items_status_data[0][:available].should == true
      items_status_data[1][:available].should == false
      items_status_data[1][:status_text].should == '2 Checked Out, Due on December 30, 2013'
    end

    it "lost holding should have item status date of the item" do
      availability_data = load_data_from_file('lost_2837410.dat')
      availability_data.size.should  == 1
      availability_data[0].holdings.size.should  == 1
      availability_data[0].holdings[0].items.size.should  == 1 
      items_status_data = availability_data[0].holdings[0].get_items_display[:status]
      items_status_data.size.should  == 1
      items_status_data[0][:available].should == false
      items_status_data[0][:status_text].should == 'Lost June 14, 2004.'
    end

    it "overdue holding should have item status date of the item" do
      availability_data = load_data_from_file('overdue_2772804.dat')
      availability_data.size.should  == 1
      availability_data[0].holdings.size.should  == 2 
      availability_data[0].holdings[1].items.size.should  == 1
      items_status_data = availability_data[0].holdings[1].get_items_display[:status]
      items_status_data.size.should  == 1
      items_status_data[0][:available].should == false
      items_status_data[0][:status_text].should == 'Overdue June 10, 2013.'
    end


    it "holding with two copies both checked out should have item due date of each  item" do
      availability_data = load_data_from_file('two_copies_checkedout_6202124.dat')
      availability_data.size.should  == 1
      availability_data[0].holdings.size.should  == 1
      availability_data[0].holdings[0].items.size.should  == 2
      items_status_data = availability_data[0].holdings[0].get_items_display[:status]
      items_status_data.size.should  == 2
      items_status_data[0][:available].should == false
      items_status_data[0][:status_text].should == 'v.1 Checked Out, Due on December 30, 2013'
      items_status_data[1][:available].should == false
      items_status_data[1][:status_text].should == 'v.2 Checked Out, Due on December 30, 2013'
    end

    it "holding with 5 out of 10 items checkout should have item status date of all checkout items" do
      availability_data = load_data_from_file('5_out_of_10_bindery_8486735.dat')
      availability_data.size.should  == 1
      availability_data[0].holdings.size.should  == 1
      availability_data[0].holdings[0].items.size.should  == 10
      items_status_data = availability_data[0].holdings[0].get_items_display[:status]
      items_status_data.size.should  == 10
      concise = true
      unavailable_items = availability_data[0].holdings[0].get_items_display(concise)[:status]
      unavailable_items.size.should  == 5
      unavailable_items[0][:available] == false
      unavailable_items[0][:status_text].should == 'v.1:supp. At Bindery June 02, 2011'
      unavailable_items[4][:available] == false
      unavailable_items[4][:status_text].should == 'v.5:supp. At Bindery June 02, 2011'
    end

    it "holding with all items available should status 'aggregated' status of available" do
      availability_data = load_data_from_file('all_available_3451268.dat')
      availability_data.size.should  == 1
      availability_data[0].holdings.size.should  == 1
      availability_data[0].holdings[0].items.size.should  == 3
      items_status_data = availability_data[0].holdings[0].get_items_display[:status]
      items_status_data.size.should  == 3
      unavailable_items = availability_data[0].holdings[0].get_items_display(true)[:status]
      unavailable_items.size.should  == 1
      unavailable_items[0][:available] == true
      unavailable_items[0][:status_text].should == 'Available'
    end

  end
end
