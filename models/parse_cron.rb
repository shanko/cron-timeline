require "pp"

def parse_time_element(te,from,to)
  ret = []

  if te =~ /^\d+$/
    ret << te.to_i
  elsif te =~ /^[*]$/
    ret = (from..to).to_a
  elsif te =~ /,/
    te.split(',').each do |e|
      if e =~ /^\d+$/
        ret << e.to_i
      elsif e =~ /-/
        ret += parse_time_element(e,from,to)
      else
        raise "Cannot parse: #{te}"
      end
    end
  elsif te =~ /^(\d+)-(\d+)\/?(\d+)?$/
    if $3.to_i < 2
      ret = ($1.to_i..$2.to_i).to_a
    else
      step = $3.to_i
      start = $1.to_i
      stop = $2.to_i
      while start < stop do
        ret << start
        start += step
      end
    end
  elsif te =~ /^[*]\/(\d+)$/
    freq = $1.to_i
    to_limit = (to - from + 1)
    if freq > 0 && freq < to_limit
      to_limit.times do |i|
        m = i * freq
        break if m >= to_limit
        ret << m
      end
    else
      raise "Cannot parse: #{te}"
    end
  else
    raise "Cannot parse: #{te}"
  end
  ret
end

def canonize(min, hr, day, month, wday, cmd)
  cmd_str   = cmd.join(" ")
  minutes   = parse_time_element(min,   0, 59)
  hours     = parse_time_element(hr,    0, 23)
  days      = parse_time_element(day,   1, 31)
  months    = parse_time_element(month, 1, 12)
  week_days = parse_time_element(wday,  0,  6)
  return [minutes, hours, days, months, week_days, cmd_str]
end

def will_execute_at?(cron_entry,at_time=Time.now)
  val = true
  at  = [at_time.min, at_time.hour, at_time.day, at_time.month, at_time.wday]

  cron_entry.each_with_index do |element,i|
    next if element.class == String
    found = false
    element.each{|t| found = (at[i] == t); break if found}
    unless found
      val = found
      break
    end
  end

  val
end

def will_execute_when?(cron_entry,from_time,to_time)
  times = []
  return times if from_time > to_time
  min = 0
  next_minute = from_time + min * 60
  while (next_minute <= to_time)
    times << next_minute if will_execute_at?(cron_entry,next_minute)
    min += 1
    next_minute = from_time + min * 60
  end
  times
end

def cron_hash(cron_jobs,hour_window=1)
  reverse_cron_hash = {}
  cron_jobs.each do |line|
    next if (line.strip.size == 0) || (line =~ /^\s*#/)
    min, hr, day, month, week_day, *cmd = line.strip.split

    begin
      cron_entry =  canonize(min, hr, day, month, week_day, cmd)
      # pp cron_entry

      from, to = Time.now, Time.now + (hour_window * 60 * 60)
      arr = will_execute_when?(cron_entry,from,to)

      arr.each do |time_element|
        if reverse_cron_hash[time_element.to_s]
          reverse_cron_hash[time_element.to_s] << cron_entry[-1] unless reverse_cron_hash[time_element.to_s].include?(cron_entry[-1])
        else
          reverse_cron_hash[time_element.to_s] = [cron_entry[-1]]
        end
      end

    rescue
      puts "---------------------\n"  + line + ' ' + $!.to_s
    end
  end
  reverse_cron_hash
end

def to_timeline_hash(cron_jobs,hour_window)
  chash = cron_hash(cron_jobs,hour_window)
  events_arr = []
  chash.each do |key,val|
     val.each do |cmd|
       events_arr << {"start" => key, "instant" => true, "title" => cmd.split(' ')[0], "description" => cmd}
     end
  end

  event_data = {
    'dateTimeFormat' => 'Gregorian',
    'events'         => events_arr 
  }
  
  # pp event_data

  event_data
end

if __FILE__ == $0
  # min hr day month week-day command
  # cron_jobs = ['*/15  *  *  1 * whoami','*/30  *  *  1 * uname' ]
  # cron_jobs = `crontab -l`
  cron_jobs = File.readlines("cronfile.txt")

  puts
  pp to_timeline_hash(cron_jobs,2)
end



