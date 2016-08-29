require 'bundler'
Bundler.require
require "json"
require 'date'
require 'yaml'
require './trello_api'
require './graph_data_creator'

$sprint_date = YAML.load_file(File.dirname(__FILE__) + "/data/sprint_date.yml")

get '/sbc/:os/:ph/:sp' do |os,ph,sp|
    init(ph,sp)
    create_origin_data(os)
    create_graph_data()
    erb :index
end

def init(ph,sp)
    @trello = Trello.new if @trello == nil

    @graph_data_ideal = Array.new
    @graph_data_remain_times = Array.new
    @graph_data_additional_times = Array.new
    @graph_data_total_estimated_times = Array.new

    phase = get_phase(ph)
    sprint = get_sprit(sp)
    @sprint_title = phase + " " + sprint

    @sprint_period = get_sprint_date(phase,sprint)
    
    @total_estimated_times = 0.0
    @week_day_consumed_times = Hash.new(0)
    @week_day_additional_times = Hash.new(0)
end

def create_origin_data(os)
    # TODO エラーハンドリング
    return set_dummy_data() if @sprint_period == nil

    lists = get_target_lists(os)

    # TODO エラーハンドリング
    return set_dummy_data() if lists == nil

    lists.each { |list|
    	list_id = list["id"]
    	list_name = list["name"]
    	cards = @trello.get_cards(list_id)

    	cards.each { |card|
    		estimated_time = get_estimated_time(card)
    		# 見積もり時間が設定されてないものはスキップ
    		next if estimated_time == 0

			# 追加タスク or 初期タスク
			if additional_task?(card)
				# 追加された日付を取得
				additional_date_str = get_additional_date(card)

				current_additional_time = @week_day_additional_times[additional_date_str]
				@week_day_additional_times[additional_date_str] = current_additional_time + estimated_time
			else
				@total_estimated_times += estimated_time
			end

			if list_name == "DONE"
				# DONE に移動された最新の日付を取得
				moved_to_done_date_str = get_latest_done_date(card)

				current_week_day_consumed_time = @week_day_consumed_times[moved_to_done_date_str]
				@week_day_consumed_times[moved_to_done_date_str] = current_week_day_consumed_time + estimated_time
			end
			}
		}
end

def get_target_lists(os)

    # 表示対象が現在のスプリントか
    return @trello.get_all_lists(os) if current_sprint?(@sprint_period[0], @sprint_period[@sprint_period.size - 1])

    closed_lists = @trello.get_all_closed_lists(os)
    target_list_name = get_target_list_name()
    return closed_lists.select { |list| list["name"] == target_list_name }[0]
end

def additional_task?(card)
	labels = card["labels"]
	return false if labels == nil

	add_label = labels.select { |label| label["name"] == "追加タスク" }[0]
	return add_label != nil
end

def get_additional_date(card)
	actions = card["actions"]
	created_action = actions.select { |action| action["type"] == "createCard" }[0]

	additional_date = DateTime.parse(created_action["date"]) + (9.0/24.0)
	return additional_date.strftime("%Y-%m-%d")
end

def get_latest_done_date(card)
	latest_action = nil
	card["actions"].each { |action|
		if action["type"] == "updateCard" && action["data"]["listAfter"] != nil && action["data"]["listAfter"]["name"] == "DONE" || 
            action["type"] == "createCard" && action["data"]["list"] != nil && action["data"]["list"]["name"] == "DONE"

			next latest_action = action if latest_action == nil

			latest_action_time = DateTime.parse(latest_action["date"]) + (9.0/24.0)
			action_time = DateTime.parse(action["date"]) + (9.0/24.0)

			latest_action = action if action_time > latest_action_time
		end
	}
	moved_to_done_date = DateTime.parse(latest_action["date"]) + (9.0/24.0)
	return moved_to_done_date.strftime("%Y-%m-%d")
end

def create_graph_data()
    num_of_sprint_days = @sprint_period.length
    # 理想線用データ
    @graph_data_ideal = GraphDataCreator.ideal_data(num_of_sprint_days,@total_estimated_times)
    # 消費線用データ
    @graph_data_remain_times = GraphDataCreator.remain_times_data(num_of_sprint_days,@sprint_period,
                                    @total_estimated_times,@week_day_consumed_times,@week_day_additional_times)
    # 追加タスク用データ作成
    @graph_data_additional_times = GraphDataCreator.additional_times_data(num_of_sprint_days,@sprint_period,@week_day_additional_times)

    # 総時間用データ作成
    @graph_data_total_estimated_times = GraphDataCreator.total_estimated_time_data(num_of_sprint_days,@sprint_period,@total_estimated_times,@week_day_additional_times)
end

# Util
def get_estimated_time(card)
    # カード名
    card_name = card["name"]
    # (X)で見積もり時間が振ってあるので抽出
    estimated_time = card_name.match(/.*\((.+)\)*/)

    return estimated_time[1].to_f if estimated_time != nil

    return 0.0
end
def get_phase(ph)
    return "Phase " + ph.delete("ph")
end
def get_sprit(sp)
    return "Sprint " + sp.delete("sp")
end
def get_sprint_date(ph,sp)
    return $sprint_date[ph][sp]
end
def current_sprint?(sprint_start_date_str, sprint_end_date_str)
    return DateTime.parse(sprint_start_date_str) <= DateTime.parse(DateTime.now.strftime("%Y-%m-%d")) && DateTime.parse(DateTime.now.strftime("%Y-%m-%d")) <= DateTime.parse(sprint_end_date_str)
end
def get_target_list_name()
    return "Phase2_SP" + @sprint_title.delete("Sprint ")
end
def set_dummy_data()
    @graph_data_ideal=[73.0,64.88888888888889,56.77777777777778,48.66666666666667,40.55555555555556,32.44444444444444,24.333333333333336,16.22222222222223,8.111111111111114,0]
    @graph_data_remain_times=[73.0,63.0,52.5,43.5,40.5,37.5,37.5,23.0,11,0]
    @graph_data_additional_times=[0,2,3,4,5,6,5,4,3,2]
    @sprint_title="Phase Dummy Sprint Dummy"
    @sprint_period=["2016-08-03","2016-08-04","2016-08-05","2016-08-08","2016-08-09","2016-08-10","2016-08-11","2016-08-12","2016-08-15","2016-08-16"]
end