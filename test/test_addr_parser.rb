@src_root = "/home/jonathan/workspaces_src/PlansMapper"

require '../src/addr_parser'
require '../src/browser'
require 'test'

def test_is_zip_cd
  assert is_zip_cd("12345")
  assert is_zip_cd("12345-1234")
  assertf is_zip_cd("123")
  assertf is_zip_cd("aasdf")
end

def test_is_state()
  assert is_state("IL")
  assert is_state("Il", true)
  assert is_state("Washington DC")
  assert is_state("DC")
  assert is_state("wisc")
  assert is_state("iowa")
  assert is_state("rhode island")
  assert is_state("district of columbia")
  assert is_state("cali")
  assert is_state("miss")
  assert is_state("york")
  assertf is_state("york", true)
  assert is_state("of")
  assertf is_state("of", true)
  assert is_state("california")
  assertf is_state("ali")
  assertf is_state("asdfasd")
  assertf is_state("colu")
end

def test_is_city()
  # puts "cities tokens " + @all_cities.length.to_s
  assert is_city("new york city")
  assert is_city("Des Moines")
  assert is_city("Des Moines", true)
  assert is_city("Moines")
  assertf is_city("Moines", true)
  assert is_city("grinnell")
  assert is_city("newton")
  assert is_city("lucas")
  assert is_city("pisgah")
  assert is_city("nyc")
  assertf is_city("rinnell")
  assertf is_city("Moine")
  assertf is_city("and", true)
  assert is_city("Shoreline", true)
  assert is_city("South St Paul", true)
end

def test_is_apt_type()
  assert is_apt_type("apt 1")
  assert is_apt_type("apart 2")
  assert is_apt_type("#2")
  assert is_apt_type("#A")
  assert is_apt_type("unit a")
  assert is_apt_type("floor a first")
  assert is_apt_type("floor 3b")
  assertf is_apt_type("floor abadsf first")
end

def test_is_street_type()
  assert is_street_type("street")
  assert is_street_type("st")
  assert is_street_type("str")
  assert is_street_type("ave")
  assert is_street_type("avenue")
  assert is_street_type("place")
  assert is_street_type("circle")
  assert is_street_type("way")
  assert is_street_type("hwy")
  assert is_street_type("junction")
  assert is_street_type("blvd")
  assert is_street_type("drive")
  assertf is_street_type("chicago")
  assertf is_street_type("il")
  assertf is_street_type("lvd")
end

def test_is_house_nbr
  assert is_house_nbr("1")
  assert is_house_nbr("123456")
  assertf is_house_nbr("1234567")
  assertf is_house_nbr("adsf")
end

def test_parse_addrs_part1()
  puts "washington dc".match(/(^|\s)DC($|\s)/i)
end

def test_contains_direction
  assert contains_direction("apt 2 N")
  assert contains_direction("N apt 2")
  assertf contains_direction("apt 2")
  assert contains_direction("west apt 2")
  assertf contains_direction("westapt 2")
end

def test_parse_addrs() 
  #plan_str = "Contact Info:  jkoomjian@gmail.com    755 17th St.  Des Moines, IA 50314  (515) 243-5829"
  #plan_str = "316 10th Street N #2 NE Washington DC 20002"
  #plan_str = get_plan_content(File.open("/home/jonathan/projects/PlansMapper/test_plans/warlicks.html", "r").read)
  plan_usr = "mauritz"
  plan_str = get_refined_plan_content(File.open("#{@src_root}/plans/#{plan_usr}.html", "r").read)
  results = parse_addrs(plan_str)
  
  puts "\n"
  puts results.length
  results.each{|g| puts g[:tokens].reverse.join(" ")}
  
  puts "\nbest"
  puts choose_best_addr(results)
end

def test_parse_geo_data
  all_states = parse_geo_data(@src_root + "/geo_data/us_states.txt")
  all_states.each{|key, value| puts "[#{key}]: #{value}"}
end

##---------------------
#test_is_zip_cd()
#test_is_state()
# test_is_city()
#test_is_apt_type
#test_is_street_type()
#test_is_house_nbr()
#test_contains_direction
test_parse_addrs()
#test_parse_geo_data