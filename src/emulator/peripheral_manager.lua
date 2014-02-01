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

		if ok and fn ~= nil then
			setfenv(fn, _G) -- TODO: Possible sandbox, however not needed currently
			local tPeripheral = fn()
			if type(tPeripheral) == "table" then
				PeripheralManager.loaded_peripherals[tPeripheral.type] = tPeripheral
			end
			log("Loaded peripheral: " .. name)
		else
			-- TODO: Print the actual error in peripheral file
			log("Failed to load peripheral: " .. name, "ERROR")
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
		table.insert(self.computer.eventQueue, {"peripheral_detach", side})
	else
		if PeripheralManager.loaded_peripherals[peripheralType] == nil then return end
		local data = {}
		if PeripheralManager.loaded_peripherals[peripheralType]["initialize"] then
			PeripheralManager.loaded_peripherals[peripheralType]["initialize"](self.computer, data)
		end
		self.peripherals[side] = {
			["type"] = peripheralType,
			["data"] = data
		}
		table.insert(self.computer.eventQueue, {"peripheral", side})
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
