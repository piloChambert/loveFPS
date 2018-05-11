StaticSound = {}
StaticSound.__index = StaticSound
function StaticSound.new(filename, x, y, z, ref, max)
	local self = setmetatable({}, StaticSound)

	self.position = {x = x, y = y, z = z}
	self.source = love.audio.newSource(filename, "static")
	self.source:setPosition(x, y, z)
	self.source:setAttenuationDistances(ref, max)
	self.source:setLooping(true)
	self.source:play()

	return self
end

setmetatable(StaticSound, { __call = function(_, ...) return StaticSound.new(...) end })

monsterAppearTime = 5
monsterAttackTime = 5
monsterMinIdle = 20
monsterMaxIdle = 45

Monster = {}
Monster.__index = Monster
function Monster.new()
	local self = setmetatable({}, Monster)

	self.timer = 0
	self.sound = love.audio.newSource("monster.wav", "static")
	self.sound:setAttenuationDistances(3, 0)

	self.attackSound = love.audio.newSource("attack.wav", "static")
	self.attackSound:setAttenuationDistances(3, 0)


	self.state = 0 -- hidden state
	self.hiddentTime = love.math.random(monsterMinIdle, monsterMaxIdle) -- generate a new wait time
	self.position = {x = 0, y = 0, z = 0}

	return self
end

function Monster:update(dt, gameState)
	self.timer = self.timer + dt

	if self.state == 0 then
		if self.timer > self.hiddentTime then
			--print("monster appear")
			self.state = 1 --appear state
			self.timer = 0

			-- next to the player!
			self.position.x = gameState.playerPosition.x
			self.position.z = gameState.playerPosition.z
			self.sound:setPosition(self.position.x, self.position.y, self.position.z)

			-- appearing, play the sound
			self.sound:play()
		end
	elseif self.state == 1 then
		if self.timer > monsterAppearTime then
			--print("monster attack")

			self.timer = 0
			self.state = 2 -- attack!
		end

	elseif self.state == 2 then
		-- move to the player
		local dx = gameState.playerPosition.x - self.position.x
		local dz = gameState.playerPosition.z - self.position.z
		local len = math.sqrt(dx * dx + dz * dz)

		dx = dx / len
		dz = dz / len

		self.position.x = self.position.x + dx * math.min(12.0 * dt, len)
		self.position.z = self.position.z + dz * math.min(12.0 * dt, len)

		-- if close enough, attack
		if len < 2 then
			-- play attack sound
			self.attackSound:play()
			self.sound:stop()

			-- switch to attack state
			self.timer = 0
			self.state = 3

			-- decrease healt
			gameState.health = gameState.health - 1	
		end

		if self.timer > monsterAttackTime then
			-- disappear
			self.timer = 0
			self.state = 0
			self.hiddentTime = love.math.random(monsterMinIdle, monsterMaxIdle) -- generate a new wait time
			self.sound:stop()
		end
	elseif self.state == 3 then -- Attacking
		-- stick to the player
		self.position.x = gameState.playerPosition.x
		self.position.z = gameState.playerPosition.z

		if self.timer > 3 then
			self.timer = 0
			self.state = 0
			self.hiddentTime = love.math.random(monsterMinIdle, monsterMaxIdle) -- generate a new wait time
			self.sound:stop()			
			self.attackSound:stop()
		end
	end

	self.sound:setPosition(self.position.x, self.position.y, self.position.z)
end

setmetatable(Monster, { __call = function(_, ...) return Monster.new(...) end })

showDebugMap = false

mouseSensibility = 0.005
indicatorVisibleTime = 0.1
indicatorFadeTime = 0.1
wallInvVisibilityIdle = 18
wallInvVisibilityWalk = 24
wallInvVisibilityRun = 64
wallInvVisibilityChangeRateUp = 100 -- per seconds
wallInvVisibilityChangeRateDown = 130 -- per seconds
wallInvVisibility = 12

wallWireframe = false
wallSize = 64

playerRadius = 1

