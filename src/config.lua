Config = class('Config')

function Config:initialize(path)
	self.path = path
	self.default = {}
	self.data = {}
end

function Config:setDefault( key, value )
	self.default[key] = value
	if not self.data[key] then self.data[key] = value end
end

function Config:resetToDefault()
	for k, v in pairs(self.default) do
		self.data[k] = v
	end
end

function Config:load()
	if love.filesystem.exists(self.path) then
		for line in love.filesystem.lines(self.path) do
			key, value = string.match(line,"(.-)=(.-)$")
			if key and value then
				self.data[key] = value -- Will overide defaults
			end
		end
	end

	self:save() -- Save defaults that weren't loaded
end

function Config:save()
	local lines, saved_keys = {}, {}

	if love.filesystem.exists(self.path) then
		for line in love.filesystem.lines(self.path) do
			key, value = string.match(line,"(.-)=(.-)$")
			if self.data[key] then
				saved_keys[key] = true
				lines[#lines + 1] = key .. "=" .. tostring(self.data[key])
			else
				lines[#lines + 1] = line -- Preseve comments and empty lines
			end
		end
	end

	for key, value in pairs(self.data) do -- Add extra configs that weren't in the file already
		if not saved_keys[key] then
			saved_keys[key] = true
			lines[#lines + 1] = key .. "=" .. tostring(value)
		end
	end

	love.filesystem.write(self.path, table.concat(lines, "\n"))
end

function Config:set(key, value)
	self.data[key] = value
end

function Config:get(key)
	return self.data[key]
end

local function toboolean(v)
    return (type(v) == "string" and v == "true") or (type(v) == "number" and v ~= 0) or (type(v) == "boolean" and v)
end

-- There is another default setting in case the key is set to false. Useful when the function must return something
function Config:getBoolean(key, default)
	local val = toboolean(self.data[key])
	return val ~= nil and val or default
end

function Config:getString(key, default)
	local val = tostring(self.data[key])
	return val ~= nil and val or default
end

function Config:getNumber(key, default)
	local val = tonumber(self.data[key])
	return val ~= nil and val or default
end
