module UwCatalog
  class HoldingMarc

    YEAR_CAPTIONS   = ['(year)', '(Year)', 'year', '(year covered)']
    MONTH_CAPTIONS  = ['(month)', 'mo']
    DAY_CAPTIONS    = ['(day)']
    SEASON_CAPTIONS = ['(season)']
 
    attr_reader :holding_id, :record
    
    def initialize(holding_id)
      @holding_id = holding_id
      to_marc
    end    

    def marc_record 
      @record
    end
    
    def bound_copies
      bound_copies_internal
    end

    def indexes
      indexes_internal
    end

    def indexes
      indexes_internal
    end

    def supplements
      supplements_internal
    end

    private

    def new_issues
      issues_received(0)
    end

    def issues_received(category)
      sql = VoyagerSql.get_issues_recieved_sql
      repository(:UW).adapter.select(sql, @holding_id, category)
    end

    def to_marc
      if @record.nil?
        @record = MARC::Record.new_from_marc(marc_stream)
      end
      @record
    end

    def marc_stream
      marc_stream = ''
      sql = VoyagerSql.get_marc_stream_sql
      mfhd_data_segments = repository(:UW).adapter.select(sql, @holding_id)
      mfhd_data_segments.each do |segment|
        marc_stream << segment
      end
      marc_stream
    end


    def classification_part
      @record = to_marc
      if @record['852'] and @record['852']['h']
        @record['852']['h']
      else
        nil
      end
    end
  
    def location_code
      @record['852']['b']
    end
    
    def indexes_internal
      indexes_key_ordered_hash = Hash.new
      indexes = Array.new
      
      caption_and_pattern = get_caption_and_pattern_hash(@record, '855')
      @record.find_all {|field| field.tag == '865' or field.tag == '868'}.each do |field| 
        
        if field.tag == '868' 
          
          # I don't trust that the data in subfield $8 will always be numeric floats.
          begin
            key = "%04d" % field['8'].to_i
            str = field['a']
            str += " " + field['z'] if field['z']
            indexes_key_ordered_hash[key] = str
          rescue
            # Move on and don't include the data if it is improperly coded.
          end
          
        # Full blown MARC Format Holdings Data. Oy!
        elsif field.tag == '865'
        
          link_and_sequence = field['8']
          
          if link_and_sequence
            link = link_and_sequence.split('.')[0]
            sequence = link_and_sequence.split('.')[1]

            # Make sure that we know which caption/pattern to link to before processing the 865 field
            if caption_and_pattern[link]

              # Parse the data
              enum_chron_hash = Hash.new
              add_field_chronology_data_to_enum_chron_hash(caption_and_pattern, link, enum_chron_hash, field)
              add_field_enumeration_data_to_enum_chron_hash(caption_and_pattern, link, enum_chron_hash, field)
              
              # Format it
              str = get_enum_chron_type_of_unit_and_notes(enum_chron_hash, field)

              # I don't trust that the data in subfield $8 will always be numeric floats.
              begin
                key = ("%04d" % link.to_i) + "-" + ("%04d" % sequence.to_i)
                indexes_key_ordered_hash[key] = str.strip
              rescue
                # Move on and don't include the data if it is improperly coded.
              end
            end
          end
        end
      end
      
      indexes_key_ordered_hash.keys.sort.each {|key| indexes << indexes_key_ordered_hash[key] }
      
      issues_received(2).each { |new_index| indexes << new_index }
      
      indexes
    end
    
    def supplements_internal
      supplements_key_ordered_hash = Hash.new
      supplements = Array.new
      
      caption_and_pattern = get_caption_and_pattern_hash(@record, '854')
      @record.find_all {|field| field.tag == '864' or field.tag == '867'}.each do |field| 
        
        if field.tag == '867' 
          
          # I don't trust that the data in subfield $8 will always be numeric floats.
          begin
            key = "%04d" % field['8'].to_i
            str = field['a']
            str += " " + field['z'] if field['z']
            supplements_key_ordered_hash[key] = str
          rescue
            # Move on and don't include the data if it is improperly coded.
          end
          
        # Full blown MARC Format Holdings Data. Oy!
        elsif field.tag == '864'
        
          link_and_sequence = field['8']
          if link_and_sequence
          
            link = link_and_sequence.split('.')[0]
            sequence = link_and_sequence.split('.')[1]
        
            # Parse the data
            enum_chron_hash = Hash.new
            add_field_chronology_data_to_enum_chron_hash(caption_and_pattern, link, enum_chron_hash, field)
            add_field_enumeration_data_to_enum_chron_hash(caption_and_pattern, link, enum_chron_hash, field)
            
            # Format it
            str = get_enum_chron_type_of_unit_and_notes(enum_chron_hash, field)
         
            # I don't trust that the data in subfield $8 will always be numeric floats.
            begin
              key = ("%04d" % link.to_i) + "-" + ("%04d" % sequence.to_i)
              supplements_key_ordered_hash[key] = str.strip
            rescue
              # Move on and don't include the data if it is improperly coded.
            end
          end
        end
      end
      
      supplements_key_ordered_hash.keys.sort.each {|key| supplements << supplements_key_ordered_hash[key] }
      
      issues_received(1).each { |new_supplement| supplements << new_supplement }
      
      supplements
    end
    
    def get_enum_chron_type_of_unit_and_notes(enum_chron_hash, field)
      str = ''
      str += get_formatted_enumeration_info(enum_chron_hash)
      str += " (#{get_formatted_chronology_info(enum_chron_hash)})" unless get_formatted_chronology_info(enum_chron_hash).strip == ""
      enum_chron_hash[:type_of_unit] = field['o'] if field['o']
      if enum_chron_hash[:type_of_unit] 
        str = remove_trailing_punctuation(str)
        str += ", " unless str.strip == ""
        str += enum_chron_hash[:type_of_unit] 
      end
      enum_chron_hash[:notes] = field['z'] if field['z']
      if enum_chron_hash[:notes] 
        str = remove_trailing_punctuation(str)
        str += ", " + enum_chron_hash[:notes] 
      end
      str
    end

    # remove trailing punctuation
    def remove_trailing_punctuation(str)
      str.strip!
      if str.match(/[\/:,.]$/)
        str[0,str.length - 1].strip
      else
        str.strip
      end
    end
    
    # Get a hash that indicates which subfields hold volume, issue, year, month 
    # and day info.
    def get_caption_and_pattern_hash(record, field_number)
      caption_and_pattern = Hash.new
      record.find_all {|field| field.tag == field_number}.each do |field|
        caption_and_pattern[field['8']] = Hash.new
        caption_and_pattern[field['8']][:chronology] = Hash.new
        
        # Locate the chronology subfields
        field.subfields.each do |subfield| 
          caption_and_pattern[field['8']][:chronology][:year] = subfield.code if YEAR_CAPTIONS.include?(subfield.value)
          caption_and_pattern[field['8']][:chronology][:month] = subfield.code if MONTH_CAPTIONS.include?(subfield.value)
          caption_and_pattern[field['8']][:chronology][:day] = subfield.code if DAY_CAPTIONS.include?(subfield.value)
          caption_and_pattern[field['8']][:chronology][:season] = subfield.code if SEASON_CAPTIONS.include?(subfield.value)
        end

        # Unless the chronology data is in subfield $a...
        #
        # From MARC Holdongs:
        #
        # When only Chronology captions are used on an item (that is, the item carries no enumeration), 
        # the Chronology captions are contained in the relevant enumeration caption subfields ($a-$h). 
        # If a Chronology caption is not to be used in a display of the 863-865 Enumeration and Chronology 
        # field, it is enclosed in parentheses, for example, (year).
        # 
        # 853 03$81$a(year)
        # 863 40$81.1$a1964-1981
        # [An annual publication identified only by year.]
        unless caption_and_pattern[field['8']][:chronology].values.include?('a')
          # Create a Hash to hold the enum captions
          caption_and_pattern[field['8']][:enumeration] = Hash.new
          
          # Locate the enumeration subfields
          caption_and_pattern[field['8']][:enumeration][:enum_level_1_caption] = field['a']
          caption_and_pattern[field['8']][:enumeration][:enum_level_2_caption] = field['b']
          caption_and_pattern[field['8']][:enumeration][:enum_level_1_caption_alt] = field['g']
          caption_and_pattern[field['8']][:enumeration][:enum_level_2_caption_alt] = field['h']
        end
      end
      caption_and_pattern
    end
    
    def add_field_chronology_data_to_enum_chron_hash(caption_and_pattern, link, enumeration_hash, field)
      
      # To handle the possibility of missing caption and pattern fields...
      if caption_and_pattern[link]
        
        enumeration_hash[:start_year] = field[caption_and_pattern[link][:chronology][:year]].split('-').first if field[caption_and_pattern[link][:chronology][:year]]
        enumeration_hash[:end_year] = field[caption_and_pattern[link][:chronology][:year]].split('-').last if field[caption_and_pattern[link][:chronology][:year]]
        enumeration_hash[:start_month] = field[caption_and_pattern[link][:chronology][:month]].split('-').first if field[caption_and_pattern[link][:chronology][:month]]
        enumeration_hash[:end_month] = field[caption_and_pattern[link][:chronology][:month]].split('-').last if field[caption_and_pattern[link][:chronology][:month]]
        enumeration_hash[:start_day] = field[caption_and_pattern[link][:chronology][:day]].split('-').first if field[caption_and_pattern[link][:chronology][:day]]
        enumeration_hash[:end_day] = field[caption_and_pattern[link][:chronology][:day]].split('-').last if field[caption_and_pattern[link][:chronology][:day]]
        enumeration_hash[:season] = field[caption_and_pattern[link][:chronology][:season]] if field[caption_and_pattern[link][:chronology][:season]]
      end
    end
    
    def add_field_enumeration_data_to_enum_chron_hash(caption_and_pattern, link, enumeration_hash, field)
      
      # To handle the possibility of missing caption and pattern fields...
      if caption_and_pattern[link] 
        if field['a'] and caption_and_pattern[link][:enumeration] and caption_and_pattern[link][:enumeration][:enum_level_1_caption] #and (field['a'] or field['g'])
          enumeration_hash[:enum_level_1_caption] = caption_and_pattern[link][:enumeration][:enum_level_1_caption]
          enumeration_hash[:enum_level_1_start] = field['a'].split('-').first
          enumeration_hash[:enum_level_1_end] = field['a'].split('-').last
        end
        
        if caption_and_pattern[link][:enumeration] and caption_and_pattern[link][:enumeration][:enum_level_2_caption] and (field['b'] or field['h'])
          enumeration_hash[:enum_level_2_caption] = caption_and_pattern[link][:enumeration][:enum_level_2_caption]

          if field['b']
            enumeration_hash[:enum_level_2_start] = field['b'].split('-', 2).first 
            enumeration_hash[:enum_level_2_end] = field['b'].split('-', 2).last
          end
        end
        
        if field['g'] and caption_and_pattern[link][:enumeration] and caption_and_pattern[link][:enumeration][:enum_level_1_caption_alt]
          enumeration_hash[:alt_enum_level_1_caption] = caption_and_pattern[link][:enumeration][:enum_level_1_caption_alt]
          enumeration_hash[:alt_enum_level_1_start] = field['g'].split('-').first
          enumeration_hash[:alt_enum_level_1_end] = field['g'].split('-').last
        end
        
        if field['h']
          begin
          raise("#{Time.now.strftime("%D %T")} Invalid enum link for: #{self.mfhd_id}") if caption_and_pattern[link][:enumeration].nil?
          enumeration_hash[:alt_enum_level_2_caption] = caption_and_pattern[link][:enumeration][:enum_level_2_caption_alt]
          enumeration_hash[:alt_enum_level_2_start] = field['h'].split('-').first
          enumeration_hash[:alt_enum_level_2_end] = field['h'].split('-').last

          rescue Exception => ex
            enumeration_hash[:alt_enum_level_2_caption] = ""
            File.open("log/cataloging_errors.log", "a") {|f| f.puts ex}
          end
        end
      end
    end

    def bound_copies_internal
      # This Hash stores all the enumeration chronology Strings for a given holdings record.
      # The Hash keys will sort to the correct order.
      bound_copies_key_ordered_hash = Hash.new
      # This Array will be returned containing the enumeration chronology Strings.
      bound_copies = Array.new
      
      caption_and_pattern = get_caption_and_pattern_hash(@record, '853')
      @record.find_all {|field| field.tag == '863' or field.tag == '866'}.each do |field| 
        
        # Freetext holdings field
        if field.tag == '866' 
          
          # I don't trust that the data in subfield $8 will always be numeric floats.
          begin
            key = "%04d" % field['8'].to_i
            raise("#{Time.now.strftime("%D %T")} Invalid 866 for: #{self.mfhd_id}") if field['a'].nil?
            str = field['a']
            str += " " + field['z'] if field['z']
            bound_copies_key_ordered_hash[key] = str
          rescue Exception => ex
            File.open("log/cataloging_errors.log", "a") {|f| f.puts ex}
            # Move on and don't include the data if it is improperly coded.
          end
          
        # Full blown MARC Format Holdings Data. Oy!
        elsif field.tag == '863'
          
          # Use the $8 field to determine which 853 caption each field links to.
          link_and_sequence = field['8']
          if link_and_sequence
            link = link_and_sequence.split('.')[0]
            sequence = link_and_sequence.split('.')[1]
          
            # Build the enumeration_hash that will be used to format the data
            enum_chron_hash = Hash.new
            add_field_chronology_data_to_enum_chron_hash(caption_and_pattern, link, enum_chron_hash, field)
            add_field_enumeration_data_to_enum_chron_hash(caption_and_pattern, link, enum_chron_hash, field)
          
            # Format the data in the enumeration Hash into a human readable String
            str = get_enum_chron_type_of_unit_and_notes(enum_chron_hash, field)
          
            # I don't trust that the data in subfield $8 will always be numeric floats.
            begin
              key = ("%04d" % link.to_i) + "-" + ("%04d" % sequence.to_i)
              bound_copies_key_ordered_hash[key] = str.strip if str.strip != ""
            rescue
              # Move on and don't include the data if it is improperly coded.
            end
          end
        end
      end
      
      bound_copies_key_ordered_hash.keys.sort.each {|key| bound_copies << bound_copies_key_ordered_hash[key] }
      
      
      bound_copies
    end
    
    def additional_copies
      record = to_marc
      additional_copies = Array.new
      record.find_all {|field| field.tag == '899'}.each do |field| 
        additional_copies << field['a'] if field['a']
      end
      additional_copies
    end
    
    # Takes a hash like the following:
    #
    #   {
    #     :enum_level_1_caption => "v.",
    #     :enum_level_2_caption => "no.", 
    # 	  :enum_level_1_start => "173", :enum_level_1_end => "173",
    # 	  :enum_level_2_start => "2", :enum_level_2_end => "26",
    # 	  :start_year => "2009", :end_year => "2009",
    # 	  :start_month => "1", :end_month => "6",
    #     :start_day => "19", :end_day => "29"
    #   }
    #
    # and returns a string like this:
    #
    #  v. 173, no. 2 - v. 173, no. 26
    def get_formatted_enumeration_info(enumeration_hash)
      enum = ''
      
      # With two levels of enumeration
      if enumeration_hash[:enum_level_2_start] 
        
        # Single Issue
        if enumeration_hash[:enum_level_2_start] == enumeration_hash[:enum_level_2_end] and 
            enumeration_hash[:enum_level_1_start] == enumeration_hash[:enum_level_1_end]
          enum += "#{enumeration_hash[:enum_level_1_caption]} #{enumeration_hash[:enum_level_1_start]}, " if enumeration_hash[:enum_level_1_start]
          enum += "no. #{enumeration_hash[:enum_level_2_start]}"
        # Multiple issues in a single volume
        elsif enumeration_hash[:enum_level_2_start] != enumeration_hash[:enum_level_2_end] and 
            enumeration_hash[:enum_level_1_start] == enumeration_hash[:enum_level_1_end]
          enum += "#{enumeration_hash[:enum_level_1_caption]} #{enumeration_hash[:enum_level_1_start]}, " if enumeration_hash[:enum_level_1_start]
          enum += "#{enumeration_hash[:enum_level_2_caption]} #{enumeration_hash[:enum_level_2_start]} - "
          enum += "#{enumeration_hash[:enum_level_2_caption]} #{enumeration_hash[:enum_level_2_end]}"
        # Issue Range
        else
          enum += "#{enumeration_hash[:enum_level_1_caption]} #{enumeration_hash[:enum_level_1_start]}, " if enumeration_hash[:enum_level_1_start]
          enum += "#{enumeration_hash[:enum_level_2_caption]} #{enumeration_hash[:enum_level_2_start]} - "
          enum += "#{enumeration_hash[:enum_level_1_caption]} #{enumeration_hash[:enum_level_1_end]}, " if enumeration_hash[:enum_level_1_end]
          enum += "#{enumeration_hash[:enum_level_2_caption]} #{enumeration_hash[:enum_level_2_end]}"
        end
      
      # First Level Enumeration Only
      elsif enumeration_hash[:enum_level_1_start]
        if enumeration_hash[:enum_level_1_start] == enumeration_hash[:enum_level_1_end]
          enum += "#{enumeration_hash[:enum_level_1_caption]} #{enumeration_hash[:enum_level_1_start]}"
        else
          enum += "#{enumeration_hash[:enum_level_1_caption]} #{enumeration_hash[:enum_level_1_start]}"
          enum += " - #{enumeration_hash[:enum_level_1_caption]} #{enumeration_hash[:enum_level_1_end]}" if enumeration_hash[:enum_level_1_end]
        end
        
      # Hacked data like this:
      # 854 00 $8 2 $a Building for a secure future $i (year) 
      # 864 40 $8 2.1 $a  $i 2001-2004 
      # Notice that there is a free text caption with no data
      elsif enumeration_hash[:enum_level_1_caption] and !enumeration_hash[:enum_level_1_start] 
        enum += enumeration_hash[:enum_level_1_caption]
      end
      
      if enumeration_hash[:alt_enum_level_1_start]
        enum += " (#{enumeration_hash[:alt_enum_level_1_caption]} "
        
        if enumeration_hash[:alt_enum_level_1_start] == enumeration_hash[:alt_enum_level_1_end]
          enum += "#{enumeration_hash[:alt_enum_level_1_start]}"
        else
          enum += "#{enumeration_hash[:alt_enum_level_1_start]}"
          enum += "-#{enumeration_hash[:alt_enum_level_1_end]}" if enumeration_hash[:alt_enum_level_1_end]
        end
        
        if enumeration_hash[:alt_enum_level_2_start]
          enum += ", #{enumeration_hash[:alt_enum_level_2_caption]} "
          if enumeration_hash[:alt_enum_level_2_start] == enumeration_hash[:alt_enum_level_2_end]
            enum += "#{enumeration_hash[:alt_enum_level_2_start]}"
          else
            enum += "#{enumeration_hash[:alt_enum_level_2_start]}"
            enum += "-#{enumeration_hash[:alt_enum_level_2_end]}" if enumeration_hash[:alt_enum_level_2_end]
          end
        end
        
        enum += ")"
      end
      
      enum
    end
    
    def get_season(season_code)
      case season_code
      when "21" then "Spring"
      when "22" then "Summer"
      when "23" then "Autumn"
      when "24" then "Winter"
      else season_code
      end
    end
    
    def get_season_old(season_code)
      case season_code
      when "21" then " (Spring)"
      when "22" then " (Summer)"
      when "23" then " (Autumn)"
      when "24" then " (Winter)"
      else ""
      end
    end
    
    # Takes a hash like the following:
    #
    #   {
    #     :enum_level_1_caption => "v.",
    # 	  :enum_level_1_start => "173", :enum_level_1_end => "173",
    # 	  :enum_level_2_start => "2", :enum_level_2_end => "26",
    # 	  :start_year => "2009", :end_year => "2009",
    # 	  :start_month => "1", :end_month => "6",
    #     :start_day => "19", :end_day => "29"
    #   }
    #
    # and returns a string like this:
    #
    #   January 19, 2009 - June 29, 2009
    def get_formatted_chronology_info(enumeration_hash)  
      date = ''

      # Begin with the literal values...
      start_month = enumeration_hash[:start_month]
      end_month = enumeration_hash[:end_month]
      # Try to convert them into a normalized form.
      begin
        start_month = Integer(enumeration_hash[:start_month].gsub(/^0*/, "")) 
        start_month = Date::MONTHNAMES[start_month]
        end_month = Integer(enumeration_hash[:end_month].gsub(/^0*/, "")) 
        end_month = Date::MONTHNAMES[end_month]
      rescue 
        # don't error out, just use the literal value that came out of the holdings record.
      end
      
      if enumeration_hash[:start_day] and enumeration_hash[:start_month] and enumeration_hash[:start_year]
        # Lone Issue
        if enumeration_hash[:start_year] == enumeration_hash[:end_year] and 
          enumeration_hash[:start_month] == enumeration_hash[:end_month] and
          enumeration_hash[:start_day] == enumeration_hash[:end_day] 
          date += "#{start_month} #{enumeration_hash[:start_day]}, #{enumeration_hash[:start_year]}"
        else
          date += "#{start_month} #{enumeration_hash[:start_day]}, #{enumeration_hash[:start_year]} -"
          date += " #{end_month} #{enumeration_hash[:end_day]}, #{enumeration_hash[:end_year]}"
        end
      elsif enumeration_hash[:start_month] and enumeration_hash[:start_year]

        # If the month values were outside of the 1-12 range
        # check to see if they are 21-24 for Spring, Summer, Fall, Winter
        start_month = get_season(enumeration_hash[:start_month]) unless start_month
        end_month = get_season(enumeration_hash[:end_month]) unless end_month
        
        date += start_month
        date += "," if start_month.match(/\d/)
        date += " #{enumeration_hash[:start_year]}"
        
        # Single Issue.
        # Don't display the end month and end year if they just output the same chronology substring
        # as the start month and start year.
        if start_month != end_month or enumeration_hash[:start_year] != enumeration_hash[:end_year]
          date += " - #{end_month}"
          date += "," if end_month[-1,1].match(/\d/)
          date += " #{enumeration_hash[:end_year]}"
        end
        
      elsif enumeration_hash[:start_year] 
        if enumeration_hash[:end_year] and enumeration_hash[:start_year] != enumeration_hash[:end_year] 
          date += "#{enumeration_hash[:start_year]} - #{enumeration_hash[:end_year]}"
        else
          date += "#{enumeration_hash[:start_year]} "
        end
      end
      
      date += "#{get_season(enumeration_hash[:season])}" if enumeration_hash[:season]
      
      date.strip
    end
    
    def notes
      record = to_marc
      notes = record['852'].subfields.reduce(Array.new) do |notes, subfield|
        notes << subfield.value if subfield.code == 'z'
        notes
      end
      notes
    end
  
    def unavailable_items
      MfhdItem.all(
        :mfhd_id => mfhd_id, 
        MfhdItem.item.item_statuses.item_status_type_id.not => 1, 
        MfhdItem.item.item_statuses.item_status_type_id.not => 11, 
        MfhdItem.item.item_statuses.item_status_type_id.not => 19,
        MfhdItem.item.item_statuses.item_status_type_id.not => 20)
    end

    def other_permanent_locations
      return false if self.mfhd_items.size > 999

      locations = []      
      self.mfhd_items.each do |mfhd_item|
        unless(mfhd_item.item.perm_location == self.location_id || locations.include?(mfhd_item.item.perm_loc_display))
          locations << mfhd_item.item.perm_loc_display
        end
      end
      locations
    end
  end
end
