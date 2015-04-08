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
end

function AndroidMenu:postInitialize()
	self.font = love.graphics.newFont( 'res/minecraft.ttf', 48 )

	self.power = Button("Power Off", 10, 20, self.font:getWidth("Power Off"), 48, function()
		self:onPower()
	end, self)

	local ctrl_state = false
	self.ctrl = Button("CTRL", 340, 20, self.font:getWidth("CTRL"), 46, function()
		ctrl_state = not ctrl_state
		self:onControl(ctrl_state)
	end, self)
	self.ctrl.draw = function(self)
		love.graphics.setFont(self.component.font)
		if ctrl_state then
			love.graphics.setColor(255, 0, 0)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h )
		end
		love.graphics.setColor(255, 255, 255)
		love.graphics.print(self.label, self.x, self.y)
	end

	local shift_state = false
	self.shift = Button("SHIFT", 510, 20, self.font:getWidth("SHIFT"), 46, function()
		shift_state = not shift_state
		self:onShift(shift_state)
	end, self)
	self.shift.draw = function(self)
		love.graphics.setFont(self.component.font)
		if shift_state then
			love.graphics.setColor(255, 0, 0)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h )
		end
		love.graphics.setColor(255, 255, 255)
		love.graphics.print(self.label, self.x, self.y)
	end
end

function AndroidMenu:onPower() end
function AndroidMenu:onControl() end
function AndroidMenu:onShift() end

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
	self.ctrl:draw()
	self.shift:draw()
end
