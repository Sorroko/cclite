require 'ui.component'
Android = class('Android', Component)

function Android:initialize(window, x, y, width, height)
	self.width = width
	self.height = height

	Component.initialize(self, window, x, y)
end

function Android:getWidth()
	return self.width
end

function Android:getHeight()
	return self.height
end

function Android:draw()
	love.graphics.setColor(172, 232, 250)
	love.graphics.rectangle("fill", 0, 0, self:getWidth(), self:getHeight() )
end

AndroidMenu = class('AndroidMenu', Component)

function AndroidMenu:initialize(window, x, y, width)
	self.width = width
	self.height = 72

	Component.initialize(self, window, x, y)

	self.power = Button("Power Off", 10, 20, 40, 40, function()
		self:onPower()
	end, self)
end

function AndroidMenu:postInitialize()
	self.font = love.graphics.newFont( 'res/minecraft.ttf', 48 )

	self.power.w = self.font:getWidth(self.power.label)
end

function AndroidMenu:onPower() end

function AndroidMenu:getWidth()
	return self.width
end

function AndroidMenu:getHeight()
	return self.height
end

function AndroidMenu:draw()
	love.graphics.setColor(63, 81, 181)
	love.graphics.rectangle("fill", 0, 0, self:getWidth(), self:getHeight() )

	self.power:draw()
end
