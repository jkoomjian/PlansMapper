#return a hash containing all the entires. Value of 2 = partial match (York) and 1 = full match (New York)
def parse_geo_data(geo_file_path, include_partial_matches=true)
  data = {}
  data_txt = File.open(geo_file_path, "r").read.downcase
  data_txt.split(/\n/).each{|line|
    if line.length > 0
      data[line.downcase] = 1
      if line =~ /\s+/ && include_partial_matches
        tokens_so_far = ""
        line.split(/\s+/).reverse.each {|token|
          tokens_so_far = token + (tokens_so_far.length>0 ? (' ' + tokens_so_far) : '').downcase   
          data[tokens_so_far] = 2 unless data.has_key?(tokens_so_far) && data[tokens_so_far] == 1
        }
      end
    end
  }
  return data
end

@all_states = parse_geo_data(@src_root + "/geo_data/us_states.txt")
@all_cities = parse_geo_data(@src_root + "/geo_data/us_cities.txt")
@street_abbvs = parse_geo_data(@src_root + "/geo_data/us_street_abbvs.txt", false)
@directions = parse_geo_data(@src_root + "/geo_data/directions.txt", false)
@debug = false

def is_zip_cd(token)
  return token.match(/\d{5}(-\d{4})?/) != nil
end

#if require_full_match=true, token must match a full state name (ex. new york). if false token may match a part of the state (ex. york)
def is_state(token, require_full_match=false)
  return _is_match(token, require_full_match, @all_states)
end

def is_city(token, require_full_match=false)
  return _is_match(token, require_full_match, @all_cities)
end

