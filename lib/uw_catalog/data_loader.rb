module UwCatalog

  class DataLoader

    def self.load_dynamic_object(data_struct, class_name)
      cls = Object.const_get(class_name)
      obj = cls.new
      data_struct.each_pair {|key, value| obj.send("#{key}=",value) }
      obj
    end

    def self.load(data_struct, obj)
      data_struct.each_pair {|key, value| obj.send("#{key}=",value) }
    end

    def self.get_data(repository_key, sql, bibid)
      repository(repository_key).adapter.select(sql, bibid)
    end

  end

end
