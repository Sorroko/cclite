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
	if not love.filesystem.exists(self.path) then
		self:save() -- Will save the defaults
	end

	for line in love.filesystem.lines(self.path) do
		key, value = string.match(line,"(.-)=(.-)$")
		if key and value then
			self.data[key] = value -- Will overide default
		end
	end
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