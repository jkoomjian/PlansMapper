require '../src/browser'

require 'rubygems'
require 'mechanize'

@src_root = "/home/jonathan/workspaces_src/PlansMapper"
@usrname = ARGV[0]
@passwd = ARGV[1]

def test_login
  puts login(@usrname, @passwd).root
end

def test_logout
  login(@usrname, @passwd)
  puts logout.root
end

def test_extract_usernames_from_planslist()
  #puts File.open("/home/jonathan/projects/PlansMapper/test_plans_list/listusers.html", "r").read
  r = extract_usernames_from_planslist( File.open("/home/jonathan/projects/PlansMapper/test_plans_list/listusers.html", "r").read)
  r.each{|i| puts i}
end

def test_get_all_plans_usernames()
  #@read_plans_from_fs = true
  login(@usrname, @passwd)
  all_usernames = get_all_plans_usernames
  puts "# users found: " + all_usernames.length.to_s
  all_usernames.each{|i| puts i}
  logout
end

def test_get_plan_html()
  @save_plans_to_fs = true
  login(@usrname, @passwd)
  puts get_plan_html(@usrname)
end

def test_get_plan_txt_from_page() 
  login(@usrname, @passwd)
  test_plan = get_plan_html(@usrname)
  puts get_plan_txt_from_page(test_plan)
  puts get_plan_txt_from_page("AAA <pre class=\"sub\">BBB</pre> CCC <p class=\"sub\">DDD</p> EEE")
end

def test_remove_html()
  #puts remove_html("hi<a href>asdfadsf</a>jon<input adsf dsaf asdf />howdy")
  #puts remove_html("<b>Check out my new project: <a href=\"http://www.printwhatyoulike.com\" class=\"onplan\">PrintWhatYouLike.com</a></b>")
  puts remove_html( get_plan_txt_from_page( File.open("/home/jonathan/projects/PlansMapper/test_plans/koomjian.html", "r").read ))
end

##---------------------------------------------------------

#test_login
#test_logout
#test_extract_usernames_from_planslist
test_get_all_plans_usernames
#test_get_plan_html
#test_get_plan_txt_from_page()
#test_remove_html()