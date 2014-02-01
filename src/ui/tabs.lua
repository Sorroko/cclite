require 'ui.component'
Tabs = class('Tabs', Component)

function Tabs:initialize(x, y)
	Component.initialize(self, x, y)
	self.width = 0
	self.height = 0
	self.selectedTab = nil
	self.tabs = {}
end

function Tabs:getWidth()
	return self.width
end

function Tabs:getHeight()
	return self.height
end

function Tabs:addTab(tTab)
	table.insert(self.tabs, tTab)
end

function Tabs:draw()
	-- Draw tab bar

	if self.selectedTab then
		self.tabs[self.selectedTab].draw()
	end
end
