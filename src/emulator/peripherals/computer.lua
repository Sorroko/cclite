{
	["type"] = "computer",
	["methods"] = {
		-- data.computer should be set when creating peripheral, with the target/related computer
		["turnOn"] = function(computer, data)
			if not data.computer.running then
				data.computer:start()
			end
		end,
		["shutdown"] = function(computer, data)
			if data.computer.running then
				data.computer:stop()
			end
		end,
		["reboot"] = function(computer, data)
			if data.computer.running then
				data.computer:stop( true )
			end
		end,
		["getID"] = function(computer, data)
			return data.computer.id
		end,
	}
}
