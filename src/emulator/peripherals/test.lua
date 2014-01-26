{
	["type"] = "test",
	["methods"] = {
		["foo"] = function(computer, data, arg1, arg2)
			return "hello"
		end,
		["get"] = function(computer, data)
			return data.bar
		end,
	}
}
