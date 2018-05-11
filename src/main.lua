require "State"
require "gameState"

canvasResolution = {w = 1280, h = 720}
screenScale = 1
fullscreen = false
azerty = true

titleState = State()
function titleState:load()
	State.load(self)

	self.backgroundImage = love.graphics.newImage("titleBackground.png")

	self.startButton = UIElement(213, 135, love.graphics.newImage("startOff.png"), love.graphics.newImage("startOn.png"), nil, self, self.startCallback)
	self.optionsButton = UIElement(48, 135, love.graphics.newImage("optionButtonOff.png"), love.graphics.newImage("optionButtonOn.png"), nil, self, self.optionsCallback)

	table.insert(self.elements, self.startButton)
	table.insert(self.elements, self.optionsButton)
end

function titleState:startCallback(sender)
	changeState(introState)
end

function titleState:optionsCallback(sender)
	pushState(optionState)
end

function titleState:keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end

optionState = State()
function optionState:load()
	State.load(self)

	self.backgroundImage = love.graphics.newImage("optionsBackground.png")

	self.fullscreenCheck = UIElement(160, 61, love.graphics.newImage("checkOff.png"), nil, love.graphics.newImage("checkOn.png"), self, self.fullscreenCallback)
	self.azertyCheck = UIElement(160, 40, love.graphics.newImage("checkOff.png"), nil, love.graphics.newImage("checkOn.png"), self, self.azertyCallback)
	self.azertyCheck.active = azerty

	self.plusButton = UIElement(238, 82, love.graphics.newImage("plusButtonOff.png"), nil, love.graphics.newImage("plusButtonOn.png"), self, self.resolutionCallback)
	self.minusButton = UIElement(160, 82, love.graphics.newImage("minusButtonOff.png"), nil, love.graphics.newImage("plusButtonOff.png"), self, self.resolutionCallback)

	table.insert(self.elements, self.fullscreenCheck)
	table.insert(self.elements, self.azertyCheck)
	table.insert(self.elements, self.plusButton)
	table.insert(self.elements, self.minusButton)
end

function optionState:fullscreenCallback(sender)
	self.fullscreenCheck.active = not self.fullscreenCheck.active
end

function optionState:azertyCallback(sender)
	self.azertyCheck.active = not self.azertyCheck.active

	azerty = self.azertyCheck.active
end

function optionState:resolutionCallback(sender)
end

function optionState:keypressed(key)
	if key == "escape" then
		popState()
	end
end

introState = State()
function introState:load()
	State.load(self)

	self.backgroundImage = love.graphics.newImage("intro.png")
end

function introState:mousemoved(x, y, dx, dy)

end

function introState:mousepressed(x, y, button)
	if button == "l" then
		changeState(gameState)
	end
end


gameoverState = State()
function gameoverState:load()
	State.load(self)

	self.backgroundImage = love.graphics.newImage("gameover.png")
end

function gameoverState:mousepressed(x, y, button)
	State.mousepressed(self, x, y, button)

	if button == "l" then
		changeState(titleState)
	end
end

endState = State()
function endState:load()
	State.load(self)
	
	self.backgroundImage = love.graphics.newImage("endscreen.png")
end


function endState:mousepressed(x, y, button)
	State.mousepressed(self, x, y, button)
	if button == "l" then
		changeState(titleState)
	end
end


-- Love callback
local mainCanvas
states = {}

canvasformats = love.graphics.getCanvasFormats()
function setupScreen() 
	love.window.setMode(canvasResolution.w * screenScale, canvasResolution.h * screenScale, {fullscreen=fullscreen})

	local formats = love.graphics.getCanvasFormats()
	if formats.normal then
		mainCanvas = love.graphics.newCanvas(canvasResolution.w, canvasResolution.h)
		mainCanvas:setFilter("nearest", "nearest")
	end
end

function changeState(newState)
	if #states > 0 then
		states[#states]:unload()
	end

	table.remove(states)
	table.insert(states, newState)
	states[#states]:load()
end

function pushState(newState)
	table.insert(states, newState)
	states[#states]:load()	
end

function popState()
	if #states > 0 then
		states[#states]:unload()
	end

	table.remove(states)	
end

function love.load()
	setupScreen()

	love.audio.setDistanceModel("exponent")

	changeState(gameState)
end

function love.update(dt)
	states[#states]:update(dt)
end

function love.draw()
	-- if we have a canvas
	if mainCanvas ~= nil then
		love.graphics.setCanvas(mainCanvas)
		love.graphics.clear()

    	states[#states]:draw()

		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setCanvas()
		love.graphics.draw(mainCanvas, 0, 0, 0, screenScale, screenScale)
	else
		-- else print an error
	    local y = 0
    	for formatname, formatsupported in pairs(canvasformats) do
        	local str = string.format("Supports format '%s': %s", formatname, tostring(formatsupported))
        	love.graphics.print(str, 10, y)
        	y = y + 20
    	end
	end
end

function love.mousemoved(x, y, dx, dy)
	states[#states]:mousemoved(x / screenScale, y / screenScale, dx, dy)
end

function love.mousepressed( x, y, button )
	states[#states]:mousepressed(x / screenScale, y / screenScale, button)
end

function love.keypressed(key)
	-- key translation!
	local tkey = key
	if azerty then 
		if tkey == "a" then tkey = "q" end
		if tkey == "z" then tkey = "w" end
		if tkey == "q" then tkey = "a" end
		if tkey == "w" then tkey = "z" end
	end

	states[#states]:keypressed(tkey)
end