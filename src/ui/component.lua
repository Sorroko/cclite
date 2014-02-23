Component = class('Component')

function Component:initialize( window, x, y )
	self.x = x
	self.y = y
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
