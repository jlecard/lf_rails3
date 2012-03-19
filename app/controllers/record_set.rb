# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

require 'net/http'
require 'uri'
require 'ropenurl'
require 'yajl'
require 'marc'

class RecordSet  < ActionController::Base
  #Structs
  @@citation = Struct.new(:volume, :issue,:page)
  #I believe that static is deprecated -- but will include for now
  @@url = Struct.new(:open, :direct,:static,:vendor) 
  attr_reader :pkeyword
  
  attr_reader :hits, :xml
  
  def setKeyword(_val) 
    @pkeyword = _val
  end
  
  def getKeyword()
    return @pkeyword
  end
  
  def setId(_val) 
    @pid = _val
  end
  
  def getId()
    return @pid
  end
  
  #unpack the cache xml
  def unpack_cache(_recs, _max)
    Record.new()
    _sTime = Time.now().to_f
    tab = []
    begin
      Yajl::Parser.parse(_recs,{:check_utf8=>false}).each do |h|
        r = Record.new()
        h.each do |k,v|
          eval("r.#{k} = v")
        end
        tab << r
      end
    rescue Exception => e
      logger.error("[RecordSet] [unpack_cache] error : #{e.message} \n called on #{_recs.inspect}")
      logger.debug("[RecordSet] [unpack_cache] error : #{e.backtrace}")
    end
    tmp = tab[0.._max.to_i]
    logger.debug("#STAT# [RECORDSET] unpack_cache: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    return tmp
  end
  
  #unpack the cache xml
  #    def unpack_cache2(_recs, _max)
  #      _sTime = Time.now().to_f
  #      logger.debug("[Debug] : level 1");
  #      if (_recs == nil)
  #        logger.debug("_recs is nil");
  #        return nil;
  #      end
  #      if (_recs == '')
  #        logger.debug("_recs is empty")
  #        return nil;
  #      end 
  #      
  #      arr_rec		= Array.new()
  #      _counter	= 0
  #      _xpath		= Xpath.new()
  #      parser		= ::PARSER_TYPE
  #      logger.debug("[RecordSet][Debug] : ParserType : " + parser);
  #      begin
  #        case parser
  #          when 'libxml' 
  #          _parser					= LibXML::XML::Parser.new()
  #          _parser.string	= _recs
  #          _xml						= LibXML::XML::Document.new()
  #          _xml						= _parser.parse
  #          when 'rexml'
  #          _xml = REXML::Document.new(_recs)
  #          when 'nokogiri'
  #          _xml = Nokogiri::XML.parse(_recs)
  #        end
  #      rescue => e
  #        logger.error("error on Record set " + e.message + "\n" + e.backtrace.join("\n"))
  #        return nil
  #      end
  #      
  #      nodes	= _xpath.xpath_all(_xml, "//item") #_xml.find("//item")
  #      if _max ==  -1: _max = nodes.length  end
  #      
  #      nodes.each do |rec|
  #        record = Record.new()
  #        
  #        if parser == 'nokogiri'
  #          values = rec.elements
  #        else
  #          values = rec
  #        end
  #        
  #        values.each do |item|
  #          _tmpText = _xpath.xpath_get_text(item)
  #          if _xpath.xpath_get_name(item) != nil
  #            array = item.xpath("./line")
  #            if array.empty?
  #              class_att = record.instance_variable_get("@"+_xpath.xpath_get_name(item)).class
  #              if class_att == TrueClass or class_att == FalseClass
  #                # pas de dump
  #                if _tmpText.blank?
  #                  _tmpText = false
  #                end
  #              else
  #                _tmpText = _tmpText.dump 
  #              end
  #              eval("record." + _xpath.xpath_get_name(item) + "=" + _tmpText.to_s)
  #            else
  #              begin
  #                tab = Array.new()
  #                array.each do |i|
  #                  # TODO: find rule for instance generic object
  #                  ex = Struct::Examplaire.new()
  #                  i.children.each do |ch|
  #                    _txt = _xpath.xpath_get_text(ch)
  #                    if _xpath.xpath_get_name(ch) != nil
  #                      eval("ex." + _xpath.xpath_get_name(ch) + "=" + _txt.dump) 
  #                    end
  #                  end
  #                  tab << ex
  #                end
  #                eval("record." + _xpath.xpath_get_name(item) + "=tab") 
  #                logger.debug("tab : #{tab.inspect}")
  #              rescue => e
  #                logger.error("[record_set] [unpack_cache] error : #{e.message}")
  #              end
  #            end
  #          end
  #        end 
  #        arr_rec << record
  #        _counter = _counter + 1
  #        if _counter >= _max
  #          logger.debug("#STAT# [RECORDSET] unpack_cache: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  #          return arr_rec
  #        end
  #      end
  #      logger.debug("#STAT# [RECORDSET] unpack_cache: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  #      return arr_rec
  #    end
  
  
  #unpacks a MARCXML record utilizing the information from the def.
  #might want to look at if we can use YAML or using Sax
  #process to handle a bit more of this.
  def unpack_marcxml(_host, _rec, _def, _bool_obj, infos_user=nil) 
    _start_time	= Time.now();
    _openvals		= Hash.new;
    _rechash		= Hash.new;
    _tarray			= _def.split(';');
    _prefix			= '';
    @xml				= ""
    _recs = MARC::XMLReader.new(StringIO.new(_rec))

    def_hash = Hash.new
    _tarray.each { |id|
      cut = id.split('=')
      tag = cut[1].match(/(\d+)[a-z]/) if !cut.nil? and !cut[1].nil?
      tag = tag[1] if !tag.nil? and !tag[1].nil?
      subfield = cut[1].match(/\d+([a-z])$/)#slice(3,cut[1].length)
      subfield = subfield[1] if !subfield.nil? and !subfield[1].nil?
      if def_hash[tag].nil?
		def_hash[tag]= Hash.new 
      end
      def_hash[tag][subfield] = cut[0]
    }
     _url = checknil(_host['url'])
     _recs.each do |reader|
        if !reader.kind_of?(MARC::ControlField) #and !reader.respond_to?('subfields')
            for field in reader
               if !def_hash[field.tag.to_s].nil? # Si l'element est present dans la table
                  if (def_hash[field.tag].nil?)
                    _rechash[_tlabel] = ''  # Dans ce cas, la collection est mal formee
                  else   # Cas general
                    field.subfields.each { |subfield|
                      if !def_hash[field.tag.to_s][subfield.code.to_s].blank?
                         _tlabel = def_hash[field.tag.to_s][subfield.code.to_s]
                          if _rechash[_tlabel].nil?   #S'il n'y a pas encore de valeur associee à ce label dans la table de Hash
                            _rechash[_tlabel] = subfield.value  # On y met la valeur
                          else
                            _rechash[_tlabel] += ";#{subfield.value}"   # Sinon, on concatene les valeurs en séparant par un ;
                          end
                      end
                    }
                  end  ## Fin du if (def_hash[field.tag].length < 2)
               end ## Fin du if !(def_hash[field.tag] == nil)
            end ## for rec in reader
        end ## Fin du !MARC::ControlField
     end ## Fin du _recs.each
    
    #logger.debug("[RecordSet][UnpackMarcXml] define of collection line of _tarray -> _X : " + _x.inspect);
    #logger.debug("[RecordSet][UnpackMarcXml] _tlabel " + _tlabel.inspect);
    _rechash.each_key {|key|
      _rechash[key] = checknil(_rechash[key]).chomp('; ')
    }
    #=============================================
    #At this point, we should have the data 
    #extracted.
    #Here we handle special data (like subjects)
    #then normalize the data and place them into 
    #the class parameters
    #=============================================
    if normalize(_rechash['author'])!=""
      if _rechash['author']!=''
        _tmpl = _rechash['author'].split('; ')
        #_rechash['author']= _tmpl[0];
        if _rechash['author'].index(',')!=nil
          #_rechash['author'] = _rechash['author'].slice(0, _rechash['author'].index(","))
        end
      end
    end
    _openvals['issn']=_rechash['issn']
    _openvals['isbn']=_rechash['isbn']
    _openvals['title']=normalize(_rechash['title'])
    _openvals['atitle']=normalize(_rechash['atitle'])
    _openvals['aulast']=normalize(_rechash['author'])
    _openvals['volume'] = normalize(_rechash['vol'])
    _openvals['num'] = normalize(_rechash['num'])
    _openvals['issue'] = normalize(_rechash['issue'])
    _openvals['date'] = UtilFormat.normalizeDate(_rechash['date'])
    if normalize(_rechash['doi'])!="" 
      _openvals['rft_id'] = "info:doi/" + checknil(_rechash['doi'])
    else
      _openvals['rft_id'] = ""
    end
    _openvals['spage'] = normalize(_rechash['page'])
    
    _rechash['date'] = UtilFormat.normalizeDate(_rechash['date'])
    _rechash['ass_num'] = normalize(_rechash['ass_num'])
    _rechash['static'] = checknil(_rechash['static'])
    if _rechash['static'].index('; ') != nil
      _rechash['static'] = _rechash['static'].split('; ')[0].chomp('; ')
    end
    
    
    _openurl = "" 
    if defined? LIBRARYFIND_OPENURL 
      _openurl = buildopenlink(_openvals, ::LIBRARYFIND_OPENURL)
    end
    #_openurl = _openurl.gsub("%20", "+")
    _direct = ''
    if _openurl!='' 
      logger.debug('entering parsedirect')
      _direct =  ParseDirect(_openvals) #ParseDirect(buildopenlink(_openvals, ::LIBRARYFIND_OPENURL))
    else
      logger.debug('libraryfind_ill?')
      if defined? LIBRARYFIND_ILL
        logger.debug('Entering ILL')
        _openurl = BuildILL(_openvals,::LIBRARYFIND_ILL ) #this is for the citation link
        logger.debug('exiting ill')
        if _openurl.strip == '' || _openurl == nil
          _openurl = ::LIBRARYFIND_OPENURL
        end
      else 
        logger.debug('no ill');
        _openurl = ""
      end
    end 
    _openvals.clear
    if defined? _rechash['static'] 
      _tindex = _rechash['static'].index('http')
      if _tindex!=nil 
        if _tindex>0 
          _rechash['static'] = _rechash['static'].slice(_tindex, _rechash['static'].size-_tindex)
        end
      end 
      #_rechash['static'] = procUrl(_rechash['static'])
      #if _direct=='' 
      #  _direct = normalize(_rechash['static']).strip
      #end 
      if LIBRARYFIND_USE_PROXY == true && _host['proxy']==1
        _host['vendor_url'] = GenerateProxy(normalize(_host['vendor_url']).strip)
      end
      
      if _rechash['static']!=""
        #logger.debug("Proxy info: " + _host['proxy'].to_s)
        if LIBRARYFIND_USE_PROXY == true && _host['proxy']==1
          _direct = GenerateProxy(normalize(_rechash['static']).strip)
        else
          _direct = normalize(_rechash['static']).strip
        end
      end
    end 
    #if _rechash['ass_num']!=''
    #  if _direct=='' 
    #    _direct = normalize(_url.gsub(/\{ass_num\}/, normalize(_rechash['ass_num'])))
    #  end 
    #end 
    
    if _rechash['atitle']==nil
      _ptitle=_rechash['title'] 
    else  
      _ptitle=_rechash['atitle']
    end
    
    _tmp = "" 
    if defined? LIBRARYFIND_SPECIAL_WEIGHT
      _tmp_list = LIBRARYFIND_SPECIAL_WEIGHT.split(";")
      _tmp_list.each do |el|
        logger.debug("SPECIAL?")
        if _host['vendor_name'].index(el) != nil
          logger.debug("SPECIAL RAN")
          _tmp = calc_rank({'special' => '1', 'title' => _rechash['title'],
                                        'atitle' => _rechash['atitle'],
                                        'creator' => _rechash['author'],
                                        'date' => _rechash['date'],
                                        'rec' => "#{_rechash["abstract"]} #{_rechash["publisher"]} #{_rechash["subject"]}",
                                        'pos' => 1}, @pkeyword)
          break
        end
      end
    else 
      _tmp = calc_rank({'title' => _rechash['title'],
                                        'atitle' => _rechash['atitle'],
                                        'creator' => _rechash['author'],
                                        'date' => _rechash['date'],
                                        'rec' => "#{_rechash["abstract"]} #{_rechash["publisher"]} #{_rechash["subject"]}",
                                        'pos' => 1}, @pkeyword) 
    end
    
    if _bool_obj == false
      _tmp = "<item rank = \"" + _tmp + "\">"
      _rechash.keys.each { |_x|
        _tmp << "<#{_x}>" + _rechash[_x] + "</#{_x}>\n"
      } 
      _tmp << "<mat_type>" + _rechash['mat_type'] == nil || _rechash['mat_type'] == "" ? _host['mat_type'] : normalize(_rechash['mat_type']) + "</mat_type>\n"
      _tmp << "<url>"
      _tmp << "<openurl>" + _openurl + "</openurl>\n"
      _tmp << "<direct>" + _rechash["link"]+ "</direct>\n"
      _tmp << "<static>"  + _rechash['static'] + "</static>\n"
      _tmp << "<vendor>" + _host['vendor_url']  + "</vendor>\n"
      _tmp << "</url>"
      _tmp <<  "</item>\n"
      return _tmp 
    else
      
      _rechash['callnum'] = GetPrimaryCall(checknil(_rechash['callnum']))
      
      record = Record.new()
      record.rank = _tmp
      record.hits = _host['hits']
      record.vendor_name = _host['vendor_name']
      record.ptitle = _ptitle
      record.title = checknil(_rechash['title'])
      record.atitle = checknil(_rechash['atitle'])
      record.issn = checknil(_rechash['issn'])
      record.isbn = checknil(_rechash['isbn'])
      record.abstract = checknil(_rechash['abstract'])
      record.date = checknil(_rechash['date'])
      record.author = checknil(normalize(_rechash['author']))
      record.link = checknil(_rechash['link'])
      doi = checknil(_rechash['doi'])
      if doi.blank?
        record.id = (rand(1000000) + checknil(_rechash['ass_num']).to_i).to_s + ID_SEPARATOR + _host['collection_id'].to_s + ID_SEPARATOR + _host['search_id'].to_s 
      else
        record.id = doi + ID_SEPARATOR + _host['collection_id'].to_s + ID_SEPARATOR + _host['search_id'].to_s 
      end
      record.doi = doi
      record.openurl = _openurl
      if(INFOS_USER_CONTROL and !infos_user.nil?)
        # Does user have rights to view the notice ?
        droits = ManageDroit.GetDroits(infos_user,_host['collection_id'])
        if(droits.id_perm == ACCESS_ALLOWED)
          if !_rechash['link'].blank?
            record.direct_url = checknil(_rechash['link'])
          elseif !_rechash['direct_url'].blank?
            record.direct_url = _rechash['direct_url']
          end
        else
          record.direct_url = _rechash['direct_url']
        end
      else
        if !_rechash['link'].blank?
          record.direct_url = checknil(_rechash['link'])
        elseif !_rechash['direct_url'].blank?
          record.direct_url = _rechash['direct_url']
        end
      end
      record.direct_url = _rechash['direct_url']
      record.static_url = checknil(_rechash['static'])
      record.subject = checknil(normalize(_rechash['subject']))
      record.publisher = checknil(normalize(_rechash['publisher']))
      record.callnum = checknil(_rechash['callnum'])
      record.vendor_url = _host['vendor_url']
      record.material_type = _rechash['mat_type'] == nil || _rechash['mat_type'] == "" ? _host['mat_type'] : PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(_rechash['mat_type']), _host['collection_id'])
      if _rechash['mat_type'].blank?
        record.material_type = UtilFormat.normalize(_host['mat_type'])
      else
        record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(_rechash['mat_type']), _host['collection_id'])
      end
      record.volume = normalize(_rechash['vol'])
      record.issue = checknil(_rechash['issue'])
      record.page = checknil(_rechash['page'])
      record.number = checknil(_rechash['number'])
      record.start = _start_time.to_f
      record.end = Time.now().to_f
      record.raw_citation = checknil(_rechash['raw_citation'])
      record.oclc_num = checknil(_rechash['oclc_num'])
      record.theme = ""
      record.category = ""
      
      return record
    end	
  end
  
  def sutrs2record(sutrs, definition, params, position = 1)
    
    if (sutrs.blank?)
      raise "Error when decoding"
    end
    
    # parse sutrs to hash
    lines = sutrs.split("\n")
    hash = Hash.new()
    ignore_first = true
    code_current = nil
    lines.each do |line|
      if (ignore_first)
        ignore_first = false
      else
        if (line[0] != 32) #dif space
          code = line.downcase
          if (!code.blank?)
            tmp = code.split(" ")
            code_current = tmp[0]
            hash[code_current] = ""
          end
        else
          tmp = line.chomp("\r\n\t ").strip()
          if (!hash[code_current].blank?)
            hash[code_current] += " " # add space
          end
          hash[code_current] += "#{tmp}"
        end
      end
    end # end do
    
    record = Record.new()
    # sample
    #definition="ptitle=ti;source=so;subject=sa;abstract=ab,ga;date=py;identifier=an;isbn=ib;issn=is;author=au;issue=is;lang=la;page=jp;volume=fe;doi=do;"
    mapping = definition.split(";")
    mapping.each do |map|
      tab = map.split("=")
      record_property = tab[0]
      sutrs_properties = tab[1]
      multi_values = false
      tmp = nil
      sutrs_properties.split(",").each do |sutrs_property|
        if (!hash[sutrs_property].blank?)
          if (multi_values)
            tmp = ";" # add separator
          else
            tmp = ""
          end
          
          tmp += hash[sutrs_property]
        end
        multi_values = true
      end
      
      if !tmp.nil?
        begin
          eval("record.#{record_property} = normalize(tmp.capitalize)")
        rescue => e
          logger.error("[RecordSet] [sutrs2record] Record property : #{map} not exist : #{e.message}")
        end
      end
    end
    
    if (record.identifier.blank?)
      raise "No identifier. checked data"
    end
    
    record.rank = calc_rank({'title' => record.ptitle,
                                        'atitle' => record.atitle,
                                        'creator' => record.author,
                                        'date' => record.date,
                                        'pos' => position}, @pkeyword)
    record.id = "#{record.identifier}#{ID_SEPARATOR}#{params['collection_id']}#{ID_SEPARATOR}#{params['search_id']}"
    record.vendor_name = params['vendor_name']
    record.vendor_url  = params['vendor_url']
    record.end = Time.now().to_f
    record.hits = params['hits']
    
    if record.material_type.blank?
      record.material_type = UtilFormat.normalize(params['mat_type'])
    else
      record.material_type = PrimaryDocumentType.getNameByDocumentType(UtilFormat.normalize(record.material_type), params['collection_id'])
    end
    
    return record
  end
  
  def sutrs2xml(_s)
    logger.debug('SUTRS RECORD: ' + _s)
    _header = '<record>' + #  xmlns="http://www.loc.gov/MARC21/slim">' +
  		  '<leader>01059naa a2200289Ia 4500</leader>' 
    
    _rechash = sutrs2hash(_s)
    
    #Print out the data in MARCXML
    _xml = _header + "\n"
    _rechash.each {|_key, _value|
      case _key
        when "ti"
        _xml << '<datafield tag="245" ind1="0" ind2="0">'+
			   '<subfield code="a">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
        when "au"
        _xml << '<datafield tag="700" ind1="0" ind2="0">'+
			   '<subfield code="a">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
        when "is"
        _xml << '<datafield tag="022" ind1="0" ind2="0">'+
			   '<subfield code="a">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
        when "do"
        _xml << '<datafield tag="028" ind1="0" ind2="0">'+
			   '<subfield code="a">' + normalizeForXML(_value) + '</subfield>'+
			   '<subfield code="b">doi</subfield>'+
			   '</datafield>'
        when "py"
        _xml << '<datafield tag="260" ind1="0" ind2="0">'+
			   '<subfield code="c">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
        when "an"
        _xml << '<controlfield tag="001">' + normalizeForXML(_value) + '</controlfield>'
        when "so"
        _xml << '<datafield tag="773" ind1="0" ind2="0">'+
			   '<subfield code="t">' + normalizeForXML(_value) + '</subfield>'+
			   '</datafield>'
      else
      end
    }
    _xml << '</record>'
    
    logger.debug('SUTRS XML: ' + _xml) 
    return _xml 
  end
  
  def normalizeForXML(_s) 
    return _s
    _s = _s.gsub('&','&amp;')
    _s = _s.gsub('>','&gt;')
    _s = _s.gsub('<','&lt;')
    return _s
  end
  
  def GetPrimaryCall(_string) 
    return _string.split(";")[0]
  end
  
  def calc_rank(_rec, _keyword)
    objCalc = CalcRank.new
    return objCalc.calc_rank(_rec, _keyword)
  end
  
  
  def string_count(_haystack, _needle)
    _x = 1
    _pos = -1
    while _x==nil
      _x = _haystack.index(_x,_needle)
      if _x!=nil : _pos = _x end
    end
    return _pos
  end
  
  def is_stop(_s)
    return false
  end
  
  def strip_ex(_string, _pat, _rep)
    _string = _string.gsub(/\W+$/,_rep)
    _string = _string.gsub(/^\W+/,_rep)
    return _string
  end 
  
  def normalize(_string)
    return "" if _string == nil
    _string = _string.gsub(/^\s*/,"") 
    _string = _string.gsub(/\s*$/,"")
    #Remove trailing punctuation
    _string = _string.gsub(/[.,;:-]*$/,"")
    #Remove html data 
    _string = _string.gsub(/<(\/|\s)*[^>]*>/, "")
    #_string = strip_tags(_string)
    #Remove trailing non word character
    _string = _string.gsub(/[\/ ]*$/,"")
    #Managing accent
    _string = _string.gsub("ℓe", "é")
    _string = _string.gsub("ℓE", "E")
    _string = _string.gsub("℗e", "é")
    _string = _string.gsub("℗E", "E")
    _string = _string.gsub("ℓA", "A")
    _string = _string.gsub("ℓa", "à")
    _string = _string.gsub("©o", "ô")
    _string = _string.gsub("©a", "â")
    _string = _string.gsub("©e", "ê")
    _string = _string.gsub("©i", "î")
    _string = _string.gsub("©I", "I")
    _string = _string.gsub("©u", "û")
    _string = _string.gsub("©U", "U")
    _string = _string.gsub("Ðc", "ç")
    _string = _string.gsub("ÐC", "C")
    _string = _string.gsub("©e", "è")
    return _string
  end
  
  def getLabel(_s)
    case _s.downcase
      when 'linking' : return 'link'
      when 'staticurl' : return 'static'
      when 'bn' : return 'isbn'
      when 'ti' : return 'title'
      when 'ati' : return 'atitle'
      when 'au' : return 'author'
      when 'an' : return 'ass_num'
      when 'note' : return 'abstract'
      when 'abs' : return 'abstract'
      when 'cnum' : return 'callnum'
      when 'pub' : return 'publisher'
    else return _s.downcase
    end
  end
  
  def buildopenlink(_val, _stem) 
    if _stem == "": return "" end
    if _stem.index('?')==nil: _stem + '?' end
    co = OpenURL::ContextObject.new
    if _val['rft_id']!='' 
      if _val['rft_id'].index("info:doi/")!=nil
        _tmphash = Hash.new
        _tmphash['rft_id'] = _val['rft_id']
        co = co.resolve_doi(::DOI_SERVLET.gsub("{@DOI}", URI.escape(_val['rft_id'].gsub("info:doi/", ""))), _val['atitle'])
        if co == nil
          co = OpenURL::ContextObject.new
          co.import_hash(_tmphash)
        end
        return _stem + co.kev
      else  
        return ""
      end
    elsif _val['date']=='' || (_val['issn']=='' && _val['isbn']=='')
      return '';
    else 
      if _val['aulast']!=''
        _tmpl = _val['aulast'].split('; ')
        _val['aulast']= _tmpl[0];
        if _val['aulast'].index(',')!=nil
          _val['aulast'] = _val['aulast'].slice(0, _val['aulast'].index(","))
        end 
      end 
      co.import_hash(_val)
      return _stem + co.kev
    end 
  end 
  
  def ParseDirect(_val)
    url = nil
    co = OpenURL::ContextObject.new 
    logger.debug('import hash')
    co.import_hash(_val)
    logger.debug('hash imported')
    begin
      case LIBRARYFIND_OPENURL_TYPE
        when LIBRARYFIND_LOCAL
        logger.debug("Using LOCAL")
        objProvider = Coverage.search_coverage(co) 
        if objProvider != nil
          url = Coverage.processURL(objProvider.url, co)
          if objProvider.proxy == "y"
            url = GenerateProxy(url)
          end
        else
          url=""
        end
        when LIBRARYFIND_SFX
        logger.debug("Using SFX")
        url = Coverage.search_SFX(co) 
        when LIBRARYFIND_SS
        logger.debug("Using SS")
        url = Coverage.search_SS(co)
        when LIBRARYFIND_GD
        logger.debug("Using GoldDust Link Resolver")
        url = Coverage.search_GD(co)
      end
    rescue  => detail
      logger.debug("ERROR in PARSEDIRECT")
    end
    
    if url==nil
      return ""
    else
      return url
    end
  end 
  
  def BuildILL(_val,_stem)
    url = nil
    co = OpenURL::ContextObject.new
    co.import_hash(_val)
    return _stem + co.kev
  end
  
  
  def ParseDirectEx(_s) 
    return ""
    _tmp = ''
    if _s!=''
      begin
        #open(_s) do |_f|
        #  _tmp << _f.gets
        #end
        response = Net::HTTP.get_response(URI.parse(_s))
        return response.body
      rescue
        return "";
      end
    else 
      return "";
    end 
  end
  
  def checknil(_s) 
    return "" if _s == nil
    return _s.chomp()
  end
  
  def GenerateProxy(s) 
    objProxy = Proxy.new()
    url = objProxy.GenerateProxy(s)
    return url
  end
  
  def init_parser(parser, _records)
    case parser
      when 'libxml' 
      _parser	= LibXML::XML::Parser.string(_records.to_s, :encoding => XML::Encoding::UTF_8, :options => XML::Parser::Options::NOBLANKS)
      _xml 		= LibXML::XML::Document.new()
      _xml 		= _parser.parse()
      when 'rexml'
      _xml 		= REXML::Document.new(_records)
      when 'nokogiri'
      _xml = Nokogiri::XML.parse(_records)
      _xml = _xml.root
    end
    return (_xml)
  end
  
  def set_correlation_hash(_correlation_word)
    _h_correlation 	= Hash.new();
    tmp							= _correlation_word.split(';')
    
    tmp.each do |item| 
      _h_correlation[item.split(':')[0].to_s] = item.split(':')[1].to_s
    end
    return (_h_correlation)
  end
  
  def set_value_dc(_record, attribute, value)
    if (attribute == "lang")
      value = UtilFormat.normalizeLang(value)
    end
    eval("_record.#{attribute} = value")
    return ;
  end
  
  def unpack_dc(_host, _records, _correlation_word)
    if (_records.blank?)
      logger.error("[RecordSet][UnpackDC] Paramaters given is empty")
      return (nil);
    end
    parser					= ::PARSER_TYPE
    _h_correlation 	= set_correlation_hash(_correlation_word)
    
    logger.debug("[RecordSet][Debug] _h_correlation : " + _h_correlation.inspect)
    logger.debug("[RecordSet][Debug] : ParserType : " + parser)
    begin
      _xml = init_parser(parser, _records)
    rescue => e
      logger.error("error on Record set " + e.message + "\n" + e.backtrace.join("\n"))
      return (nil)
    end
    
    _record			= Record.new();
    _fields			= _record.instance_variables;
    
    logger.debug("[RecordSet] _fields : " + _fields.inspect)
    cond = false
    
    if (::PARSER_TYPE == 'nokogiri')
      cond = (_xml.element?) && (_xml.elements[0].element?)
    else
      cond = (_xml.child?) && (_xml.child.child?)
    end
    
    if (cond)
      
      if (::PARSER_TYPE == 'nokogiri')
        _nodeList = _xml.elements[0].elements; # enter in RecordData node -> enter in dc node
      else
        _nodeList = _xml.child.child;
      end
      
      _nodeList.each do |node|
        
        if (::PARSER_TYPE == 'nokogiri')
          c1 = (!node.name.nil?) && (!node.elements.to_s.nil?)
        else
          c1 = (!node.name.nil?) && (!node.child.to_s.nil?)
        end
        
        if (c1)
          if (_fields.include?("@" + node.name) == false)
            if ((!_h_correlation.nil?) && (!_h_correlation[node.name].nil?))
              logger.debug("[RecordSet] attribute in class record inexistant : " + node.name + " <-- swap by --> " + _h_correlation[node.name]);
              tmp = _h_correlation[node.name]
              set_value_dc(_record, tmp, UtilFormat.html_decode(node.child.to_s))
            else
              #              logger.warn("[RecordSet] attribute in class record inexistant : " + node.name)
            end
          else
            set_value_dc(_record, node.name, UtilFormat.html_decode(node.child.to_s))
            logger.debug("[REcordSet] node : " + node.name + " => " + node.child.to_s)
          end
        end
      end
      _record.id	=  _record.identifier.to_s + ID_SEPARATOR + _host["collection_id"].to_s + ID_SEPARATOR + _host["search_id"].to_s
      _record.vendor_name	= _host['vendor_name']
      _record.vendor_url	= _host['vendor_url']
      if _record.material_type.blank?
        _record.material_type = UtilFormat.normalize(_host['mat_type'])
      end
    end
    logger.debug("[RecordSet] obj record : " + _record.inspect)
    _record.ptitle = _record.title
    return (_record)
  end
end
