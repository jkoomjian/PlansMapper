require 'rubygems'
require 'uri'
require 'net/http'
require 'json'

def get_geo_data(addr)
  begin
    url = "http://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(addr)}&sensor=false&region=us"
    resp = Net::HTTP.get_response(URI.parse(url))
    result = JSON.parse(resp.body)
  
    if result['results'].length == 0 then return nil end
  
    neighborhood = city = state = zip = nil
    result['results'][0]['address_components'].each{|token|
        if token['types'][0].downcase == "neighborhood" : neighborhood = token['long_name'] end
        if token['types'][0].downcase == "locality" : city = token['long_name'] end
        if token['types'][0].downcase == "administrative_area_level_1" : state = token['long_name'] end
        if token['types'][0].downcase == "postal_code" : zip = token['long_name'] end
    }
    if !neighborhood : neighborhood = city end
  
    return {
            :lng => result['results'][0]['geometry']['location']['lng'].to_s,
            :lat => result['results'][0]['geometry']['location']['lat'].to_s,
            :formatted_addr => result['results'][0]['formatted_address'],
            :city => city,
            :neighborhood => neighborhood,
            :state => state,
            :zip => zip
          }
  rescue
    puts "Error retrieving geoencoding for: " + addr
    return nil
  end
end

#------------- SQL Stuff -----------------#
def open_db_conn
  begin
   return Mysql.new('localhost', @db_user, @db_pass, 'plans_mapper')
  rescue StandardError => bang
    puts "Unable to save sql data: " + bang
  end
end

def write_plan_to_db(plan_data)
  begin
    q = "insert into addresses (username, lat, lng, addr, city, neighborhood, state, zip) values ('#{@con.escape_string(plan_data[:username])}', '#{plan_data[:lat]}', '#{plan_data[:lng]}', '#{@con.escape_string(plan_data[:address])}', '#{@con.escape_string(plan_data[:city])}', '#{@con.escape_string(plan_data[:neighborhood])}', '#{plan_data[:state]}', '#{plan_data[:zip]}')"
    @con.query(q)
  rescue StandardError => bang
    puts "Failed to insert SQL Query!: " + bang
    puts q
  end
end

def get_city_list
  rs = @con.query("select count(city), city from addresses where city <> '' group by city order by count(city) desc limit 100")
  index = 1
  html = "<table><tr><td>Rank</td><td># Grinnellians</td><td>City</td></tr>"
  rs.each_hash{|row|
    html += "<tr>"
    html += "<td>#{index}</td><td>#{row['count(city)']}</td><td>#{@con.escape_string(row['city'])}</td></tr>"
    html += "</tr>"
    index += 1
  }
  html += "</table>"
  return html
end

def get_neighborhood_list
  rs = @con.query("select count(neighborhood), neighborhood, city from addresses where neighborhood <> '' group by neighborhood, city order by count(*) desc limit 100;")
  index = 1
  html = "<table><tr><td>Rank</td><td># Grinnellians</td><td>Neighborhood</td><td>City</td></tr>"
  rs.each_hash{|row|
    html += "<tr>"
    html += "<td>#{index}</td><td>#{row['count(neighborhood)']}</td><td>#{@con.escape_string(row['neighborhood'])}</td><td>#{@con.escape_string(row['city'])}</td></tr>"
    html += "</tr>"
    index += 1
  }
  html += "</table>"
  return html
end