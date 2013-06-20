COLOUR_RGB = {
	WHITE = {255, 255, 255},
	ORANGE = {230, 125, 50},
	MAGENTA = {230, 50, 145},
	LIGHT_BLUE = {16, 106, 232},
	YELLOW = {240, 230, 50},
	LIME = {50, 240, 50},
	PINK = {230, 50, 225},
	GRAY = {90, 90, 90},
	LIGHT_GRAY = {150, 150, 150},
	CYAN = {50, 230, 230},
	PURPLE = {130, 50, 230},
	BLUE = {50, 60, 230},
	BROWN = {150, 85, 75},
	GREEN = {60, 220, 40},
	RED = {230, 20, 20},
	BLACK = {0, 0, 0},
}
COLOUR_CODE = {
	[1] = COLOUR_RGB.WHITE,
	[2] = COLOUR_RGB.ORANGE,
	[4] =  COLOUR_RGB.MAGENTA,
	[8] = COLOUR_RGB.LIGHT_BLUE,
	[16] = COLOUR_RGB.YELLOW,
	[32] = COLOUR_RGB.LIME,
	[64] = COLOUR_RGB.PINK,
	[128] = COLOUR_RGB.GRAY,
	[256] = COLOUR_RGB.LIGHT_GRAY,
	[512] = COLOUR_RGB.CYAN,
	[1024] = COLOUR_RGB.PURPLE,
	[2048] = COLOUR_RGB.BLUE,
	[4096] = COLOUR_RGB.BROWN,
	[8192] = COLOUR_RGB.GREEN,
	[16384] = COLOUR_RGB.RED,
	[32768] = COLOUR_RGB.BLACK,
}

Screen = {
	width = 51,
	height = 19,
	textB = {},
	backgroundColourB = {},
	textColourB = {},
	font = nil,
	pixelWidth = 6 * 2,
	pixelHeight = 9 * 2,
	showCursor = false,
	textOffset = 3, -- Small correction for font, align the bottom of font with bottom of pixel.
	showCursor = false,
	lastCursor = nil,
}
function Screen:init()
	for y = 1, self.height do
		self.textB[y] = {}
		self.backgroundColourB[y] = {}
		self.textColourB[y] = {}
		for x = 1, self.width do
			self.textB[y][x] = " "
			self.backgroundColourB[y][x] = 32768
			self.textColourB[y][x] = 1
		end
	end

	self.font = love.graphics.getFont()
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

	if not Emulator.running then 
		local text = "Press any key..."
		lprint(text, ((self.width * self.pixelWidth) / 2) - (font:getWidth(text) / 2), (self.height * self.pixelHeight) / 2)
		return 
	end

	-- TODO Better damn rendering!
	-- term api draws directly to buffer
	-- i.e. each pixel is updated independantly on a canvas
	-- copy the canvas to main canvas only when dirty/changed (blinking cursor)

	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do

			setColor( COLOUR_CODE[ self.backgroundColourB[y + 1][x + 1] ] ) -- TODO COLOUR_CODE lookup might be too slow?
			ldrawRect("fill", x * self.pixelWidth, y * self.pixelHeight, self.pixelWidth, self.pixelHeight )
			
		end
	end
	-- Two seperate for loops to not setColor all the time and allow batch gl calls.
	-- Is this actually a performance improvement?
	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			local text = self.textB[y + 1][x + 1]
			local offset = self.pixelWidth / 2 - self.font:getWidth(text) / 2 -- Could also create a lookup table of widths on load
			setColor( COLOUR_CODE[ self.textColourB[y + 1][x + 1] ] )
			lprint( text, (x * self.pixelWidth) + offset, (y * self.pixelHeight) + self.textOffset)
		
		end
	end

	if api.term.blink and self.showCursor then
		local px = (api.term.cursorX - 1) * self.pixelWidth
		local py = (api.term.cursorY * self.pixelHeight) - 1
		setColor(COLOUR_CODE[ api.term.fg ])
		ldrawLine(px, py, px + self.pixelWidth, py)
	end
end