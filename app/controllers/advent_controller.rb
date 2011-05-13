class AdventController < LocaleBaseController
  layout_for_latest_ruby_kaigi

  before_filter :load_events

  # GET /advent
  def index
    respond_to do |format|
      format.html
      format.json { render :json => events_to_json }
      format.ics  { render :text => events_to_ical }
      format.rdf  { render :xml  => events_to_rdf }
    end
  end

  private
  
    def load_events
      AdventEvent.load params[:year]
    end
  
    def events_to_json
      AdventEvent.all.to_json
    end

    def events_to_ical
      RiCal.Calendar do |cal|
        AdventEvent.all.each do |e|
          cal.event do |event|
            event.summary     e.name
            event.description e.description
            event.dtstart     e.dtstart
            event.dtend       e.dtstart
            event.location    e.location
          end
        end
      end.to_s
    end

    def events_to_rdf
      page_url = advent_index_url params[:year], params[:locale]
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.rdf:RDF,   :xmlns        => "http://purl.org/rss/1.0/",
                     :'xmlns:rdf'  => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
                     :"xmlns:dc"   => "http://purl.org/dc/elements/1.1/",
                     :'xmlns:foaf' => "http://xmlns.com/foaf/0.1/",
                     :'xmlns:ical' => "http://www.w3.org/2002/12/cal/icaltzd#",
                     :'xml:lang'   => "ja" do
        xml.channel :'rdf:about' => page_url do
          xml.title "RubyKaigi AdventCalender #{params[:year]}"
          xml.link page_url
          xml.description "RubyKaigi AdventCalender #{params[:year]}"
          xml.items do
            xml.rdf:Seq do
              AdventEvent.all.each{|e| xml.rdf:li, :'rdf:resource' => page_url + "##{e.id}" }
            end
          end
        end

        AdventEvent.all.each do |e|
          xml.item :about => page_with_link_url = page_url + "##{e.id}" do
            xml.title e.name
            xml.description e.description
            xml.pubDate Time.now
            xml.link page_with_link_url
            xml.foaf:topic do
              xml.ical:Vevent do
                xml.ical:dtstart,  e.dtstart
                xml.ical:dtend,    e.dtend
                xml.ical:location, e.location
              end
            end
          end
        end
      end
    end

end
