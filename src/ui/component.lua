Component = class('Component')

function Component:initialize( window, x, y )
	self.x = self.x or x
	self.y = self.y or y
	window:addComponent(self)
end

function Component:getWidth()
	-- Stub
end

function Component:getHeight()
	-- Stub
end

function Component:draw()
	-- Stub
end
