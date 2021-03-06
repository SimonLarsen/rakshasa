local BaseLaser = require("game.enemies.BaseLaser")
local PlayerBullet = require("game.PlayerBullet")
local Flash = require("game.Flash")

local Laser = class("game.enemies.Laser", BaseLaser)

local MOVE_SPEED = 70

function Laser:enter(properties)
	assert(#properties.points == 2, "Laser needs two points.")
	BaseLaser.enter(self)

	local p1, p2 = properties.points[1], properties.points[2]
	if p1.x > p2.x then
		p1, p2 = p2, p1
	end
	local xdist = p2.x - p1.x
	local ydist = p2.y - p1.y

	self.x = math.floor((p1.x + p2.x) / 2)
	self.y = -math.abs(ydist)-8
	self.dir = math.floor(math.atan2(ydist, xdist) / (math.pi/4) + 0.5) * (math.pi/4)
	self.dist = math.sqrt(xdist^2 + ydist^2)
	self.speed = properties.speed or MOVE_SPEED
	self.beam_sprites = {}
	self.on = true
	self.time = 0

	if properties.intervals then
		self.on = false
		self.interval = 1
		parts = prox.string.split(properties.intervals, ",")
		self.intervals = {}
		for i,v in ipairs(parts) do
			table.insert(self.intervals, tonumber(v))
		end
	end
	
	local ortho = math.floor(self.dir / (math.pi/4) + 0.5) % 2 == 0
	local odist = self.dist+12

	self:setRenderer(prox.MultiRenderer())

	self.turret_anim1 = prox.Animation("data/animations/enemies/laser_spawner.lua")
	self.turret_anim2 = prox.Animation("data/animations/enemies/laser_spawner.lua")

	self:getRenderer():addRenderer(self.turret_anim1, math.floor(-math.cos(self.dir)*odist/2 + 0.5), math.floor(-math.sin(self.dir)*odist/2 + 0.5))
	self:getRenderer():addRenderer(self.turret_anim2, math.floor( math.cos(self.dir)*odist/2 + 0.5), math.floor( math.sin(self.dir)*odist/2 + 0.5))

	local beam_anim = prox.Animation("data/animations/enemies/laser_beam_orthogonal.lua")
	table.insert(self.beam_sprites, beam_anim)
	self:getRenderer():addRenderer(beam_anim, 0, 0)
	if ortho then
		beam_anim:setScale(self.dist-6, 1)
	else
		beam_anim:setScale(self.dist-7, 1)
	end
	beam_anim:setRotation(self.dir)

	self.laser_end1 = prox.Animation("data/animations/enemies/laser_end_orthogonal.lua")
	self.laser_end1:setRotation(self.dir)
	self.laser_end2 = prox.Animation("data/animations/enemies/laser_end_orthogonal.lua")
	self.laser_end2:setRotation(self.dir+math.pi)

	self:getRenderer():addRenderer(self.laser_end1, math.floor(-math.cos(self.dir)*odist/2 + 0.5), math.floor(-math.sin(self.dir)*odist/2 + 0.5))
	self:getRenderer():addRenderer(self.laser_end2, math.floor( math.cos(self.dir)*odist/2 + 0.5), math.floor( math.sin(self.dir)*odist/2 + 0.5))

	--self.turret_anim1:setProperty("state", self.on)
	--self.turret_anim2:setProperty("state", self.on)

	if self.intervals then
		for i,v in ipairs(self.beam_sprites) do
			v:setVisible(false)
		end
	end

	self.hc_rect = HC.rectangle(0, 0, odist, 16)
	self.hc_rect:setRotation(self.dir)
end

function Laser:update(dt, rt)
	BaseLaser.update(self, dt, rt)

	self.y = self.y + self.speed * dt
	self.hc_rect:moveTo(self.x, self.y)
	
	self.time = self.time + dt
	if self.intervals and self.time >= self.intervals[self.interval] then
		self.on = not self.on
		self.time = 0
		self.interval = self.interval % #self.intervals + 1

		for i,v in ipairs(self.beam_sprites) do
			v:setVisible(self.on)
			v:reset()
			--self.turret_anim1:setProperty("state", self.on)
			--self.turret_anim2:setProperty("state", self.on)
		end
	end

	if self.on then
		for i,v in ipairs(self:getScene():findAll(PlayerBullet)) do
			if self.hc_rect:collidesWith(v:getHCShape()) then
				v:kill(true)
			end
		end
	end

	if self.y > settings.screen_height+math.abs(math.sin(self.dir))*(self.dist+12)+32 then
		self:remove()
	end
end

function Laser:getHCShape()
	if self.on then
		return self.hc_rect
	end
end

function Laser:kill()
	
end

return Laser
