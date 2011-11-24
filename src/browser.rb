require 'rubygems'
require 'mechanize'

@wwwagent = nil

def login(username, pass)
  if @read_plans_from_fs then return end

  @wwwagent = Mechanize.new
  login_page = @wwwagent.get 'http://www.grinnellplans.com/'
  if login_page.title == "GrinnellPlans"
    login_form = login_page.form("post")
    login_form.username = username
    login_form.password = pass
    login_form.add_field!("submit","Login") #hack to handle plan's incorrect html :(
    login_form.add_field!("js_test_value","on")
    home_page = @wwwagent.submit login_form
    return home_page
  end
end

def logout()
  if @read_plans_from_fs then return end
  return @wwwagent.get 'http://www.grinnellplans.com/index.php?logout=1'
end

#return an array of hashes {plan_url, plan_id}
def get_all_plans_usernames()
  all_plans_usernames = []
  
  if @read_plans_from_fs
    Dir.entries("#{@src_root}/plans").sort.each{|i|
      if i =~ /\.html/i then all_plans_usernames << i.gsub(".html", "") end
    }
    return all_plans_usernames
  end
  
  (97..122).each{|i|
    curr_url = "http://grinnellplans.com/listusers.php?letternum=" + i.to_s
    puts "getting " + curr_url
    plans_list_page = @wwwagent.get curr_url
    all_plans_usernames.concat( extract_usernames_from_planslist(plans_list_page.root.to_s) )
  }

  return all_plans_usernames
end

def extract_usernames_from_planslist(plans_list)
  results = []
  plans_list.scan(/<a href=\"read\.php\?searchname=\w+?\"\s+class=\"planlove\">(\w+)<\/a>/i).each{|i| results << i[0]}
  puts "# names: " + results.length.to_s 
  return results
end

#given a plan username, get the text content of that plan - parse to remove all html code
def get_plan_html(username)
  if @read_plans_from_fs
    return File.open("#{@src_root}/plans/#{username}.html", "r").read
  end

  plan_html = @wwwagent.get("http://grinnellplans.com/read.php?searchname=" + username).root.to_s
  if @save_plans_to_fs then File.open("#{@src_root}/plans/#{username}.html", "w").write(plan_html) end
  return plan_html
end

#get the content from the plan
def get_refined_plan_content(plan_html)
 return remove_html( get_plan_txt_from_page(plan_html) ) 
end

def get_plan_txt_from_page(plan_html)
  results = ""
  plan_html.scan(/<p(re)? class="sub">(.*?)<\/p(re)?>/im).each{|m|
    results += m[1] + " "
  }
  return results
end

def remove_html(plan_html)
  return plan_html.gsub(/<\/?\w+.*?>/m, " ")  
end