gameState = State()
function gameState:load()
	self.playerPosition = {x = 96, y = 0, z = 96}
	self.playerAngular = {x = 0, y = 0, z = 0} -- angle

	self.sounds = {}

	self.footstepSound = StaticSound("footsteps_wood.wav", 0, 0, 0, 0, 0)
	self.footstepSound.source:setVolume(0)

	self.footstepRunSound = StaticSound("footsteps_run_wood.wav", 0, 0, 0, 0, 0)
	self.footstepRunSound.source:setVolume(0)


	self.indicator = love.graphics.newImage("indicator.png")
	self.indicatorRotation = 0
	self.indicatorTimer = 0

	love.mouse.setGrabbed(true)
	love.mouse.setRelativeMode(true)

	self.monster = Monster()

	self.health = 5

	self.level = {
		data = {
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 0, 0, 0, 2, 2, 2, 2, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1,
			1, 1, 0, 0, 0, 0, 2, 2, 2, 2, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1,
			1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1,
			1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1,
			1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1,
			1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1,
			1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1,
			1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
		},
		width = 20,
		height = 20
	}

	self.textures = {}

	self.textures[1] = love.graphics.newImage("Wall.png")
	self.textures[1]:setFilter("nearest", "nearest")

	self.textures[2] = love.graphics.newImage("brickWall.png")
	self.textures[2]:setFilter("nearest", "nearest")


	self.floorTexture = love.graphics.newImage("Floor.png")
	self.floorTexture:setFilter("nearest", "nearest")

	self.roofTexture = love.graphics.newImage("Roof.png")
	self.roofTexture:setFilter("nearest", "nearest")


	local pixelcode = [[
    	varying vec2 uv;
    	varying vec3 pos;

    	number coneLight(vec3 o, vec3 dir, vec3 p) {
    		vec3 _p = p - o;
    		number d = dot(normalize(_p), dir) - 0.8;

    		return (d * 5 * max(1 - length(_p) * 0.02, 0)) * 0.8 + 0.2;
    	}


    	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
      		vec4 texcolor = Texel(texture, uv.xy);

      		//number light = 1 - max(min(length(pos * 0.02), 1), 0);
      		//number light = coneLight(vec3(0, 0, 0), vec3(0, 0, -1), pos);
      		number light = 1.0;

      		texcolor.rgb *= color.a * light;

      		return texcolor;
    	}
  	]]

  	local vertexcode = [[
    	varying vec2 uv;
    	varying vec3 pos;

    	extern mat4x4 projectionMatrix;

    	vec4 position( mat4 transform_projection, vec4 vertex_position ) {
	   		uv = vec2(VertexColor.r, VertexColor.g);
	   		pos = vec3(vertex_position.x, vertex_position.y, VertexTexCoord.x);
      		return projectionMatrix * vec4(vertex_position.x, vertex_position.y, VertexTexCoord.x, 1);
    	}
  	]]

	self.shader = love.graphics.newShader(pixelcode, vertexcode)
end

function gameState:unload()
	-- stop every sound
	self.footstepSound.source:stop()
	self.footstepRunSound.source:stop()

	for k, v in pairs(self.sounds) do
		v.source:stop()
	end

	self.monster.sound:stop()

	love.mouse.setGrabbed(false)
	love.mouse.setRelativeMode(false)
end