def is_apt_type(token)
  return  (token =~ /ap(ar)?t/i ||         # apt
          token =~ /\d+/ ||                #contains a #
          token =~/(unit|bldg|#)/i ||     #apt abbrevs
          token =~ /[\^\s]\w{1}[$\s]/i     #contains a single letter or digit
          ) != nil
end

def is_street_type(token)
  return _is_match(token, true, @street_abbvs)
end

def is_house_nbr(token)
  return token.match(/^\d{1,6}$/) != nil
end

def contains_direction(input)
  @directions.each_key{|dir| if input.downcase.match( Regexp.new("(^|\s)#{dir}($|\s)") ) != nil: return true end }
  return false
end

def _is_match(token, require_full_match, geo_data)
  #return geo_data.match( Regexp.new( (require_full_match ? '^' : '[\^\s]') + token.downcase + (require_full_match ? '$' : '[$\s]') ) ) != nil
  return geo_data.has_key?(token.downcase) && (!require_full_match || geo_data[token.downcase] == 1)
end

## Rules - method which returns goto level (will be -1 for no match)
@rules = []
#first rule - figure out if we are dealing with a zip, state, or city
@rules[0] = lambda{|input, grammar|
  if is_zip_cd(input)
    grammar[:addr_zip] = input
    return 10
  elsif is_state(input)
    grammar[:addr_state] = input
    return 10
  elsif is_city(input)
    grammar[:addr_city] = input
    return 20
  else
    return -1
  end
}
#2nd rule - parse state
@rules[10] = lambda{|input, grammar|
  #states can be up to 3 words long (District of Columbia)
  if grammar.has_key?(:addr_state)
     #multi-word states
    if is_state(input + " " + grammar[:addr_state])
      grammar[:addr_state] = input + " " + grammar[:addr_state]
      return 10
    else
      #must be a city token - goto city level
      if is_state(grammar[:addr_state], true)
        #there's always one troublemaker
        if grammar[:addr_state].match(/(^|\s)DC($|\s)/i) != nil
          #set dc as the city and jump to apt. no
          grammar[:addr_city] = grammar[:addr_state]
          return @rules[21].call(input, grammar)
        else          
          return @rules[20].call(input, grammar)
        end
      else
        return -1
      end
    end
  else
    #first word in state
    if is_state(input)
      grammar[:addr_state] = input
      return 10
    else
      return -1
    end
  end
}
#3rd rule - parse city
@rules[20] = lambda{|input, grammar|
  if grammar.has_key?(:addr_city)
    if is_city(input + " " + grammar[:addr_city])
      grammar[:addr_city] = input + " " + grammar[:addr_city]
      return 20
    else
      #make sure we have a full city, not a city part, before going to apartment no. ("Truth or Consequences" is good, just "or" is bad)
      if is_city(grammar[:addr_city], true)
        return @rules[21].call(input, grammar)
      else
        return -1
      end
    end
  else
    if is_city(input)
      grammar[:addr_city] = input
      return 20
    else
      return -1
    end
  end
}
#Parse City Quarter (Ex. West St. Paul)
@rules[21] = lambda{|input, grammar|
  if @directions.has_key?(input.downcase)
    grammar[:addr_city] = input + " " + grammar[:addr_city]
    return 21
  else
    return @rules[30].call(input, grammar)
  end
}

#4th rule - parse apartment no.
@rules[30] = lambda{|input, grammar|
  if !grammar.has_key?(:addr_apt_no) then grammar[:addr_apt_no] = "" end
  if !grammar.has_key?(:addr_apt_no_countdown) then grammar[:addr_apt_no_countdown] = 5 end #allow 5 words in the apartment # before giving up
  if grammar[:addr_apt_no_countdown] <= 0
    #TODO fix parser to handle addreses without a street abbreviation
    if grammar.has_key?(:addr_zip) && grammar.has_key?(:addr_state) && grammar.has_key?(:addr_city)
      #Begin appalling hack - just remove all text in front of the first #
      if grammar[:addr_apt_no] =~ /\d/
        grammar[:addr_apt_no] = grammar[:addr_apt_no].slice(grammar[:addr_apt_no] =~ /\d/, grammar[:addr_apt_no].length)
        grammar[:tokens] = (grammar[:addr_apt_no] + " " + grammar[:addr_city] + " " + grammar[:addr_state] + " " + grammar[:addr_zip]).split(/\s+/).reverse
        grammar[:dont_add_input] = true  
        return 70
      end
    end
    return -1 
  end
  
  if is_street_type(input)
    #if apartment exists, verify it is an actual apt address
    #some cities include direction after street type - allow that here
    if grammar[:addr_apt_no].length == 0 || is_apt_type(grammar[:addr_apt_no]) || contains_direction(input)
      return @rules[40].call(input, grammar) #goto street_type
    else
      return -1
    end
  else
    grammar[:addr_apt_no] = input + " " + grammar[:addr_apt_no]
    grammar[:addr_apt_no_countdown] -= 1
    return 30
  end
}
#5th rule - parse street type
@rules[40] = lambda{|input, grammar|
  if is_street_type(input)
    grammar[:addr_street_type] = input
    return 50
  else
    return -1
  end
}

#6 rule - parse street
@rules[50] = lambda{|input, grammar|
  if !grammar.has_key?(:addr_street) 
    #the word before the street type is never the house no., even if it is a number (ex 123 5 st.)
    grammar[:addr_street] = input
    grammar[:addr_street_countdown] = 5 #allow 5 words before giving up
    return 50
  end
  
  if grammar[:addr_street_countdown] <= 0 then return -1 end
  
  if is_house_nbr(input)
    return @rules[60].call(input, grammar) #goto house number
  else
    grammar[:addr_street] = input + " " + grammar[:addr_street]
    grammar[:addr_street_countdown] -= 1
    return 50
  end
}
#7th rule - parse house no.
@rules[60] = lambda{|input, grammar|
  if is_house_nbr(input)
    grammar[:addr_house_nbr] = input
    return 70
  else
    return -1
  end
}


def parse_addrs(plan_src)

  ##Current Stack - include array of tokens, current rule level
  curr_stack = []
  ##good addresses!
  good_grammars = []

  #remove non-word characters
  plan_src = plan_src.gsub(/[^A-Za-z0-9\-\s#]/, " ")
  #puts plan_src
  #return
    
  #tokenize the string - delimit by whitespace - reverse the array to make it easier to parse
  tokenized_str = plan_src.split(/\s+/).reverse
  
  #iterate through all the tokens
  tokenized_str.each { |input|
    if (input =~ /\w/) == nil : next end
    
    #add a new grammar to the stack
    curr_stack.push( {:tokens => [], :level => 0} )
    
    #go through each grammar on current_stack and add the new input - use a while loop to allow delete_at
    puts "\n" unless !@debug
    index = 0
    while index < curr_stack.length
      curr_grammar = curr_stack[index]
      curr_rule = @rules[ curr_grammar[:level] ]
      result = curr_rule.call(input, curr_grammar)
      if @debug : puts(input + " [" + curr_grammar[:tokens].join(" ") + "] start=>" + curr_grammar[:level].to_s + " end=>" + result.to_s) end
      case result
      when -1
        ##failed! pop curr_grammar from the stack
        curr_stack.delete_at(index)
      when 70
        ##terminated successfully! add to good_grammars
        curr_grammar[:tokens].push(input) unless curr_grammar[:dont_add_input]
        good_grammars.push( curr_stack.delete_at(index) )
      else
        ##goto the next level
        curr_grammar[:tokens].push(input)
        curr_grammar[:level] = result
        index += 1
      end
    end
  }

  #return an array of all found addresses in str form
  return good_grammars
end

#a plan may have multiple addresses - use the most qualified one
def choose_best_addr(addrs)
  if addrs.length == 0 then return nil end
  best_addr = {:addr => nil, :score => 0}
  
  addrs.each{|plan|
    score = 0
    if plan.has_key?(:addr_zip) then score += 2 end
    if plan.has_key?(:addr_state) then score += 2 end
    score += plan[:addr_city].split(" ").length
    if score > best_addr[:score] then best_addr = {:addr => plan, :score => score} end
    puts score.to_s + ": " + plan[:tokens].reverse.join(" ") unless !@debug
  }

  return best_addr[:addr][:tokens].reverse.join(" ")
end