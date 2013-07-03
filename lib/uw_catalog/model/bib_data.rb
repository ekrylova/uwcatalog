module UwCatalog

  class BibData
    attr_accessor :bibid, :title, :author, :edition, :pub_place, :publisher, :publish_date

    def published_display
      ret = ''
      ret += edition unless edition.nil?
      ret += pub_place unless pub_place.nil?
      ret += publisher unless publisher.nil?
      ret += publish_date unless publish_date.nil?
    end

  end

end