function gameState:update(dt)
	-- update monster
	self.monster:update(dt, self)

	-- the end?
	if self.health == 0 then
		changeState(gameoverState)
	end

	local ptx = math.floor(self.playerPosition.x / wallSize)
	local pty = math.floor(self.playerPosition.z / wallSize)

	if ptx == 18 and pty == 11 then
		changeState(endState)
	end

	local playerForward = {x = math.sin(self.playerAngular.y), y = 0, z = -math.cos(self.playerAngular.y)}
	local playerSideVector = {x = playerForward.z, y = 0, z = -playerForward.x}

	local footstepVolume = 0
	local playerDisplacement = {x = 0; y = 0, z = 0}

	local fwdKey = "w"
	local backKey = "s"
	local leftKey = "a"
	local rightKey = "d"
	if azerty then 
		fwdKey = "z" 
		leftKey = "q"
	end

	local isMoving = false
	local isRunning = false
	local playerSpeed = 48.0

	-- is player running?
	if love.keyboard.isDown("lshift") then
		isRunning = true
		playerSpeed = 92.0
	end

	if love.keyboard.isDown(fwdKey) then
	   	playerDisplacement.x = playerForward.x * playerSpeed * dt
   		playerDisplacement.z = playerForward.z * playerSpeed * dt 	
   		isMoving = true
	elseif love.keyboard.isDown(backKey) then
	   	playerDisplacement.x = -playerForward.x * playerSpeed * dt
   		playerDisplacement.z = -playerForward.z * playerSpeed * dt 			
   		isMoving = true
	end

	if love.keyboard.isDown(leftKey) then
	   	playerDisplacement.x = playerDisplacement.x + playerSideVector.x * playerSpeed * dt
   		playerDisplacement.z = playerDisplacement.z + playerSideVector.z * playerSpeed * dt 	
  		isMoving = true
	elseif love.keyboard.isDown(rightKey) then
	   	playerDisplacement.x = playerDisplacement.x - playerSideVector.x * playerSpeed * dt
   		playerDisplacement.z = playerDisplacement.z - playerSideVector.z * playerSpeed * dt 			
  		isMoving = true
	end

	-- clamp displacement
	if playerDisplacement.x < 0 and self.level.data[(ptx - 1 + pty * self.level.width) + 1] ~= 0 then
		playerDisplacement.x = math.max(playerDisplacement.x, ptx * wallSize - self.playerPosition.x + playerRadius)
	end

	if playerDisplacement.x > 0 and self.level.data[(ptx + 1 + pty * self.level.width) + 1] ~= 0 then
		playerDisplacement.x = math.min(playerDisplacement.x, (ptx + 1) * wallSize - self.playerPosition.x - playerRadius)
	end

	if playerDisplacement.z < 0 and self.level.data[(ptx + (pty - 1) * self.level.width) + 1] ~= 0 then
		playerDisplacement.z = math.max(playerDisplacement.z, pty * wallSize - self.playerPosition.z + playerRadius)
	end

	if playerDisplacement.z > 0 and self.level.data[(ptx + (pty + 1) * self.level.width) + 1] ~= 0 then
		playerDisplacement.z = math.min(playerDisplacement.z, (pty + 1) * wallSize - self.playerPosition.z - playerRadius)
	end


	-- update position
	self.playerPosition.x = self.playerPosition.x + playerDisplacement.x
	self.playerPosition.z = self.playerPosition.z + playerDisplacement.z

	-- update foot steps volume
	local targetVisibility = wallInvVisibilityIdle
	if isMoving then
		if isRunning then
			self.footstepSound.source:setVolume(0)
			self.footstepRunSound.source:setVolume(1)
			targetVisibility = wallInvVisibilityRun
		else
			self.footstepSound.source:setVolume(1)
			self.footstepRunSound.source:setVolume(0)
			targetVisibility = wallInvVisibilityWalk
		end
	else
		-- idle
		-- no footstep sound
		self.footstepSound.source:setVolume(0)
		self.footstepRunSound.source:setVolume(0)
		targetVisibility = wallInvVisibilityIdle
	end

	-- update audio listener position
	love.audio.setPosition(self.playerPosition.x, self.playerPosition.y, self.playerPosition.z)
	love.audio.setOrientation(playerForward.x, playerForward.y, playerForward.z, 0, 1, 0)

	-- update visibility
	local change = math.max(math.min(targetVisibility - wallInvVisibility, wallInvVisibilityChangeRateDown * dt), -wallInvVisibilityChangeRateUp * dt)
	wallInvVisibility = wallInvVisibility + change
	
	-- update indicator timer
	self.indicatorTimer = self.indicatorTimer + dt
end

function gameState:mousemoved(x, y, dx, dy)
	--print(x, y, dx, dy)

	self.playerAngular.y = self.playerAngular.y + dx * mouseSensibility

	if self.playerAngular.y > math.pi then
		self.playerAngular.y = self.playerAngular.y - 2 * math.pi
	end

	if self.playerAngular.y < -math.pi then
		self.playerAngular.y = self.playerAngular.y + 2 * math.pi
	end

	if self.indicatorTimer < indicatorVisibleTime + indicatorFadeTime then
		self.indicatorRotation = self.indicatorRotation + dx * mouseSensibility
		self.indicatorTimer = 0
	else 
		self.indicatorRotation = dx * mouseSensibility
		self.indicatorTimer = 0		
	end

	--print(dx, self.playerAngular.y)
end

function gameState:keypressed(key)
	if key == "escape" then
		changeState(titleState)
	end
end

-- transform a point in eye space
function gameState:transformPoint(p)
	local tx = p.x - self.playerPosition.x
	local ty = p.y - self.playerPosition.y
	local tz = p.z - self.playerPosition.z

	-- rotate on y
	rx = {x = math.cos(-self.playerAngular.y), y = 0, z = math.sin(-self.playerAngular.y)}
	rz = {x = -math.sin(-self.playerAngular.y), y = 0, z = math.cos(-self.playerAngular.y)}

	local x = rx.x * tx + rz.x * tz
	local y = ty
	local z = rx.z * tx + rz.z * tz

	return {x = x, y = y, z = z}
