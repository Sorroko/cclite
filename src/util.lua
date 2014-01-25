Util = class('Util')

Util.static.KEYS = {
	["q"] = 16, ["w"] = 17, ["e"] = 18, ["r"] = 19,
	["t"] = 20, ["y"] = 21, ["u"] = 22, ["i"] = 23,
	["o"] = 24, ["p"] = 25, ["a"] = 30, ["s"] = 31,
	["d"] = 32, ["f"] = 33, ["g"] = 34, ["h"] = 35,
	["j"] = 36, ["k"] = 37, ["l"] = 38, ["z"] = 44,
	["x"] = 45, ["c"] = 46, ["v"] = 47, ["b"] = 48,
	["n"] = 49, ["m"] = 50,
	["1"] = 2, ["2"] = 3, ["3"] = 4, ["4"] = 5, ["5"] = 6,
	["6"] = 7, ["7"] = 8, ["8"] = 9, ["9"] = 10, ["0"] = 11,
	[" "] = 57,

	["'"] = 40, [","] = 51, ["-"] = 12, ["."] = 52, ["/"] = 53,
	[":"] = 146, [";"] = 39, ["="] = 13, ["@"] = 145, ["["] = 26,
	["\\"] = 43, ["]"] = 27, ["^"] = 144, ["_"] = 147, ["`"] = 41,

	["up"] = 200,
	["down"] = 208,
	["right"] = 205,
	["left"] = 203,
	["home"] = 199,
	["end"] = 207,
	["pageup"] = 201,
	["pagedown"] = 209,
	["insert"] = 210,
	["backspace"] = 14,
	["tab"] = 15,
	["return"] = 28,
	["delete"] = 211,

	["rshift"] = 54,
	["lshift"] = 42,
	["rctrl"] = 157,
	["lctrl"] = 29,
	["ralt"] = 184,
	["lalt"] = 56,
}

Util.static.COLOUR_RGB = {
	WHITE = {255, 255, 255}, --Colors from GravityScore. Updated by awsmazinggenius.
	ORANGE = {235, 136, 68},
	MAGENTA = {195, 84, 205},
	LIGHT_BLUE = {102, 137, 211},
	YELLOW = {222, 222, 108},
	LIME = {65, 205, 52},
	PINK = {216, 129, 152},
	GRAY = {67, 67, 67},
	LIGHT_GRAY = {153, 153, 153},
	CYAN = {40, 118, 151},
	PURPLE = {123, 47, 190},
	BLUE = {37, 49, 146},
	BROWN = {81, 48, 26},
	GREEN = {59, 81, 26},
	RED = {179, 49, 44},
	BLACK = {0, 0, 0},
}

Util.static.COLOUR_CODE = {
	[1] = Util.COLOUR_RGB.WHITE,
	[2] = Util.COLOUR_RGB.ORANGE,
	[4] =  Util.COLOUR_RGB.MAGENTA,
	[8] = Util.COLOUR_RGB.LIGHT_BLUE,
	[16] = Util.COLOUR_RGB.YELLOW,
	[32] = Util.COLOUR_RGB.LIME,
	[64] = Util.COLOUR_RGB.PINK,
	[128] = Util.COLOUR_RGB.GRAY,
	[256] = Util.COLOUR_RGB.LIGHT_GRAY,
	[512] = Util.COLOUR_RGB.CYAN,
	[1024] = Util.COLOUR_RGB.PURPLE,
	[2048] = Util.COLOUR_RGB.BLUE,
	[4096] = Util.COLOUR_RGB.BROWN,
	[8192] = Util.COLOUR_RGB.GREEN,
	[16384] = Util.COLOUR_RGB.RED,
	[32768] = Util.COLOUR_RGB.BLACK,
}

-- Better key down check
Util.static.isKeyDown = function(key)
	if key == "ctrl" then
		return Util.isKeyDown("lctrl") or Util.isKeyDown("rctrl")
	else
		return love.keyboard.isDown(key)
	end
end

Util.static.lines = function(str)
	local t = {}
	local function helper(line) table.insert(t, line) return "" end
	helper((str:gsub("(.-)\r?\n", helper)))
	return t
end

-- TODO: Maybe replace with non-recursive
Util.static.deep_copy = function(orig) -- Simple table deep copy.
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Util.deep_copy(orig_key)] = Util.deep_copy(orig_value)
        end
        setmetatable(copy, Util.deep_copy( getmetatable(orig) ) )
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

