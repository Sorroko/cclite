require 'ui.button'
require 'ui.component'
Panel = class('Panel', Component)

function Panel:initialize(x, y)
	Component.initialize(self, x, y)
	self.power = Button(10, 10, 40, 40, function()
		log("test")
	end, self)
end

function Panel:getWidth()
	return 200
end

function Panel:getHeight()
	return 200
end

function Panel:draw()
	self.power:draw()
end
