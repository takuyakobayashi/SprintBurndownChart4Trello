module GraphDataCreator
	class << self
	def ideal_data(num_of_sprint_days, total_estimated_time)
		result = Array.new

	    consume_time_per_day = total_estimated_time / (num_of_sprint_days - 1)
	    0.upto(num_of_sprint_days - 1) { |day|
	    	remain_time = day == 0 ? total_estimated_time : total_estimated_time - (day * consume_time_per_day)
	        result[day] = remain_time
	    }

	    result
	end

	def remain_times_data(num_of_sprint_days, sprint_period, total_estimated_time, 
		week_day_consumed_times, week_day_additional_times)
		result = Array.new

	    0.upto(num_of_sprint_days - 1) { |i|
	        break if over_today?(sprint_period[i])
	        # 対象日の前日までのポイントを取得
	        remain_time_before_day = i == 0 ? total_estimated_time : result[i - 1]
	        # 今日の消化ポイントを取得
	        today_consumed_time = week_day_consumed_times[sprint_period[i]]
	        # 今日の追加ポイントを取得
	        today_add_time = week_day_additional_times[sprint_period[i]]
	        result[i] = remain_time_before_day - today_consumed_time + today_add_time
	    }

	    result
	end

	def additional_times_data(num_of_sprint_days, sprint_period, week_day_additional_times)
		result = Array.new

	    0.upto(num_of_sprint_days - 1) { |i|
	        additional_time = week_day_additional_times[sprint_period[i]]
	        result[i] = additional_time if additional_time != nil
	    }

	    result
	end

	def total_estimated_time_data(num_of_sprint_days, sprint_period, total_estimated_time,
		week_day_additional_times)
		result = Array.new
		0.upto(num_of_sprint_days - 1) { |i|
	        break if over_today?(sprint_period[i])
			next result[i] = total_estimated_time if i == 0
			estimated_time = result[i - 1]
			result[i] = result[i - 1] + week_day_additional_times[sprint_period[i]]
	    }

	    result
	end

	def over_today?(date_str)
		DateTime.parse(date_str) > DateTime.parse(DateTime.now.strftime("%Y-%m-%d"))
	end
	end
end