function testPointInQuad(x, y, qx, qy, qw, qh)
	if x >= qx and x < qx + qw and y >= qy and y < qy + qh then
		return true
	end

	-- else
	return false
end

UIElement = {}
UIElement.__index = UIElement

function UIElement.new(x, y, image, overImage, activeImage, target, callback)
	local self = setmetatable({}, UIElement)

	self.active = false -- normal
	self.over = false

	self.x = x
	self.y = y

	local w, h = image:getDimensions()
	self.width = w
	self.height = h

	self.image = image
	self.overImage = overImage
	self.activeImage = activeImage

	self.target = target
	self.callback = callback

	self.currentImage = self.image

	return self
end

function UIElement:draw()
	local img = self.image

	if self.active then
		img = self.activeImage
	end

	if self.over and self.overImage then
		img = self.overImage
	end

	love.graphics.draw(img, self.x, self.y)
end

function UIElement:mousemoved(x, y, dx, dy)
	self.over = testPointInQuad(x, y, self.x, self.y, self.width, self.height)
end

function UIElement:mousepressed(x, y, button)
	if testPointInQuad(x, y, self.x, self.y, self.width, self.height) and button == "l" then
		if self.target ~= nil and self.callback ~= nil then
			self.callback(self.target, self)
		end
	end
end

setmetatable(UIElement, { __call = function(_, ...) return UIElement.new(...) end })

State = {}
State.__index = State

function State.new()
	local self = setmetatable({elements = {}}, State)
	return self
end

function State:load()
	self.elements = {}
end

function State:unload()
end

function State:update(dt)
end

function State:draw()
	-- draw background
	if self.backgroundImage ~= nil then
		love.graphics.draw(self.backgroundImage, 0, 0)
	end

	-- draw ui elements
	for i, v in ipairs(self.elements) do
		v:draw()
	end
end

function State:mousemoved(x, y, dx, dy)
	for i, v in ipairs(self.elements) do
		v:mousemoved(x, y, dx, dy)
	end
end

function State:mousepressed(x, y, button)
	for i, v in ipairs(self.elements) do
		v:mousepressed(x, y, button)
	end
end

function State:keypressed(key)
end
setmetatable(State, { __call = function(_, ...) return State.new(...) end })