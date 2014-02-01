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
function Screen:initialize(isColor)
	self.isColor = isColor or false
	self:reset()
end

function Screen:reset()
	self._showCursor = false
	self._lastCursor = nil

	self.textB = {}
	self.backgroundColourB = {}
	self.textColourB = {}
	local x,y
	for y = 1, Screen.height do
		self.textB[y] = {}
		self.backgroundColourB[y] = {}
		self.textColourB[y] = {}
		for x = 1, Screen.width do
			self.textB[y][x] = " "
			self.backgroundColourB[y][x] = 32768
			self.textColourB[y][x] = 1
		end
	end

	self.bg = 32768
	self.fg = 1
	self.cursorY = 1
	self.cursorX = 1
	self.cursorBlink = false
end

function Screen:clear()
	for y = 1, Screen.height do
		for x = 1, Screen.width do
			self.textB[y][x] = " "
			if self.isColor then
				self.backgroundColourB[y][x] = self.bg
				self.textColourB[y][x] = 1 -- Don't need to bother setting text color
			end
		end
	end
end

function Screen:clearLine()
	if self.cursorY > Screen.height
			or self.cursorY < 1 then return end
	for x = 1, Screen.width do
		self.textB[self.cursorY][x] = " "
		if self.isColor then
			self.backgroundColourB[self.cursorY][x] = self.bg
			self.textColourB[self.cursorY][x] = 1 -- Don't need to bother setting text color
		end
	end
end

function Screen:getSize() return Screen.width, Screen.height end
function Screen:getCursorPos() return self.cursorX, self.cursorY end

function Screen:setCursorPos(x, y)
	self.cursorX = math.floor(x)
	self.cursorY = math.floor(y)
end

function Screen:write( text )
	if self.cursorY > Screen.height
		or self.cursorY < 1 then
		self.cursorX = self.cursorX + #text
		return
	end

	for i = 1, #text do
		local char = string.sub( text, i, i )
		if self.cursorX + i - 1 <= Screen.width
			and self.cursorX + i - 1 >= 1 then
			self.textB[self.cursorY][self.cursorX + i - 1] = char
			if self.isColor then
				self.textColourB[self.cursorY][self.cursorX + i - 1] = self.fg
				self.backgroundColourB[self.cursorY][self.cursorX + i - 1] = self.bg
			end
		end
	end
	self.cursorX = self.cursorX + #text
end

function Screen:setTextColor( num ) self.fg = num end
function Screen:setBackgroundColor( num ) self.bg = num end
function Screen:setCursorBlink( bool ) self.cursorBlink = bool end

function Screen:scroll(n)
	local textBuffer = {}
	local backgroundColourBuffer = {}
	local textColourBuffer = {}
	for y = 1, Screen.height do
		if y - n > 0 and y - n <= Screen.height then
			textBuffer[y - n] = {}
			if self.isColor then
				backgroundColourBuffer[y - n] = {}
				textColourBuffer[y - n] = {}
			end
			for x = 1, Screen.width do
				textBuffer[y - n][x] = self.textB[y][x]
				if self.isColor then
					backgroundColourBuffer[y - n][x] = self.backgroundColourB[y][x]
					textColourBuffer[y - n][x] = self.textColourB[y][x]
				end
			end
		end
	end
	for y = 1, Screen.height do
		if textBuffer[y] ~= nil then
			for x = 1, Screen.width do
				self.textB[y][x] = textBuffer[y][x]
				if self.isColor then
					self.backgroundColourB[y][x] = backgroundColourBuffer[y][x]
					self.textColourB[y][x] = textColourBuffer[y][x]
				end
			end
		else
			for x = 1, Screen.width do
				self.textB[y][x] = " "
				if self.isColor then
					self.backgroundColourB[y][x] = self.bg
					self.textColourB[y][x] = 1 -- Don't need to bother setting text color
				end
			end
		end
	end
end

function Screen:draw()
	local now = love.timer.getTime()

	-- term api draws directly to buffer
	if self.isColor then
		for y = 0, Screen.height - 1 do
			for x = 0, Screen.width - 1 do
				setColor( Util.COLOUR_CODE[ self.backgroundColourB[y + 1][x + 1] ] )
				ldrawRect("fill", x * Screen.pixelWidth, y * Screen.pixelHeight, Screen.pixelWidth, Screen.pixelHeight )
			end
		end
	end

	-- Two seperate for loops to not setColor all the time and allow batch gl calls.
	local text, byte, offset
	for y = 0, Screen.height - 1 do
		for x = 0, Screen.width - 1 do
			text = self.textB[y + 1][x + 1]
			byte = string.byte(text)
			if byte == 9 then
				text = " "
			elseif byte < 32 or byte > 127 then
				text = "?"
			end
			if self.isColor then
				setColor( Util.COLOUR_CODE[ self.textColourB[y + 1][x + 1] ] )
			end
			if Screen.tCharOffset[text] then -- Just incase
				lprint( text, (x * Screen.pixelWidth) + Screen.tCharOffset[text], (y * Screen.pixelHeight) + Screen.textOffset)
			end
		end
	end

	if self.cursorBlink then
		if not self._lastCursor then
			self._lastCursor = now
		end
		if now - self._lastCursor > 0.5 then
			self._showCursor = not self._showCursor
			self._lastCursor = now
		end

		if self._showCursor then
			if self.isColor then
				setColor(Util.COLOUR_CODE[ self.fg ])
			end
			lprint("_", ((self.cursorX - 1) * Screen.pixelWidth) + Screen.tCharOffset["_"], (self.cursorY - 1) * Screen.pixelHeight + Screen.textOffset)
		end
	end
end
