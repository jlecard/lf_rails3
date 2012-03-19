require 'test/unit'

  
class TestContextObject < Test::Unit::TestCase

  def test_create
    co = OpenURL::ContextObject.new
    assert_equal(co.class, OpenURL::ContextObject)
  end

  def test_import_kev
    kev = "ctx_enc=info%3Aofi%2Fenc%3AUTF-8&ctx_id=10_1&ctx_tim=2006-2-6T14%3A06%3A18EST&ctx_ver=Z39.88-2004&res_id=http%3A%2F%2Forion.galib.uga.edu%2Fsfx_git1&rft.atitle=Open+Linking+in+the+Scholarly+Information+Environment+using+the+OpenURL+Framework&rft.aufirst=Herbert&rft.aulast=Van+de+Sompel&rft.date=2001&rft.genre=article&rft.issn=1082-9873&rft.issue=3&rft.jtitle=D-Lib+magazine&rft.volume=7&rft_id=info%3Adoi%2F10.1045%2Fmarch2001-vandesompel&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&svc_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Asch_svc&url_ctx_fmt=info%3Aofi%3Afmt%3Akev%3Amtx%3Actx&url_ver=Z39.88-2004"
    co = OpenURL::ContextObject.new
    co.import_kev(kev)
    assert_equal("Open Linking in the Scholarly Information Environment using the OpenURL Framework", co.referent.metadata["atitle"])
    assert_equal("D-Lib magazine", co.referent.metadata["jtitle"])
    assert_equal("info:ofi/fmt:kev:mtx:sch_svc", co.serviceType[0].format)
    assert_equal("http://orion.galib.uga.edu/sfx_git1", co.resolver[0].identifier)
    assert_equal("info:doi/10.1045/march2001-vandesompel", co.referent.identifier)
    assert_equal("Herbert", co.referent.metadata["aufirst"])
    assert_equal("Van de Sompel", co.referent.metadata["aulast"])
    assert_equal("2001", co.referent.metadata["date"])
    assert_equal("1082-9873", co.referent.metadata["issn"])
    assert_equal("article", co.referent.metadata["genre"])
    assert_equal("3", co.referent.metadata["issue"])
    assert_equal("7", co.referent.metadata["volume"])
    assert_equal("journal", co.referent.format)
    assert_equal("info:ofi/enc:UTF-8", co.admin["ctx_enc"]["value"])
    assert_equal("10_1", co.admin["ctx_id"]["value"])
    assert_equal("2006-2-6T14:06:18EST", co.admin["ctx_tim"]["value"])
    assert_equal("Z39.88-2004", co.admin["ctx_ver"]["value"])
  end

  def test_import_kev2
    kev = "genre=article&issn=03014797&aulast=&title=Journal+of+Environmental+Management&volume=81&issue=4&date=20061201&atitle=Linking+linear+programming+and+spatial+simulation+models+to+predict+landscape+effects+of+forest+management+alternatives.&spage=339&id=10.1016%2fj.jenvman.2005.11.009&sid=EBSCO:aph&pid=<authors>Gustafson%2c+Eric+J.%3bRoberts%2c+L.+Jay%3bLeefers%2c+Larry+A.</authors><ui>22806349</ui><date>20061201</date><db>aph</db>"
    co = OpenURL::ContextObject.new
    co.import_kev(kev)
    assert_equal("Linking linear programming and spatial simulation models to predict landscape effects of forest management alternatives.", co.referent.metadata["atitle"])
    assert_equal("Journal of Environmental Management", co.referent.metadata["title"])
    assert_equal("article", co.referent.metadata["genre"])
    assert_equal("10.1016/j.jenvman.2005.11.009", co.referent.metadata["id"])
  end

  
  def test_import_context_object
		kev = "ctx_enc=info%3Aofi%2Fenc%3AUTF-8&ctx_id=10_1&ctx_tim=2006-2-6T14%3A06%3A18EST&ctx_ver=Z39.88-2004&res_id=http%3A%2F%2Forion.galib.uga.edu%2Fsfx_git1&rft.atitle=Open+Linking+in+the+Scholarly+Information+Environment+using+the+OpenURL+Framework&rft.aufirst=Herbert&rft.aulast=Van+de+Sompel&rft.date=2001&rft.genre=article&rft.issn=1082-9873&rft.issue=3&rft.jtitle=D-Lib+magazine&rft.volume=7&rft_id=info%3Adoi%2F10.1045%2Fmarch2001-vandesompel&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&svc_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Asch_svc&url_ctx_fmt=info%3Aofi%3Afmt%3Akev%3Amtx%3Actx&url_ver=Z39.88-2004"
  	co = OpenURL::ContextObject.new
  	co.import_kev(kev)
  	co2 = OpenURL::ContextObject.new
  	co2.import_context_object(co)
    assert_equal(co2.referent.metadata["atitle"], co.referent.metadata["atitle"])
    assert_equal(co2.referent.metadata["jtitle"], co.referent.metadata["jtitle"])
    assert_equal(co2.serviceType[0].format, co.serviceType[0].format)
    assert_equal(co2.resolver[0].identifier, co.resolver[0].identifier)
    assert_equal(co2.referent.identifier, co.referent.identifier)
    assert_equal(co2.referent.metadata["aufirst"], co.referent.metadata["aufirst"])
    assert_equal(co2.referent.metadata["aulast"], co.referent.metadata["aulast"])
    assert_equal(co2.referent.metadata["date"], co.referent.metadata["date"])
    assert_equal(co2.referent.metadata["issn"], co.referent.metadata["issn"])
    assert_equal(co2.referent.metadata["genre"], co.referent.metadata["genre"])
    assert_equal(co2.referent.metadata["issue"], co.referent.metadata["issue"])
    assert_equal(co2.referent.metadata["volume"], co.referent.metadata["volume"])
    assert_equal(co2.referent.format, co.referent.format)
    assert_equal(co2.admin["ctx_enc"]["value"], co.admin["ctx_enc"]["value"])
    assert_equal(co2.admin["ctx_id"]["value"], co.admin["ctx_id"]["value"])
    assert_equal(co2.admin["ctx_tim"]["value"], co.admin["ctx_tim"]["value"])
    assert_equal(co2.admin["ctx_ver"]["value"], co.admin["ctx_ver"]["value"])
  end

  def build_url
      co = OpenURL::ContextObject.new
      myval = Hash.new ()
      myval["atitle"] = "mytitle"
      myval["issue"] = "myissue"
      myval["url_ver"]="Z39.88-2004"
      co.import_hash(myval)
  end
  
  def text_import_xml
		kev = "ctx_enc=info%3Aofi%2Fenc%3AUTF-8&ctx_id=10_1&ctx_tim=2006-2-6T14%3A06%3A18EST&ctx_ver=Z39.88-2004&res_id=http%3A%2F%2Forion.galib.uga.edu%2Fsfx_git1&rft.atitle=Open+Linking+in+the+Scholarly+Information+Environment+using+the+OpenURL+Framework&rft.aufirst=Herbert&rft.aulast=Van+de+Sompel&rft.date=2001&rft.genre=article&rft.issn=1082-9873&rft.issue=3&rft.jtitle=D-Lib+magazine&rft.volume=7&rft_id=info%3Adoi%2F10.1045%2Fmarch2001-vandesompel&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&svc_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Asch_svc&url_ctx_fmt=info%3Aofi%3Afmt%3Akev%3Amtx%3Actx&url_ver=Z39.88-2004"
  	co = OpenURL::ContextObject.new
  	co.import_kev(kev)
  	co2 = OpenURL::ContextObject.new
  	co2.import_xml(co.xml)  	
    assert_equal(co2.referent.metadata["atitle"], co.referent.metadata["atitle"])
    assert_equal(co2.referent.metadata["jtitle"], co.referent.metadata["jtitle"])
    assert_equal(co2.serviceType[0].format, co.serviceType[0].format)
    assert_equal(co2.resolver[0].identifier, co.resolver[0].identifier)
    assert_equal(co2.referent.identifier, co.referent.identifier)
    assert_equal(co2.referent.metadata["aufirst"], co.referent.metadata["aufirst"])
    assert_equal(co2.referent.metadata["aulast"], co.referent.metadata["aulast"])
    assert_equal(co2.referent.metadata["date"], co.referent.metadata["date"])
    assert_equal(co2.referent.metadata["issn"], co.referent.metadata["issn"])
    assert_equal(co2.referent.metadata["genre"], co.referent.metadata["genre"])
    assert_equal(co2.referent.metadata["issue"], co.referent.metadata["issue"])
    assert_equal(co2.referent.metadata["volume"], co.referent.metadata["volume"])
    assert_equal(co2.referent.format, co.referent.format)
    assert_equal(co2.admin["ctx_enc"]["value"], co.admin["ctx_enc"]["value"])
    assert_equal(co2.admin["ctx_id"]["value"], co.admin["ctx_id"]["value"])
    assert_equal(co2.admin["ctx_tim"]["value"], co.admin["ctx_tim"]["value"])
    assert_equal(co2.admin["ctx_ver"]["value"], co.admin["ctx_ver"]["value"])  	
  end

end
