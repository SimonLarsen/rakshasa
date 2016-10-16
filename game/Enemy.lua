local shaders = require("shaders")
local Explosion = require("game.Explosion")
local Gem = require("game.Gem")

local Enemy = class("game.Enemy", prox.Entity)

function Enemy:enter(health, large)
	self.max_health = health
	self.health = self.max_health
	self.hit = 0
	self.large = large or false
	self.invulnerable = 0
	self.time_speed = 1

	self.white_shader = shaders.getShader("data/shaders/whiteout.lua")

	self.sfx_explosion1 = prox.resources.getSound("data/sounds/explosion1.wav")
	self.sfx_explosion3 = prox.resources.getSound("data/sounds/explosion3.wav")
end

function Enemy:update(dt, rt)
	dt = dt * self.time_speed
	self.invulnerable = self.invulnerable - dt
	self.hit = self.hit - dt
	self:getRenderer():setShader(self.hit > 0 and self.white_shader or nil)
	return dt, rt
end

function Enemy:onCollide(o, dt, rt)
	if o:getName() == "player_bullet" then
		if self.invulnerable <= 0 then
			self:damage(o:getDamage())
		end
		o:kill()
	elseif o:getName() == "player_powerball" then
		if self.invulnerable <= 0 then
			self:damage(o:getDamage())
			self.invulnerable = 0.5
		end
	end

	if self.health <= 0 then
		self:kill()
	end
end

function Enemy:damage(damage)
	self.health = self.health - damage
	self.hit = 0.05
end

function Enemy:kill()
	if self.large then
		self:getScene():add(Explosion(self.x, self.y, Explosion.static.SIZE_LARGE))
		self:getScene():find("screenshaker"):shake(0.5, 2, 60)
		local sfx = prox.resources.getSound("data/sounds/explosion3.wav")
		self.sfx_explosion3:play()
	else
		self:getScene():add(Explosion(self.x, self.y, Explosion.static.SIZE_MEDIUM))
		self:getScene():find("screenshaker"):shake(0.3, 1, 60)
		self.sfx_explosion1:play()
	end
	
	for i=1, self:getGems() do
		self:getScene():add(Gem(
			self.x + love.math.random(-8, 8),
			self.y + love.math.random(-8, 8)
		))
	end

	self:remove()
end

function Enemy:setTimeSpeed(speed)
	self.time_speed = 1
end

return Enemy
