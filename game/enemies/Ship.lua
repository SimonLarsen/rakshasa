local Enemy = require("game.Enemy")
local EnemyBullet = require("game.EnemyBullet")
local Explosion = require("game.Explosion")
local Flash = require("game.Flash")

local Ship = class("game.Ship", Enemy)

Ship.static.STATE_ENTER = 1
Ship.static.STATE_IDLE  = 2
Ship.static.STATE_EXIT  = 3

local MAX_HEALTH = 2

local ENTER_TIME = 1
local IDLE_TIME = 2

local IDLE_SPEED = 10
local IDLE_ACCELERATION = 50

local EXIT_SPEED = 150
local EXIT_ACCELERATION = 150

local BULLET_COOLDOWN = 2.5

function Ship:enter(destx, desty)
	Enemy.enter(self, MAX_HEALTH)

	self.x = destx
	self.y = -20
	self.destx = destx
	self.desty = desty
	self.state = Ship.static.STATE_ENTER
	self.time = 0
	self.yspeed = 0
	self.cooldown = ENTER_TIME

	self.player_chain = self:getScene():find("chain")

	self.timer = prox.timer.tween(
		ENTER_TIME, self,
		{x = self.destx, y = self.desty}, "out-quad",
		function()
			self.state = Ship.static.STATE_IDLE
			self.time = IDLE_TIME
		end
	)

	self:setRenderer(prox.Animation("data/animations/enemies/ship.lua"))
	self:setCollider(prox.BoxCollider(32, 24))
end

function Ship:update(dt, rt)
	dt, rt = Enemy.update(self, dt, rt)

	if self.state == Ship.static.STATE_IDLE then
		self.time = self.time - dt
		self.yspeed = prox.math.cap(self.yspeed + IDLE_ACCELERATION * dt, 0, IDLE_SPEED)
		self.y = self.y + self.yspeed * dt
		if self.time <= 0 then
			self.state = Ship.static.STATE_EXIT
		end

	elseif self.state == Ship.static.STATE_EXIT then
		self.yspeed = prox.math.cap(self.yspeed + EXIT_ACCELERATION * dt, 0, EXIT_SPEED)
		self.y = self.y + self.yspeed * dt
	end

	self.cooldown = self.cooldown - dt
	if self.cooldown <= 0 then
		self.cooldown = BULLET_COOLDOWN
		self:shoot()
	end

	if self.y > prox.window.getHeight()+32 then
		self:remove()
	end
end

function Ship:shoot()
	local xdist = self.player_chain.x - self.x
	local ydist = self.player_chain.y - self.y
	local dir = math.atan2(ydist, xdist)
	self:getScene():add(EnemyBullet(self.x, self.y, dir, EnemyBullet.static.TYPE_BALL))
	self:getScene():add(Flash(self.x, self.y))
end

function Ship:onRemove()
	if self.timer then
		prox.timer.cancel(self.timer)
	end
end

function Ship:getGems()
	return 2
end

return Ship