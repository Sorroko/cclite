Window = class('Window')

Window.main = nil

function Window:initialize(title) --(title, w, h)
	self.title = title
	self.w = 0 --w or 720
	self.h = 0 --h or 480
	self.components = {}
	self.isCreated = false
end

function Window:addComponent(component)
	table.insert(self.components, component)
	local changed = false

	if component.x + component:getWidth() > self.w then
		self.w = component.x + component:getWidth()
		changed = true
	end
	if component.y + component:getHeight() > self.h then
		self.h = component.y + component:getHeight()
		changed = true
	end
	if changed and self.isCreated then self:create() end -- Resize
end

function Window:draw()
	for k, v in pairs(self.components) do
		if v.x ~= 0 or v.y ~= 0 then
			love.graphics.push()
			love.graphics.translate(v.x, v.y)
			v:draw()
			love.graphics.pop()
		else
			v:draw()
		end
	end
end

function Window:create()
	self.isCreated = true
	local ok = love.window.setMode( self.w, self.h, {
		fullscreen = false,
		vsync = true,
		msaa = 0,
		resizable = true,
		borderless = false,
		minwidth = 200,
		minheight = 200
	} )
	if not ok then return false end

	love.window.setTitle( self.title )
	return true
end
