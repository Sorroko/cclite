Button = class('Button')

function Button:initialize(label, x, y, w, h, func, component) -- If button belongs to component then x, y, is relative
	self.label = label
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.component = component
	self.callback = func
	love.on("mousepressed", function ( ... )
		self:mousepressed( ... )
	end)
end

-- Love callbacks must account for relative x and y
function Button:mousepressed( x, y, _button )
	if _button ~= "l" then return end
	if not self.component then
		if x > self.x
			and x < self.x + self.w
			and y > self.y
			and y < self.y + self.h then
			self.callback()
		end
	else
		if x > self.x + self.component.x
			and x < self.x + self.component.x +  self.w
			and y + self.component.y > self.y
			and y < self.y + self.component.y + self.h then
			self.callback()
		end
	end
end

function Button:draw()
	--love.graphics.setColor()
	--love.graphics.rectangle("fill", self.x, self.y, self.w, self.h )
	love.graphics.setFont(self.component.font)
	love.graphics.setColor(255/255, 255/255, 255/255)
	love.graphics.print(self.label, self.x, self.y)
end
