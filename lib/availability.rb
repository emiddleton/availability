require 'active_support/all'

module Availability
  
  DOW_NO_TO_OFFSET = {
    "1" => 0,
    "2" => 1.day.to_i,
    "3" => 2.days.to_i,
    "4" => 3.days.to_i,
    "5" => 4.days.to_i,
    "6" => 5.days.to_i,
    "0" => 6.days.to_i
  }

  def merge_time_offset_ranges(time_offset_ranges)
    availability_merge(time_offset_ranges.shift,time_offset_ranges,[])
  end

  def availability_merge(head, rest, res)  
    return res << head if rest.count == 0
    if head[1] < rest[0][0]
      availability_merge(rest.shift, rest, res << head)
    else
      availability_merge( [head[0], [ head[1], rest.shift[1] ].max], rest, res) 
    end
  end

  def utc_to_local_offset_ranges(time_offset_ranges)
    start_of_week_utc = Time.now.utc.monday
    start_of_week = start_of_week_utc.in_time_zone
    time_offset_ranges.inject([]) do |ary,v|
      start_offset = v[0]
      finish_offset = v[1]
      if start_offset == nil
        start_offset = 7.days.to_i
        finish_offset = start_offset + finish_offset
      end
      if finish_offset == nil
        finish_offset = 7.days.to_i
      end
      start_offset_local  = (start_of_week_utc + start_offset).in_time_zone - start_of_week
      finish_offset_local = (start_of_week_utc + finish_offset).in_time_zone - start_of_week
      ary << [start_offset_local.to_i,finish_offset_local.to_i]
      ary
    end.sort_by{|a|a[0]}
  end

  def local_to_utc_offset_ranges(time_offset_ranges)
    start_of_utc_week   = Time.now.utc.monday
    end_of_utc_week     = start_of_utc_week + 7.days.to_i
    start_of_local_week = Time.zone.now.monday
    
    time_offset_ranges.inject([]) do |ary,v|
      start_time_utc  = (start_of_local_week + v[0]).utc
      finish_time_utc = (start_of_local_week + v[1]).utc

      if start_time_utc < start_of_utc_week
        if finish_time_utc > end_of_utc_week
          ary << [0, 7.days.to_i]
        else
          ary << [to_utc_offset(end_of_utc_week + (start_time_utc - start_of_utc_week)),nil]
          ary << [nil,to_utc_offset(finish_time_utc)]
        end
      elsif finish_time_utc > end_of_utc_week
        ary << [to_utc_offset(start_time_utc),nil]
        ary << [nil,to_utc_offset(start_of_utc_week+(finish_time_utc-end_of_utc_week))]
      else
        ary << [to_utc_offset(start_time_utc),to_utc_offset(finish_time_utc)]
      end
    end.sort_by{|a|a[0].to_i}
  end

  def to_utc_offset(value)
    start_of_utc_week = Time.now.utc.monday
    offset = (value - start_of_utc_week).to_i
    raise "time offset of #{offset} is outside valid range 0..#{7.days.to_i}" unless (0..7.days.to_i).include?(offset)
    offset
  end

  def str_to_local_time_offset_ranges(values)
    values.inject([]) do |ary,v|
      day_of_week_no = v[0]
      time_ranges = v[1]
      time_ranges.uniq.each do |time_range|
        begin
          if time_range =~ /^([012]?\d:\d\d|)..([012]?\d:\d\d|)$/
            start_time_str = $1
            finish_time_str = $2
            start_offset =
              if start_time_str.empty? # empty case means from start of day e.g. "..10:00"
                DOW_NO_TO_OFFSET[day_of_week_no]
              elsif start_time_str =~ /^([012]?\d):(\d\d)$/
                DOW_NO_TO_OFFSET[day_of_week_no] + $1.to_i.hours.to_i + $2.to_i.minutes.to_i
              else
                raise "invalid start time %s" % time_range
              end

            finish_offset =
              if finish_time_str.empty? # empty case means end of day e.g. "10:00.."
                DOW_NO_TO_OFFSET[day_of_week_no] + 1.day.to_i
              elsif finish_time_str =~ /^([012]?\d):(\d\d)$/
                DOW_NO_TO_OFFSET[day_of_week_no] + $1.to_i.hours.to_i + $2.to_i.minutes.to_i
              else
                raise "invalid finish time %s" % time_range
              end

            ary << [start_offset, finish_offset]
          else
            logger.warn "invalid time range %s" % time_range
          end
        rescue Exception => e
          logger.warn e.message
        end
      end
      ary
    end.sort_by{|a|a[0]}
  end

  def local_time_offset_ranges_str(time_offset_ranges)
    start_of_week_utc = Time.now.utc.monday
    start_of_week = start_of_week_utc.in_time_zone
    time_offset_ranges.inject({}) do |hash,v|
      start_time = start_of_week + v[0]
      finish_time = start_of_week + v[1]
      start_day = I18n.l(start_time, :format=>'%A')
      hash[start_day] = [] if hash[start_day].nil?

      # handle split over two days.
      if (start_time.wday != finish_time.wday) and finish_time.strftime('%R') != '00:00'
        finish_day = I18n.l(finish_time, :format=>'%A')
        start_str  = start_time.strftime('%R')
        finish_str = finish_time.strftime('%R')
        hash[finish_day] = [] if hash[finish_day].nil?
        hash[start_day] << [start_str,'24:00']
        hash[finish_day] << ['00:00',finish_str]
      else
        start_str  = start_time.strftime('%R')
        finish_str = finish_time.strftime('%R')
        finish_str = '24:00' if finish_str == '00:00'
        start_str  = '00:00' if start_str  == '00:00'
        hash[start_day] << [start_str,finish_str]
      end
      hash
    end 
  end


end
