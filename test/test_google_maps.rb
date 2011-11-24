require '../src/google_maps'
require 'mysql'
@db_user = "root"
@db_pass = ""

def test_get_geo_data
  #str = "666 Park Pl Apt 4L Brooklyn NY 11216"
  #str = "755 17th Street Des Moines, Iowa 50314"
  #str = "5000 S East End Ave Chicago IL 60615"
  #str = "1203 Main St Grinnell IA 50112"
  str = "1770 Jeffrey Drive Yuba City CA 95991"
  
  r = get_geo_data(str)
  if r
    puts "lat: " + r[:lat]
    puts "lng: " + r[:lng]
    puts "formatted_addr " + r[:formatted_addr]
    puts "city: " + r[:city]
    puts "neighborhood " + r[:neighborhood]
    puts "state " + r[:state]
    puts "zip " + r[:zip]
  end
end

def test_write_plan_to_db
  plan = {
            :username => 'koomjian', 
            :address => '755 17th Street Des Moines IA 50314',
            :lng => '1',
            :lat => '2',
            :formatted_addr => '755 17th Street Des Moines IA 50314',
            :city => 'Des Moines',
            :neighborhood => 'Sherman Hill',
            :state => 'IA',
            :zip => '50314'
  }
  
  @con = open_db_conn
  write_plan_to_db(plan)
  if @con : @con.close() end
end

#--------------------------
#test_get_geo_data
#get_sql_stmt_for_all_addrs
test_write_plan_to_db