end

function gameState:drawWall(x1, z1, x2, z2, min, max, texture, intensity)
	local p1 = self:transformPoint({x = x1, y = 0, z = z1})
	local p2 = self:transformPoint({x = x2, y = 0, z = z2})

	-- draw if visible
	if not (p1.z >= 0 and p2.z >= 0) then
		-- project points
		local A = {x = p1.x, y = min, z = p1.z}
		local B = {x = p1.x, y = max, z = p1.z}
		local C = {x = p2.x, y = min, z = p2.z}
		local D = {x = p2.x, y = max, z = p2.z}

		local mesh = love.graphics.newMesh({ { A.x, A.y, A.z, 0, (1 - p1.y) * 255,		0, 		0,	intensity},
											 { C.x, C.y, C.z, 0, 255 * p2.y,			0, 		0,	intensity},
											 { D.x, D.y, D.z, 0, 255 * p2.y, 			255, 	0,	intensity},
											 { B.x, B.y, B.z, 0, (1 - p1.y) * 255, 		255,	0,	intensity}})
		mesh:setTexture(texture)

		love.graphics.draw(mesh)
	end
end

function gameState:drawFloorTile(x, y)
	local A = self:transformPoint({x = x * wallSize, y = wallSize * 0.5, z = y * wallSize})
	local B = self:transformPoint({x = (x + 1) * wallSize, y = wallSize * 0.5, z = y * wallSize})
	local C = self:transformPoint({x = (x + 1) * wallSize, y = wallSize * 0.5, z = (y + 1) * wallSize})
	local D = self:transformPoint({x = x * wallSize, y = wallSize * 0.5, z = (y + 1) * wallSize})

	local mesh = love.graphics.newMesh({ { A.x, A.y, A.z, 0, 0,		0, 		0,	255},
										 { B.x, B.y, B.z, 0, 255,	0, 		0,	255},
										 { C.x, C.y, C.z, 0, 255,	255, 	0,	255},
										 { D.x, D.y, D.z, 0, 0, 	255,	0,	255}})
	mesh:setTexture(self.floorTexture)

	love.graphics.draw(mesh)
end

function gameState:drawRoofTile(x, y)
	local A = self:transformPoint({x = x * wallSize, y = -wallSize * 0.5, z = y * wallSize})
	local B = self:transformPoint({x = (x + 1) * wallSize, y = -wallSize * 0.5, z = y * wallSize})
	local C = self:transformPoint({x = (x + 1) * wallSize, y = -wallSize * 0.5, z = (y + 1) * wallSize})
	local D = self:transformPoint({x = x * wallSize, y = -wallSize * 0.5, z = (y + 1) * wallSize})

	local mesh = love.graphics.newMesh({ { A.x, A.y, A.z, 0, 0,		0, 		0,	255},
										 { B.x, B.y, B.z, 0, 255,	0, 		0,	255},
										 { C.x, C.y, C.z, 0, 255,	255, 	0,	255},
										 { D.x, D.y, D.z, 0, 0, 	255,	0,	255}})
	mesh:setTexture(self.roofTexture)

	love.graphics.draw(mesh)
end

function gameState:drawBlockFloor(x, y)
	local tile = self.level.data[(x + y * self.level.width) + 1]

	if tile == 0 then
		self:drawFloorTile(x, y)
	end
end

function gameState:drawBlockRoof(x, y)
	local tile = self.level.data[(x + y * self.level.width) + 1]

	if tile == 0 then
		self:drawRoofTile(x, y)
	end
end

