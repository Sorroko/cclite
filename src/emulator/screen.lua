Screen = class('Screen')

-- Constants
Screen.static.width = 51
Screen.static.height = 19
Screen.static.pixelWidth = 12--6 * 2
Screen.static.pixelHeight = 18--9 * 2
Screen.static.textOffset = 3 -- Small correction for font, align the bottom of font with bottom of pixel.
Screen.font = nil
Screen.tCharOffset = {}

-- Internal helpers
local lsetCol = love.graphics.setColor
local ldrawRect = love.graphics.rectangle
local ldrawLine = love.graphics.line
local lprint = love.graphics.print
local lastColor
local function setColor(c)
	if lastColor ~= c then
		lastColor = c
		lsetCol(c)
	end
	return self
end

function Screen.static.setFont(font)
	Screen.font = font
	love.graphics.setFont(Screen.font)
	Screen.tCharOffset = {}
	local char
	for i = 32,127 do -- TODO: Make it 170 possibly? Find a beter, complete font.
		char = string.char(i)
		Screen.tCharOffset[char] = math.floor(Screen.pixelWidth / 2 - Screen.font:getWidth(char) / 2) -- Center all chars
	end
end

-- Screen instance init
function Screen:initialize(_computer)
	self.computer = _computer
	self.showCursor = false
	self.lastCursor = nil
end

function Screen:draw()
	local now = love.timer.getTime()

	if not self.computer.running then
		local text = "Press any key..."
		lprint(text, ((Screen.width * Screen.pixelWidth) / 2) - (Screen.font:getWidth(text) / 2), (Screen.height * Screen.pixelHeight) / 2)
		return
	end

	-- term api draws directly to buffer
	if self.computer.isAdvanced then
		for y = 0, Screen.height - 1 do
			for x = 0, Screen.width - 1 do
				setColor( Util.COLOUR_CODE[ self.computer.backgroundColourB[y + 1][x + 1] ] )
				ldrawRect("fill", x * Screen.pixelWidth, y * Screen.pixelHeight, Screen.pixelWidth, Screen.pixelHeight )
			end
		end
	end

	-- Two seperate for loops to not setColor all the time and allow batch gl calls.
	local text, byte, offset
	for y = 0, Screen.height - 1 do
		for x = 0, Screen.width - 1 do
			text = self.computer.textB[y + 1][x + 1]
			byte = string.byte(text)
			if byte == 9 then
				text = " "
			elseif byte < 32 or byte > 127 then
				text = "?"
			end
			if self.computer.isAdvanced then
				setColor( Util.COLOUR_CODE[ self.computer.textColourB[y + 1][x + 1] ] )
			end
			if Screen.tCharOffset[text] then -- Just incase
				lprint( text, (x * Screen.pixelWidth) + Screen.tCharOffset[text], (y * Screen.pixelHeight) + Screen.textOffset)
			end
		end
	end

	if self.computer.api.data.term.blink then
		if not self.lastCursor then
			self.lastCursor = now
		end
		if now - self.lastCursor > 0.5 then
			self.showCursor = not self.showCursor
			self.lastCursor = now
		end

		if self.showCursor then
			if self.computer.isAdvanced then
				setColor(Util.COLOUR_CODE[ self.computer.api.data.term.fg ])
			end
			lprint("_", ((self.computer.api.data.term.cursorX - 1) * Screen.pixelWidth) + Screen.tCharOffset["_"], (self.computer.api.data.term.cursorY - 1) * Screen.pixelHeight + Screen.textOffset)
		end
	end
end
