Component = class('Component')

function Component:initialize( x, y )
	self.x = x
	self.y = y
	Window.main:addComponent(self)
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