function gameState:drawBlockWall(x, y)
	-- max 4 wall to draw
	--[[
	*----- 3 -----*
	|             |
	|             |
	1             2
	|             |
	|             |
	*----- 4 -----*
	]]

	local tile = self.level.data[(x + y * self.level.width) + 1]

	-- nothing to draw
	if tile ~= 0 then
		local min = -wallSize * 0.5
		local max = wallSize * 0.5

		-- else block == 1
		if x > 0 and self.level.data[(x - 1 + y * self.level.width) + 1] == 0 and self.playerPosition.x <= x * wallSize then
			self:drawWall(x * wallSize, y * wallSize, x * wallSize, (y + 1) * wallSize, min, max, self.textures[tile], 255)
		end

		if x < self.level.width - 1 and self.level.data[(x + 1 + y * self.level.width) + 1] == 0 and self.playerPosition.x >= (x + 1) * wallSize then
			self:drawWall((x + 1) * wallSize, y * wallSize, (x + 1) * wallSize, (y + 1) * wallSize, min, max, self.textures[tile], 255)
		end

		if y > 0 and self.level.data[(x + (y - 1) * self.level.width) + 1] == 0 and self.playerPosition.z <= y * wallSize then
			self:drawWall(x * wallSize, y * wallSize, (x + 1) * wallSize, y * wallSize, min, max, self.textures[tile], 128)
		end

		if y < self.level.height - 1 and self.level.data[(x + (y + 1) * self.level.width) + 1] == 0 and self.playerPosition.z >= (y + 1) * wallSize then
			self:drawWall(x * wallSize, (y + 1) * wallSize, (x + 1) * wallSize, (y + 1) * wallSize, min, max, self.textures[tile], 128)
		end
	end
end

function gameState:drawObject(x, z)
	local p = self:transformPoint({x = x, y = 5, z = z})
	local A = {x = p.x - 4, y = p.y - 8, z = p.z}
	local B = {x = p.x + 4, y = p.y - 8, z = p.z}
	local C = {x = p.x + 4, y = p.y, z = p.z}
	local D = {x = p.x - 4, y = p.y, z = p.z}

	local mesh = love.graphics.newMesh({ { A.x, A.y, A.z, 0, 0,		0, 		0,	255},
										 { B.x, B.y, B.z, 0, 255,	0, 		0,	255},
										 { C.x, C.y, C.z, 0, 255,	255, 	0,	255},
										 { D.x, D.y, D.z, 0, 0, 	255,	0,	255}})
	mesh:setTexture(self.roofTexture)

	love.graphics.draw(mesh)
end

function gameState:draw()
	love.graphics.setColor(255, 255, 255, 255)
	local winW, winH = love.graphics.getCanvas():getDimensions()

	-- compute projection matrix
	local near = 1
	local far = 1024
	local ratio = winW / winH
	local fov = math.tan(40.0 * math.pi / 360.0)
	local projectionMatrix = {
		{1 / (ratio * fov), 0, 0, 0},
		{0, 1 / fov, 0, 0},
		{0, 0, -(far + near) / (far - near), -2*far*near/(far - near)},
		{0, 0, -1, 0}
	}
	self.shader:send("projectionMatrix", projectionMatrix)

	-- drawing order
	local yStart = 0
	local yEnd = self.level.height - 1
	local yInc = 1

	local xStart = 0
	local xEnd = self.level.width - 1
	local xInc = 1

	local drawRow = true

	if self.playerAngular.y > 0 then
		xStart = xEnd
		xEnd = 0
		xInc = -1
	end

	if self.playerAngular.y < math.pi * -0.5 or self.playerAngular.y > math.pi * 0.5 then
		yStart = yEnd
		yEnd = 0
		yInc = -1
	end

	-- row of column or column of row?
	if (self.playerAngular.y > 0.25 * math.pi and self.playerAngular.y < 0.75 * math.pi) or (self.playerAngular.y < -0.25 * math.pi and self.playerAngular.y > -0.75 * math.pi) then
		drawRow = false
	end

	love.graphics.setShader(self.shader)
	-- draw roof and floor
	for y = yStart, yEnd, yInc do
			for x = xStart, xEnd, xInc do
			self:drawBlockRoof(x, y)
			self:drawBlockFloor(x, y)
		end
	end


	if drawRow then
		for y = yStart, yEnd, yInc do
			for x = xStart, xEnd, xInc do
				self:drawBlockWall(x, y)
			end
		end
	else -- draw column
		for x = xStart, xEnd, xInc do			
			for y = yStart, yEnd, yInc do
				self:drawBlockWall(x, y)
			end
		end
	end		

	self:drawObject(self.monster.position.x, self.monster.position.z)

	love.graphics.setShader()

	love.graphics.print(wallInvVisibility, 0, 0)

	-- draw rotation indicator
	local indicatorAlpha = 255
	if self.indicatorTimer > indicatorVisibleTime then
		indicatorAlpha = 255 * math.max(1 - (self.indicatorTimer - indicatorVisibleTime) / indicatorFadeTime, 0)
	end

	love.graphics.setColor(255, 255, 255, indicatorAlpha)
	love.graphics.draw(self.indicator, 96 / screenScale, winH - 96 / screenScale, self.indicatorRotation, 1 / screenScale , 1 / screenScale, 64, 64)
end