class Trello

	TORELLO_BASE_PATH="https://trello.com/1"

	def initialize()
		setting = YAML.load_file(File.dirname(__FILE__) + "/settings.yml")
		@key = setting["Key"]
		@token = setting["Token"]
		@board_id = setting["BoardId"]
	end

	def get_all_lists(os)
		return JSON.parse(HTTPClient.new.get_content(TORELLO_BASE_PATH+"/boards/"+@board_id[os]+"/lists?fields=name&filter=open&key="+@key+"&token="+@token))
	end

	def get_cards(list_id)
		return JSON.parse(HTTPClient.new.get_content(TORELLO_BASE_PATH+"/lists/"+list_id+"/cards?actions=all&fields=actions,labels,name&key="+@key+"&token="+@token))
	end

	def get_all_closed_lists(os)
		return JSON.parse(HTTPClient.new.get_content(TORELLO_BASE_PATH+"/boards/"+@board_id[os]+"/lists?fields=name&filter=closed&key="+@key+"&token="+@token))
	end
end