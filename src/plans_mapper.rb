@src_root = "/home/jonathan/workspaces_src/PlansMapper"
@plans_w_addresses = []
@save_plans_to_fs = false
@read_plans_from_fs = false
@db_user = "root"
@db_pass = ""

require 'browser'
require 'addr_parser'
require 'google_maps'
require 'mysql'

@HELP =<<EOS
  Usage: ruby plans_mapper.rb [OPTIONS] [plans_username] [plans_password]
     -s     save a copy of every plan to /plans
     -r     read plans from /plans dir instead of grinnellplans.com
  Generates plans_map.html
  This project depends on the mechanize gem 1.0.0. Use the gem provided - the newer versions of mechanize are broken.
EOS

## Setup
if ARGV.length < 1
  puts @HELP
  exit
end

if ARGV[0] =~ /^\-\w?s/ 
  @save_plans_to_fs = true
  `rm #{@src_root}/plans/*`
end
if ARGV[0] =~ /^\-\w?r/ then @read_plans_from_fs = true end

## Get Plans
login(ARGV[-2], ARGV[-1])

all_plans_users = get_all_plans_usernames()

all_plans_users.each{|plan_username|
  plan_raw = get_plan_html(plan_username)
  plan_content = get_refined_plan_content( plan_raw )
  plan_address =  choose_best_addr( parse_addrs(plan_content) )
  if plan_address
    usr_data = {:username => plan_username, :address => plan_address}

    geo_data = get_geo_data(plan_address)
    if geo_data
      usr_data.merge!(geo_data)
      @plans_w_addresses.push(usr_data)
    else
      puts "Invalid address"
    end
    sleep(1) #sleep to avoid overloading the geoencoder api
  end
  puts ("[" + plan_username + "]:").ljust(15) + (plan_address ? plan_address : "no address")
}

logout()

puts "Found #{@plans_w_addresses.length} plans with addresses!"

##Write results in html, sql
@con = open_db_conn

puts "Writing out plans_map.html"
@google_maps_data = ""
@is_first = true

@plans_w_addresses.each{|plan_data|

  ## write out data to db
  write_plan_to_db(plan_data)
  
  if @is_first
    delim = ""
    @is_first = false
  else 
    delim = ",\n"
  end
  @google_maps_data += "#{delim}{username:'#{plan_data[:username]}', lat:'#{plan_data[:lat]}', lng:'#{plan_data[:lng]}', addr:'#{plan_data[:address]}'}"  
}

#Write out maps page
#gsub to replace token w/real data
html_template = File.open(@src_root + "/html/map_template.html", "r").read
html_template.gsub!("/* PLAN_DATA_PLACEHOLDER */", @google_maps_data)
html_template.gsub!("<!-- CITIES_LIST_PLACEHOLDER -->", get_city_list())
html_template.gsub!("<!-- NEIGHBORHOODS_LIST_PLACEHOLDER -->", get_neighborhood_list())
output_file = File.open("#{@src_root}/plans_map.html", "w")
bytes_written = output_file.write(html_template)
puts "Wrote " + bytes_written.to_s + " bytes to " + output_file.path

if @con : @con.close() end