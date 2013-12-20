Screen = class('Screen')

Screen.static.width = 51
Screen.static.height = 19
Screen.static.pixelWidth = 12--6 * 2
Screen.static.pixelHeight = 18--9 * 2
Screen.static.textOffset = 3 -- Small correction for font, align the bottom of font with bottom of pixel.

function Screen:initialize(_computer)
	self.computer = _computer
	self.showCursor = false
	self.lastCursor = nil
end

-- Local functions are faster than global
-- Source: https://love2d.org/forums/viewtopic.php?f=3&t=3500
-- Unconfirmed, saw a drop from 12% to 10% cpu usage, too small a diff to confirm.
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

function Screen:draw()
	if not self.font then self.font = love.graphics.getFont() end -- TODO: This needs a nicer solution
	local now = love.timer.getTime()

	if not self.computer.running then
		local text = "Press any key..."
		lprint(text, ((Screen.width * Screen.pixelWidth) / 2) - (self.font:getWidth(text) / 2), (Screen.height * Screen.pixelHeight) / 2)
		return
	end

	-- TODO Better damn rendering!
	-- term api draws directly to buffer
	-- i.e. each pixel is updated independantly on a canvas
	-- copy the canvas to main canvas only when dirty/changed (blinking cursor)

	for y = 0, Screen.height - 1 do
		for x = 0, Screen.width - 1 do
			setColor( Util.COLOUR_CODE[ self.computer.backgroundColourB[y + 1][x + 1] ] ) -- TODO COLOUR_CODE lookup might be too slow? Possibly keep color in pixel?
			ldrawRect("fill", x * Screen.pixelWidth, y * Screen.pixelHeight, Screen.pixelWidth, Screen.pixelHeight )
		end
	end

	-- Two seperate for loops to not setColor all the time and allow batch gl calls.
	-- Is this actually a performance improvement?
	local text, byte, offset
	for y = 0, Screen.height - 1 do
		for x = 0, Screen.width - 1 do
			text = self.computer.textB[y + 1][x + 1]
			byte = string.byte(text)
			if byte == 9 then
				text = " "
			elseif byte < 32 or byte > 126 or byte == 96 then
				text = "?"
			end
			offset = Screen.pixelWidth / 2 - self.font:getWidth(text) / 2 -- Could also create a lookup table of widths on load (done in gamax92s fork)
			setColor( Util.COLOUR_CODE[ self.computer.textColourB[y + 1][x + 1] ] )
			lprint( text, (x * Screen.pixelWidth) + offset, (y * Screen.pixelHeight) + Screen.textOffset)

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
			local offset = Screen.pixelWidth / 2 - self.font:getWidth("_") / 2
			setColor(Util.COLOUR_CODE[ self.computer.api.data.term.fg ])
			lprint("_", (self.computer.api.data.term.cursorX - 1) * Screen.pixelWidth + offset, (self.computer.api.data.term.cursorY - 1) * Screen.pixelHeight + Screen.textOffset)
		end
	end
end
