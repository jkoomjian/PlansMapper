def assert(p)
  if p == true
    puts "Good"
    return
  else
    puts "Error!"
  end
end

def assertf(p)
  assert(!p)
end
