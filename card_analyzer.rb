module CardAnalyzer
	class << self
	def additional_task?(card)
		
		labels = card["labels"]
		false if labels == nil

		add_label = labels.select { |label| label["name"] == "追加タスク" }[0]
		
		add_label != nil
	end

	def get_additional_date(card)
		
		actions = card["actions"]
		created_action = actions.select { |action| action["type"] == "createCard" }[0]

		additional_date = DateTime.parse(created_action["date"]) + (9.0/24.0)
		additional_date.strftime("%Y-%m-%d")
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
		moved_to_done_date.strftime("%Y-%m-%d")
	end
	end
end