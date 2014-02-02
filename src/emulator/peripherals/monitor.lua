{
	["type"] = "monitor",
	["methods"] = {
		["clear"] = function(computer, data)
			data.screen:clear()
		end,
		["clearLine"] = function(computer, data)
			data.screen:clearLine()
		end,
		["getSize"] = function(computer, data)
			return data.screen:getSize()
		end,
		["getCursorPos"] = function(computer, data)
			return data.screen:getCursorPos()
		end,
		["setCursorPos"] = function(computer, data, x, y)
			assert(type(x) == "number")
			assert(type(y) == "number")
			data.screen:setCursorPos(x, y)
		end,
		["write"] = function(computer, data, text)
			text = tostring(text)
			data.screen:write(text)
		end,
		["setTextColor"] = function(computer, data, num)
			assert(type(num) == "number")
			assert(Util.COLOUR_CODE[num] ~= nil)
			data.screen:setTextColor( num )
		end,
		["setTextColour"] = function(computer, data, num)
			assert(type(num) == "number")
			assert(Util.COLOUR_CODE[num] ~= nil)
			data.screen:setTextColor( num )
		end,
		["setBackgroundColor"] = function(computer, data, num)
			assert(type(num) == "number")
			assert(Util.COLOUR_CODE[num] ~= nil)
			data.screen:setBackgroundColor( num )
		end,
		["setBackgroundColour"] = function(computer, data, num)
			assert(type(num) == "number")
			assert(Util.COLOUR_CODE[num] ~= nil)
			data.screen:setBackgroundColor( num )
		end,
		["isColor"] = function(computer, data)
			return data.screen.isColor
		end,
		["isColour"] = function(computer, data)
			return data.screen.isColor
		end,
		["setCursorBlink"] = function(computer, data, bool)
			assert(type(bool) == "boolean")
			data.screen:setCursorBlink( bool )
		end,
		["scroll"] = function(computer, data, n)
			assert(type(n) == "number")
			data.screen:scroll(n)
		end,
	}
}
