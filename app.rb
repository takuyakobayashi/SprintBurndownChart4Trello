require 'bundler'
Bundler.require
require "json"
require 'date'
require 'yaml'
require './trello_api'
require './graph_data_creator'
require './card_analyzer'

get '/sbc/:os/:ph/:sp' do |os,ph,sp|
    init()
    init_graph(ph,sp)
    create_origin_data(os)
    create_graph_data()
    erb :index
end

get '/sbc/add' do erb :sprint_setting end

post '/sbc/add' do
    $sprint_date = YAML.load_file(File.dirname(__FILE__) + "/data/sprint_date.yml")
    phase = $sprint_date["Phase " + params[:phase]]
    selected_dates  = params[:dates].gsub!('/', '-').split(",")
    if phase

        sprint = phase["Sprint " + params[:sprint]]
        if sprint
            status 204
        else
            status 200
            new_sprint_date = $sprint_date.dup
            new_sprint_date["Phase " + params[:phase]]["Sprint " + params[:sprint]] = selected_dates
            open("./data/sprint_date.yml", "w") {|f|
                YAML.dump(new_sprint_date, f)
            }
        end

    else
        status 200
        new_sprint_date = $sprint_date.dup
        new_sprint_date["Phase " + params[:phase]] = {'Sprint ' + params[:sprint] => selected_dates}
        open("./data/sprint_date.yml", "w") {|f|
            YAML.dump(new_sprint_date, f)
        }
    end

    body 'success'
end

get '/' do
    init()
    erb :index
end
get '*' do redirect to('/') end

def init()
    # view data
    @all_sprints_list = get_all_sprints_list()
end

def init_graph(ph,sp)
    @trello = Trello.new if @trello == nil

    @graph_data_ideal = Array.new
    @graph_data_remain_times = Array.new
    @graph_data_additional_times = Array.new
    @graph_data_total_estimated_times = Array.new

    @phase = ph.delete("ph")
    @sprint = sp.delete("sp")

    # graph data
    @sprint_period = $sprint_date["Phase " + @phase]["Sprint " + @sprint]
    @closed_list_title = "Phase" + @phase + "_SP" + @sprint
    @total_estimated_times = 0.0
    @week_day_consumed_times = Hash.new(0)
    @week_day_additional_times = Hash.new(0)
end

def create_origin_data(os)
    # TODO エラーハンドリング
    return set_dummy_data() if @sprint_period == nil

    is_current_sprint = current_sprint?(@sprint_period[0], @sprint_period[@sprint_period.size - 1])
    lists = get_target_lists(os, is_current_sprint)

    # TODO エラーハンドリング
    return set_dummy_data() if lists == nil

    lists.each { |list|
    	list_id = list["id"]
    	list_name = list["name"]

        next if !is_current_sprint && list_name != @closed_list_title

        cards = @trello.get_cards(list_id)
    	cards.each { |card|

            estimated_time = get_estimated_time(card)
            # 見積もり時間が設定されてないものはスキップ
            next if estimated_time == 0

            # 追加タスク or 初期タスク
            if CardAnalyzer.additional_task?(card)
                # 追加された日付を取得
                additional_date_str = CardAnalyzer.get_additional_date(card)
                @week_day_additional_times[additional_date_str] += estimated_time
            else
                @total_estimated_times += estimated_time
            end

            # 対象スプリントでない場合 かつ リスト名が一致する場合
            if !is_current_sprint && list_name == @closed_list_title || list_name == "DONE"
                # DONE に移動された最新の日付を取得
                moved_to_done_date_str = CardAnalyzer.get_latest_done_date(card)
                @week_day_consumed_times[moved_to_done_date_str] += estimated_time
            end
		}
	}
end

def get_target_lists(os, is_current_sprint)

    # 表示対象が現在のスプリントか
    return @trello.get_all_lists(os) if is_current_sprint

    closed_lists = @trello.get_all_closed_lists(os)
    return closed_lists.select { |list| list["name"] == @closed_list_title }
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

def current_sprint?(sprint_start_date_str, sprint_end_date_str)
    return DateTime.parse(sprint_start_date_str) <= DateTime.parse(DateTime.now.strftime("%Y-%m-%d")) && DateTime.parse(DateTime.now.strftime("%Y-%m-%d")) <= DateTime.parse(sprint_end_date_str)
end
def set_dummy_data()
    @graph_data_ideal=[73.0,64.88888888888889,56.77777777777778,48.66666666666667,40.55555555555556,32.44444444444444,24.333333333333336,16.22222222222223,8.111111111111114,0]
    @graph_data_remain_times=[73.0,63.0,52.5,43.5,40.5,37.5,37.5,23.0,11,0]
    @graph_data_additional_times=[0,2,3,4,5,6,5,4,3,2]
    @closed_list_title="Phase Dummy Sprint Dummy"
    @sprint_period=["2016-08-03","2016-08-04","2016-08-05","2016-08-08","2016-08-09","2016-08-10","2016-08-11","2016-08-12","2016-08-15","2016-08-16"]
end

# for View data
def get_all_sprints_list()
    result = Hash.new(0)
    $sprint_date = YAML.load_file(File.dirname(__FILE__) + "/data/sprint_date.yml")

    $sprint_date.keys.each { |phase|
        sprints = Array.new
        $sprint_date[phase].each { |sprint|
            sprints.push(sprint[0])
        }
        result[phase] = sprints
    }
    result
end