PeripheralManager = class('PeripheralManager')

PeripheralManager.loaded_peripherals = {}
function PeripheralManager.static.parse()
	-- Detect peripherals to load
	local items = love.filesystem.getDirectoryItems("/emulator/peripherals")
	for k, v in pairs(items) do
		local name = string.gsub(v, ".lua", "")
		log("Found peripheral: " .. name)

		local data = love.filesystem.read( "/emulator/peripherals/" .. v )
		local ok, fn = pcall(loadstring, "return " .. data)

		if ok then
			setfenv(fn, {})
			local tPeripheral = fn()
			if type(tPeripheral) == "table" then
				PeripheralManager.loaded_peripherals[tPeripheral.type] = tPeripheral
			end
		end
	end
end

local sides = {
	["top"] = true,
	["bottom"] = true,
	["left"] = true,
	["right"] = true,
	["front"] = true,
	["back"] = true
}
function PeripheralManager:initialize(computer)
	self.peripherals = {}
	self.computer = computer
end

function PeripheralManager:setSide(side, peripheralType)
	if not sides[side] then return end
	if peripheralType == nil then
		self.peripherals[side] = nil
	else
		if PeripheralManager.loaded_peripherals[peripheralType] == nil then return end
		self.peripherals[side] = {
			["type"] = peripheralType,
			["data"] = {}
		} -- Clone peripheral table and set to side
	end
end

function PeripheralManager:isPresent(side)
	return self.peripherals[side] ~= nil
end

function PeripheralManager:getType(side)
	if self.peripherals[side] == nil then return end

	return self.peripherals[side]["type"]
end

function PeripheralManager:getMethods(side)
	if self.peripherals[side] == nil then return end

	local methods = {}
	for k,v in pairs(PeripheralManager.loaded_peripherals[ self.peripherals[side]["type"] ]["methods"]) do
		table.insert(methods, k)
	end
	return methods
end

function PeripheralManager:call(side, method, ...)
	if self.peripherals[side] == nil then return end
	if PeripheralManager.loaded_peripherals[ self.peripherals[side]["type"] ]["methods"][method] == nil then return end

	return PeripheralManager.loaded_peripherals[ self.peripherals[side]["type"] ]["methods"][method](self.computer, self.peripherals[side]["data"], ...)
end
