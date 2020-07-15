-- globals
_G = _ENV
_G.__index = _G
background, foreground, front, immediate, title, title_update, title_draw, game_update, game_draw, win_update, win_draw, goober_dialog, demilich_dialog, deaths = unpack(split"0,0,0,0,0,0,0,0,0,0,0,0,0,0")

local function noop()end

local function unpack(arr, from, to)
	from = from or 1
	to = to or #arr
	if (from > to) return
	return arr[from], unpack(arr, from + 1, to)
end

_sfx = sfx
function sfx(str)
	_sfx(unpack(split(str)))
end

local function keep_the_change(n, denominator)
	denominator = denominator or 8
	return n \ denominator * denominator
end

local function center(subject)
	return (type(subject) == "string" or type(subject) == "number") and ((126 - #tostr(subject) * 4) / 2) or ((127 - subject.width) / 2)
end

local function rnd_range(t)
	local a, b = unpack(split(t))
	return rnd(a) - b
end

local function same_screen(a, b)
	return a \ 128 == b \ 128
end

local function get_distance(x1, y1, x2, y2)
 return sqrt((y2 - y1) ^ 2 + (x2 - x1) ^ 2)
end

local class do
	local mt = setmetatable({
		x = 0,
		y = 0,
		update = noop,
		draw = noop,
		init = noop,
		__call = function(self, o)
			o = o or {}
			setmetatable(o, self)
			self.__index = self
			self.__call = getmetatable(self).__call
			o:init(self)

			return o
		end
	}, _G)
	mt.__index = mt
	class = setmetatable({}, mt)
end

local cam = class{
	mx = 0,
	my = 0,
	shake_level = 0,
-- focus_size = 64,
	left_focus = 0,
	right_focus = 0,
-- left_bound = 0,
-- right_bound = 1023,
	attach = function(self, target)
		local _ENV = self
		local tx = target.x
		self.target = target
		left_focus = mid(31.5, tx - 32, 927.5)
--    self.left_focus = mid((127 - focus_size) / 2, tx - focus_size / 2, right_bound - focus_size - (127 - focus_size) / 2)
		right_focus = mid(95.5, tx + 32, 991.5)
--    self.right_focus = mid(left_bound + focus_size + (127 - focus_size) / 2, tx + focus_size / 2, right_bound - (127 - focus_size) / 2)
		x = max(0, tx - 63)
		y = max(0, target.y - 63)
	end,
	update = function(self)
		local _ENV = self
		local tx, tdx = target.x, target.dx

		if shake_level > 0 then
			mx = rnd_range"10,5" / 10 * shake_level
			my = rnd_range"10,5" / 10 * shake_level
		else
			mx, my = 0, 0
		end

		local fn = tdx >= 0 and flr or ceil -- prevent subpixel jank
		if x ~= mid(left_focus, x, right_focus) then
			if (not boss_fight) and ((tx < left_focus and tdx < 0) or (tx + 12 > right_focus and tdx > 0)) then
				left_focus = mid(31.5, left_focus + fn(tdx), 927.5)
--          left_focus = mid(left_bound + ((127 - focus_size) / 2), left_focus + fn(tdx), right_bound - focus_size - ((127 - focus_size) / 2))
				right_focus = mid(95.5, right_focus + fn(tdx), 991)
--          right_focus = mid(left_bound + focus_size + (127 - focus_size) / 2, right_focus + fn(tdx), right_bound - focus_size / 2)
				x = mid(0, x + fn(tdx), 896)
--          x = mid(left_bound, x + fn(tdx), right_bound - 127)
			end
		end
		x = mid(0, x, 896)
		y = keep_the_change(target.y, 128)
		shake_level *= 0.9
		if (shake_level <= 0.1) shake_level = 0

		local _x, _y = mid(0, x, 896) + mx, y + my
--    local _x, _y = mid(0, self.x, self.right_bound - 127) + mx, self.y + my
		draw = function(self)
			camera(_x, _y)
		end
	end,
}

local new_ui = class{
	init = function(self)
		self.layers = {
			{}, -- 1 - global background
			{}, -- 2 - global foreground
			{}, -- 3 - global front
			{}, -- 4 - global immediate
		}
	end,
	update = function(self)
		for layer in all(self.layers) do
			for o in all(layer) do
				if (o.type ~= "player") o:update(layer)
			end
		end
		pc:update(foreground) -- update player last
	end,
	draw = function(self)
		local _ENV = self
		for layer in all(layers) do
			for o in all(layer) do o:draw() end
		end
	end,
}

local function is_flag(x, y, flag)
	if (flag == 3) y -= 4
	return fget(mget(x \ 8, y \ 8), flag)
end

local gateways do
	local i = 1
	gateways = {
		[4] = function()
			if not (boss_fight or boss_dead) then
				music(-1, 1000)
				return new_scene{
					messages = {
						demilich_dialog"you! why do you disturb\x0ame? do you seek to take\x0amy star?",
						goober_dialog"you must be the one\x0ashaking things up down\x0ahere.",
						demilich_dialog"fool! a fallen star\x0alanded in these caverns.\x0ait belongs to me.",
						goober_dialog"i don't know what a \x1estar\x1e\x0ais, but i don't think we\x0ahave those in the caverns.",
						demilich_dialog"you can't have it!\x0ait has great power and\x0ait's mine!",
						goober_dialog"...",
						goober_dialog"i'm just trying to find a\x0away out of here.",
						demilich_dialog("lies! lies! all lies!\x0athe star is mine. now die!", function()
							music(24)
							boss_fight = true
						end)
					}
				}
			end
		end,
		[52] = function()
			_upd, _drw = win_update, win_draw
		end,
		[56] = function()
			if has_star then
				cam.shake_level = 1
				sfx"31"
				for y = 35, 37 do
					mset(55, y, 0)
				end
			end
		end,
	}
	for coords in all(split("1000,456;616,152;208,104;168,352;16,104", ";")) do
		gateways[split"0,23,25,76,126"[i]] = function()
			pc.x, pc.y = unpack(split(coords))
			last_checkpoint = coords == "16,104" and "992,456" or coords
			cam:attach(pc)
		end
		i += 1
	end
end

local treasure_chest = class{
	n = 35,
	callback = noop,
	update = function(self)
		local _ENV = self
		local px, py = pc.x, pc.y
		if (not open) and pc.grounded and same_screen(y, py) and same_screen(x, px) and get_distance(x + 4, y + 4, px + 7.5, py + 12) < 16 then
--		if (not self.open) and pc.grounded and y \ 127 == py \ 127 and x \ 127 == px \ 127 and get_distance(x + 4, y + 4, px + pc.width / 2, py + 0.75 * pc.height) < 16 then
			n, open = 36, true
			sfx"31"
			return self:callback()
		end
	end,
	draw = function(self)
		local _ENV = self
		spr(n, x, y, 1, 1, flip)
	end,
}

local chunks = class{
	init = function(self)
		local _ENV = self
		chunks = {}
		for i = 1, 4 do
			add(chunks, {
				x = x,
				y = y,
				dx = rnd_range"50,25",
				dy = -5,
			 })
		end
	end,
	update = function(self, layer)
		local _ENV = self
		if (not same_screen(pc.y, y)) or pc.x \ 255 ~= x \ 255 then
			del(layer, self)
		end
		foreach(chunks, function(chunk)
			chunk.x += chunk.dx * dt
			chunk.y += chunk.dy * dt
			chunk.dy += dt * 150
			if is_flag(chunk.x + 1, chunk.y + 3, 0) then
				chunk.dy = 0
				chunk.dx = 0
			end
		end)
		if (#chunks == 0) del(layer, self)
	end,
	draw = function(self)
		foreach(self.chunks, function(chunk)
			sspr(5, 24, 3, 3, chunk.x, chunk.y)
		end)
	end,
}

local sparkle = class{
	init = function(self)
		local _ENV = self
		sparks = {}
		for i = 1, 35 do
			add(sparks, {
				x = x,
				y = y,
				dx = rnd_range"15,10",
				dy = rnd_range"15,10",
				col = rnd{ col, 7, 9 },
				t = rnd(50)
			 })
		end
	end,
	update = function(self, layer)
		local _ENV = self
		foreach(sparks, function(spark)
			spark.x += spark.dx * dt
			spark.y += spark.dy * dt
			spark.dy += 0.7
			spark.t -= 1
			if (spark.t <= 0) del(sparks, spark)
		end)
		if (#sparks == 0) del(layer, self)
	end,
	draw = function(self)
		foreach(self.sparks, function(spark)
			pset(spark.x, spark.y, spark.col)
		end)
	end,
}

local particle = class{
	0, -- 1 - x
	0, -- 2 - y
	2, -- 3 - size
	13, -- 4 - col
	update = function(self, layer)
		self[3] *= 0.8
		if (self[3] <= 0.3) del(layer, self)
	end,
	draw = function(self)
		circfill(unpack(self))
	end,
}

local water_generator = class{
	new_water = function(self)
		local _ENV = self
		return particle{
			x + rnd(7),
			y + rnd(split"4,5,6,7,8"),
			super = self,
			rnd(split"3,4,5"),
			rnd{ 6, 13 },
			update = function(self, particles)
				local _ENV = self
				self[3] *= 0.8
				if self[3] <= 1 then
					local p = super:new_water()
					del(particles, self)
					add(particles, p)
				end
			end
		}
	end,
	init = function(self)
		self.init = function(self)
			local _ENV = self
			x, y = unpack(self)
			particles = {}
			for i = 1, rnd(split"4,5,6,7,8") do
				add(particles, self:new_water())
			end
		end
	end,
	update = function(self)
		local _ENV = self
		if same_screen(pc.y, y) and pc.x \ 255 == x \ 255 then
			foreach(particles, function(p)
				p:update(particles)
			end)
			sfx"30"
			draw = function(self)
				foreach(self.particles, function(p)
					p:draw()
				end)
			end
		else
			draw = noop
		end
	end,
}

local torch = class{
	n = 0,
	init = function(self) self.x, self.y = unpack(self) end,
	update = function(self)
		self.n = flr(time() * 4 % 2) ~= 0 and 32 or 16
	end,
	draw = function(self)
		local ns = { 1, 33, 17, 33, self.n, 33, 2, 33, 18 }
		for i = 1, #ns do
			local n = i - 1
			spr(ns[i], self.x + 8 * n \ 3, self.y + 8 * (n % 3))
		end
	end,
}

local actor = class{
	dx = 0,
	dy = 0,
	height = 8,
	width = 8,
	dir = 1,
	accx = 1,
	max_speed = 1,
	health = 1,
	frozen = 0,
	check_ground = function(self)
		local _ENV = self
		return is_flag(x, y + height, 0) or is_flag(x + width - 1, y + height, 0)
	end,
	check_ceiling = function(self)
		local _ENV = self
		return is_flag(x, y, 2) or is_flag(x + width - 1, y, 2)
	end,
	check_forward = function(self, flag)
		local _ENV = self
		local x, dir = x, dir
		if (recoil) dir *= -1
		if (dir ~= -1)	x += width - 1
		return is_flag(x, y, flag) or is_flag(x, y + height - 1, flag)
	end,
	check_terrain = function(self, flag)
		local _ENV = self
		local y = y
		if (flag == 7) y -= 4
		return is_flag(x, y + height, flag) or is_flag(x + width, y + height, flag)
	end,
	hurt = function(self, o)
		local _ENV = self
		o = o or {}
		dx = o.dx or 5 * (o.x and sgn(x - o.x) or dir * -1)
		dy = (o.dy or -3)
		health -= 1
		frozen = 0
		recoil = true
		if (o.dir) dir = o.dir
	end,
	set_anim = function(self, state)
		self.anim = self.anim_state[tonum(state)]
	end,
	draw_sprite = noop,
	draw = function(self)
		self:draw_sprite()
	end,
}

local shrine = actor{
	update = function(self)
		local _ENV = self
		local x = x + 8
		-- local x, y, px = self.x + 8, self.y, pc.x + 8
		if same_screen(y, pc.y) and abs(x - pc.x - 8) <= 8 and pc.grounded and not active then
			active = true
			add(background, sparkle{ x = x, y = y, col = 2 })
			_G.last_checkpoint = x .. "," .. y
			sfx"36"
		elseif abs(x - pc.x - 8) > 8 then
			active = false
		end
	end,
	draw_sprite = function(self)
		spr(40, self.x, self.y, 2, 2)
	end,
}

lavatile = actor{
	type = "lava",
	init = function(self)
		self.init = function(self)
			local _ENV = self
			x = _x * 8
			y = _y * 8
			mset(_x, _y, 12)
		end
	end,
	update = function(self)
		local _ENV = self
		if frozen > 0 then
			frozen = max(frozen - dt, 0)
			if (frozen == 0) self:init()
		end
	end,
	freeze = function(self)
		self.frozen = 4
		mset(self._x, self._y, 13)
	end
}

local rat = actor{
	type = "enemy",
	anim_state = {
		{ speed = 1, { n = 60, offset_y = 3 }, { n = 61, offset_y = 1 } },
-- idle = { speed = 1, { n = 60, offset_y = 3 }, { n = 61, offset_y = 1 } },
		{ speed = 8, { n = 44, offset_y = 3 }, { n = 45, offset_y = 4 } },
-- run = { speed = 8, { n = 44, offset_y = 3 }, { n = 45, offset_y = 4 } },
	},
	stamina = 2,
	max_stamina = 2,
	accx = 10,
	max_speed = 1.5,
	init = function(self)
		self.anchor = { self.x, self.y }
	end,
	update = function(self, layer)
		local _ENV = self
		local old_x, is_frozen, dead = x, frozen > 0, health <= 0
		anim, animx, sprite_n, tx, ty, anchorx = anim or anim_state[1], animx or {}, sprite_n or 60, target.x + 6.5, target.y, anchor[1]
		local grounded = self:check_ground() and not dead
		local left, right = tx and tx < x or dead and dx < 0, tx and tx > x or dead and dx > 0

		if (y > 512) self:die()

		if not (recoil or is_frozen or pause or stamina == 0 or dead) then
			local diff_x, same_level, anchordiff = abs(tx - (x + 4)), same_screen(y, ty), anchorx - x
			-- local diff_x, same_level, anchordiff = abs(tx - (x + width / 2)), y \ 127 == ty \ 127, anchorx - x
			if chasing and same_level then
				if diff_x > 180 or abs(ty - y) > 120 then
					chasing = false
					dir = sgn(anchordiff)
					if (abs(anchordiff) > 10) dx += accx * dt * dir
				elseif diff_x > 8 then
					dx += accx * dt * (left and -1 or 1)
					if (dx ~= 0) dir = sgn(dx)
				end
			elseif same_level and diff_x == mid(13, diff_x, 63) then
				chasing = true
				dx += accx * dt * (left and -1 or 1)
				if (dx ~= 0) dir = sgn(dx)
			else
				chasing = false
				dir = sgn(anchordiff)
				if abs(anchordiff) > 10 then
					dx += accx * dt * dir
				else
					return
				end
			end
		elseif dead and abs(dx) > 0 then
			dx += accx * dt * sgn(dx)
		elseif is_frozen then
			dx *= 0.93
		elseif grounded then
			dx = 0
		end

		if (not grounded)	dy += 0.5 -- gravity

		dx = mid(-max_speed, dx, max_speed)
		dy = mid(-5, dy, 5)
		x += dx
		y += dy

		local predictive_coords = { x = x, y = y, width = 8, height = 8, dir = dir }
		if (not dead) and sgn(dy) == 1 and check_ground(predictive_coords) then
			grounded = true
			y = keep_the_change(y)
			dy = 0
		end

		if (not dead or dx == 0) and check_forward(predictive_coords, 1) then
			if (recoil) dir *= -1 -- facing one dir traveling another
			local fn = dir == 1 and flr or ceil
			dx = 0
			x = fn(x / 8) * 8
		end

		if flr(old_x) ~= flr(x) and (left or right) then
			stamina = max(0, stamina - dt)
			if (stamina == 0) pause = true
		else
			stamina = min(stamina + dt, max_stamina)
			if (pause and stamina == max_stamina) pause = false
		end

		self:set_anim(not (dx == 0 or flr(x) == flr(old_x)) and "2" or "1")

		local offset_y = animx.offset_y or 0
		local t = { x, y + offset_y, 1, (8 - offset_y) / 8, dir == -1, dead }
		if not is_frozen then
			if (not dead) animx = anim[flr(time() * (anim.speed or 1) % #anim) + 1]
			sprite_n = animx.n
		else
			frozen = max(0, frozen - dt)
		end
		add(t, sprite_n, 1)
		draw_sprite = function(self)
			if (is_frozen) pal(split"12,13,3,4,13")
			spr(unpack(t))
			pal(split"1,2,3,4,5")
		end

		if (not dead) and target.health then
			local distance = abs(get_distance(x + (dir > 0 and 6 or 3), y + offset_y + (t[5] or 0) * 4, target.x + 8, ty + 8))
			if distance < 10 and abs(x - tx) < 100 and abs(y - ty) < 100 and not (target.recoil or target.invuln > 0) then
				target:hurt{ x = x }
			end
		end
	end,
}

local bat = actor{
	type = "enemy",
	anim_state = {
		{ speed = 1, { n = 30, offset_x = 1 } },
	-- idle = { speed = 1, { n = 30, offset_x = 1 } },
		{ speed = 8, { n = 46, offset_y = 3 }, { n = 47, offset_y = 4 } },
	-- run = { speed = 8, { n = 46, offset_y = 3 }, { n = 47, offset_y = 4 } },
	},
	accx = 10,
-- max_speed = 1.5,
	attack_length = 2,
	sight_range_y = 100,
	init = function(self)
		self.anchor = { self.x, self.y }
	end,
	swoop = function(self, t)
		self.dy += self.accy or 10.75
		self.swooping = true
	end,
	flutter = 0,
	update = function(self, layer)
		local _ENV = self
		anim, animx, sprite_n = anim or anim_state[1], animx or {}, sprite_n or {}
		local is_frozen, dead, tx, ty, anchorx, anchory = frozen > 0, health <= 0, target.x + 8, target.y + 8, unpack(anchor)

		if (y > 512) self:die()

		if swooping then
			dy -= 0.7
			if (dy <= 0.3) dy = 0
		elseif not (dead or is_frozen or perched or flutter > 0) then
			dy = max(dy - 0.3, -5)
		elseif dead or is_frozen then
			dy += 0.5 -- gravity
		end

		-- behavior
		if not (dead or is_frozen) then
			if perched and abs(tx - x) < 22 and ty - y > 0 and ty - y < sight_range_y and not swooping then -- dive
				self:swoop{ x = tx, y = ty }
				swooping = true
				perched = false
				swoop_fn = tx < x and function(x) return cos(x) * -1 end or cos
			elseif swooping and flutter == 0 and dy <= 0 then -- attack
				swooping = false
				flutter += dt
				dx = accx * 9 * swoop_fn(flutter)
				dy = swoop_fn(2 * flutter)
			elseif flutter > 0 and flutter < attack_length then -- figure 8
				flutter += dt
				dx = accx * 9 * swoop_fn(flutter)
				dy = swoop_fn(2 * flutter)
			elseif flutter >= attack_length then -- done
				flutter = 0
				dy = 0
				dx = 0
			elseif not perched then -- return
				local diff = anchorx - x
				if (abs(diff) > 1) dx += accx * dt * sgn(diff)
				dx = min(dx, anchorx - x)
			end
		elseif is_frozen then
			swooping = false
			flutter = 0
		end

		dx = mid(-1.5, dx, 1.5)
		-- dx = mid(-max_speed, dx, max_speed)
		x += dx
		y += dy

		if (not dead) and sgn(dy) == 1 and check_ground{ x = x, y = y, width = 7, height = 8 } then
		-- if (not dead) and sgn(dy) == 1 and self.check_ground{ x = x, y = y, width = 7, height = 8 - 1 } then
			if is_frozen then
				grounded = true
				perched = false
				dx *= 0.8
			end

			y = keep_the_change(y)
			dy = -0.5
		elseif dy <= 0 and check_ceiling{ x = x, y = y, width = 7 } then
			dy = 0
			dx = 0
			perched = true
			y = ceil(y / 8) * 8
		end

		if (not dead) and abs(dx) > 0 and check_forward({ x = x, y = y, width = 7, height = 8, dir = dir }, 1) then
		-- if (not dead) and abs(dx) > 0 and self.check_wall{ x = x, y = y, width = 8, height = height, dir = dir } then
			local fn = dir == 1 and flr or ceil
			dx = 0
			x = keep_the_change(x)
		end

		self:set_anim(perched and "1" or "2")

		local offset_x, offset_y = animx.offset_x or 0, animx.offset_y or 0
		local t = { x + offset_x, y + offset_y, 1, (8 - offset_y) / 8, dead }
		if not is_frozen then
			if (not dead) animx = anim[flr(time() * (anim.speed) % #anim) + 1]
			sprite_n = animx.n
		else
			frozen = max(0, frozen - dt)
		end
		add(t, sprite_n, 1)
		draw_sprite = function(self)
			if (is_frozen) pal(split"12,13")
			spr(unpack(t))
			pal(split"1,2")
		end

		if (not (dead or is_frozen)) and target and target.health then
			local distance = abs(get_distance(x + 4, y + (animx.offset_y or 0) + t[4] * 4, tx, ty))
			if distance < 11 and abs(x - tx) < 100 and abs(y - ty) < 100 and not (target.recoil or target.invuln > 0) then
				target:hurt{ x = x, dx = -5 * target.dir } -- you shall not pass
			end
		end
	end,
}

local projectile = actor{
	init = function(self)
		self.init = function(self)
			local _ENV = self
			hurt = activate
			target_x, target_y = target.x + 8, target.y + 8
			distance_x, distance_y = target_x - x, target_y - y
		end
	end,
	activate = function(self)
		local x, y = self.x + 4, self.y + 4
		for i = 1, rnd(split"10,11,12,13,14,15,16,17,18,19,20") do
			sfx"25"
			add(front, particle{
				x + rnd_range"10,5",
				y + rnd_range"10,5",
				rnd_range"10,-5",
				rnd(split"6, 5, 5, 11, 11"),
			})
		end

		local pcx, pcy = pc.x + 6.5, pc.y + 7.5
		if get_distance(x, y, pcx, pcy) <= 20 then -- magic number
			pc:hurt{ x = self.x }
		end
		del(foreground, self)
	end,
	update = function(self)
		local _ENV = self
		local predictive_coords, distance = { x = x, y = y, width = 2, height = 2, dir = target_x - x }, get_distance(x, y, pc.x + 8, pc.y + 8)

		if (sgn(dy) == 1 and check_ground(predictive_coords)) or is_flag(x, y, 1) or distance <= 10 then
			self:activate()
		end

		x += distance_x * dt
		y += distance_y * dt
	end,
	draw = function(self)
		circfill(self.x, self.y, 2, 11)
	end,
}

local demilich = actor{
	type = "enemy",
	health = 3,
	sprite_n = 62,
	anchor = 4,
	anchors = split("32,48;64,48;96,48;90,90", ";"),
	hurt = function(self)
		if boss_fight then
			local _ENV = self
			health -= 1
			timer = 2
			pattern, anchor = patterns[2], 2
		end
	end,
	die = function(self, reset)
		if not reset then
			return new_scene{
				messages = {
					demilich_dialog"no! you can't have it",
					demilich_dialog"to think the star should\x0afall into the hands of a\x0awindshield monster...",
				},
				callback = function()
					cam.shake_level = 1
					boss_fight = false
					boss_dead = true
					music(1)
					for coords in all(split("1,12;1,13;1,14;103,27;103,28;103,29;103,30", ";")) do
						mset(unpack(split(coords))) -- implicit 0 conversion from nil?
					end
					del(foreground, self)
				end
			}
		else
			del(foreground, self)
		end
	end,
	init = function(self)
		local _ENV = self
		patterns = {
			cocreate(function(self) -- circle / idle
				local _ENV = self
				while true do
					timer = timer or rnd_range"1,-1"
					repeat
						dx = cos(time_now) * -1
						dy = sin(time_now)
						if (boss_fight) timer -= dt
						yield()
					until timer <= 0
					timer = nil
					add(foreground, projectile{
						target = pc,
						x = x + 4,
						y = y + 6,
					})
					local new_anchor
					repeat new_anchor = rnd(split"1,3,4,4") until new_anchor ~= anchor
					anchor = new_anchor
					dx, dy = 0, 0
					pattern = patterns[2]
					yield()
				end
			end),
			cocreate(function(self) -- move to set anchor
				local _ENV = self
				while true do
					local anchor_x, anchor_y = unpack(split(anchors[anchor]))
					local odx, ody = abs(anchor_x - x), abs(anchor_y - y)
					repeat
						local dir_x, dir_y = sgn(anchor_x - x), sgn(anchor_y - y)
						if abs(anchor_x - x) > 2 then
							dx = odx * dir_x * dt * 2
						else
							x = anchor_x
						end
						if abs(anchor_y - y) > 2 then
							dy = ody * dir_y * dt * 2
						else
							y = anchor_y
						end
						yield()
					until abs(anchor_x - x) == 0 and abs(anchor_y - y) == 0
					if (x == anchor_x and y == anchor_y) pattern = patterns[1]
					yield()
				end
			end),
		}
		x, y, pattern, health, flames = 90, 90, patterns[1], 3, {}
	end,
	update = function(self)
		local _ENV = self
		sprite_n = (timer and timer < 0.5) and 63 or 62
		if (health <= 0) self:die()
		dx, dy = 0, 0
		frozen = max(0, boss_fight and frozen - dt or 0)
		for i = #flames, 30 do
			add(flames, particle{
				x + 4 + rnd(split"-2,-1,0,1,2"),
				y + 4 + rnd(split"-4,-3,-2,-1,0"),
				rnd(split"3,4,5,6"),
				rnd(split"0,1,1"),
			})
		end
		for flame in all(flames) do
			flame:update(flames)
		end
		if (frozen == 0) coresume(pattern, self)
		x += dx
		y += dy
		if (frozen == 0) dir = x < pc.x
	end,
	draw_sprite = function(self)
		local _ENV = self
		local is_frozen = frozen > 0
		if (not is_frozen) then
			for flame in all(flames) do
				flame:draw()
			end
		end
		if (is_frozen) pal(13, 12)
		spr(sprite_n, x, y, 1, 1, dir)
		pal(13, 13)
	end,
}

local spawnpoint = class{
	init = function(self)
		local _ENV = self
		active_units = {}
		target = pc
		x, y = unpack(self)
	end,
	spawn = function(self)
		local _ENV = self
		local creator, unit = self, unit_type{
			x = x,
			y = y,
			target = target,
			anchor = {},
		}
		function unit.die(self, reset)
			del(foreground, self)
			del(creator.active_units, self)
			if (not reset) creator.timeout = 5
		end
		add(active_units, unit)
		add(foreground, unit)
	end,
	update = function(self, layer)
		local _ENV = self
		local n, no_units = sprite_n, #active_units < 1
		if #active_units < 1 then
			if (not timeout) then
				self:spawn()
			else
				timeout = max(0, timeout - dt)
				timeout = timeout > 0 and timeout
			end
		end
		function self.draw(self)
			if (not timeout) palt(2, true)
			spr(n, self.x, self.y)
			palt(2, false)
		end
	end,
}

local ratspawn = spawnpoint{
	unit_type = rat,
	sprite_n = 43,
}

local batspawn = spawnpoint{
	unit_type = bat,
	update = function(self, layer)
		local _ENV = self
		if #active_units < 1 then
			if ((not same_screen(y, target.y)) or abs(x - target.x) > 128) self:spawn(layer)
		end
	end,
}

local goblin = actor{
	type = "goblin",
	anim_state = {
		{
			speed = 1, -- 1 - idle
			split"16,32",
			split"16,32",
			split"16,32",
			split"29,32"
		},
		{
			speed = 8, -- 2 - run
			split"0,48",
			split"13,48",
			split"26,48",
			split"39,48",
			split"52,48",
			split"65,48",
			split"78,48",
			split"91,48"
		},
		{ split"42,32" }, -- 3 - jump
		{ split"55,32" }, -- 4 - hurt
	},
	height = 16,
	width = 13,
}

local new_potion = actor{
	type = "potion",
	sprite = { n = 80 },
	sprites = {
		{ n = 80 },
		{ n = 81 },
		{ n = 64 },
		{ n = 81, flipy = true },
		{ n = 80, flipy = true },
		{ n = 81, flipx = true, flipy = true },
		{ n = 64, flipx = true },
		{ n = 81, flipx = true }
	},
	activate = function(self, layer)
		self:effect()
		del(layer, self)
	end,
	update = function(self, layer)
		local _ENV = self
		sprite = sprites[flr(time() * 16 % #sprites) + 1]
		dy = mid(-5, dy + 0.5, 7)

		x += dx
		y += dy

		local predictive_coords = { x = x, y = y, width = 8, height = 8, dir = dir }
		if sgn(dy) == 1 and check_ground(predictive_coords) then
			dy, y = 0, keep_the_change(y)
			self:activate(layer)
		elseif dy < 0 and check_ceiling(predictive_coords) then
			dy = 0
			y = ceil(y / 8) * 8
			self:activate(layer)
		end

		if abs(dx) > 0 and check_forward(predictive_coords, 1) then
			local fn = dir == 1 and flr or ceil
			dx = 0
			x = fn(x / 8) * 8
			self:activate(layer)
		end

		foreach(foreground, function(obj)
			if (obj.health and obj.type ~= "player") then
				local objx, objy = obj.x + obj.width / 2, obj.y + obj.height / 2
				if same_screen(objy,  y) then
					local distance = get_distance(x, y, objx, objy)
					if abs(objx - x) < 30 and distance <= (obj.width + 8) / 2 then
						self:activate(layer)
					end
				end
			end
		end)
	end,
	draw = function(self)
		local _ENV = self
		pal(12, col)
		spr(sprite.n, x, y, 1, 1, sprite.flipx, sprite.flipy)
		pal(12, 12)
	end,
}

local red_potion = new_potion{
	col = 8,
	brew_length = 2,
	speed = 2,
	volatility = 1.25,
	effect = function(self)
		local x, y = self.x + 4, self.y + 4
		for i = 1, rnd(split"10,11,12,13,14,15,16,17,18,19,20") do
			sfx"25"
			add(front, particle{
				x + rnd_range"10,5",
				y + rnd_range"10,5",
				rnd_range"10,-5",
				rnd(split"6, 5, 5, 9, 9"),
			})
		end
		for x1 = x - 10, x + 10 do
			local _x = x1 \ 8
			for y1 = y - 10, y + 10 do
				local _y = y1 \ 8
				if fget(mget(_x, _y), 5) then
					mset(_x, _y, 0)
					add(background, chunks{ x = _x * 8 + 4, y = _y * 8 + 4 })
				end
			end
		end
		foreach(foreground, function(obj)
			if obj.health then
				local objx, objy = obj.x + obj.width / 2, obj.y + obj.height / 2
				local distance = get_distance(x, y, objx, objy)
				if same_screen(y, objy) and abs(objx - x) < 50 and distance <= 20 then -- magic number
					obj:hurt{ x = self.x }
				end
			end
		end)
	end,
	pop_effect = function(self, p)
		sfx"25"
		p:hurt()
	end,
}

local blue_potion = new_potion{
	col = 12,
	brew_length = 4,
	speed = 1.5,
	volatility = 1.1,
	effect = function(self)
		local x, y = self.x, self.y
		sfx"26"
		add(front, sparkle{
			x = x,
			y = y,
			init = function(self)
				for i = 1, 50 do
					add(self.sparks, {
						x = self.x + rnd_range"10,5",
						y = self.y + rnd_range"10,5",
						dx = rnd_range"15,10",
						dy = rnd_range"15,10",
						col = rnd(split"6, 7, 12"),
						t = 50,
					})
				end
			end,
		})
		foreach(foreground, function(obj)
			if obj.health then
				local objx, objy = obj.x + obj.width / 2, obj.y + obj.height / 2
				local distance = get_distance(x, y, objx, objy)
				if (same_screen(y, objy) and abs(objx - x) < 50) then
					if obj.type == "lava" then
						if (distance <= 20) obj:freeze()
					else
						if (distance <= 20) obj.frozen += 3
					end
				end
			end
		end)
	end,
	pop_effect = function(self, p)
		sfx"26"
		p.frozen += 3
	end,
}

local new_bubble = class{
	level = 0,
	speed = 1,
	pop = function(self)
		add(front, sparkle{
			x = pc.x + 6,
			y = pc.y - 5,
			col = self.col
		})
		cam.shake_level = 0
		self.potion:pop_effect(pc)
		pc.potion_timeout = true
		flash = 2 -- it's a global
	end,
	charge = function(self)
		self.level += dt * 2 * self.speed
		if (cam.shake_level == 0) cam.shake_level = 1
		cam.shake_level *= self.volatility
		self.charging = true
		if (stat(18) ~= 23) sfx"23,2"
	end,
	remove = function(self, layer)
		del(layer, self)
		pc.bubble = false
	end,
	update = function(self, layer)
		local potion, _ENV = pc.potions[pc.potion_recipe], self
		x = pc.x + 6
		y = pc.y - 5
		if potion then
			if not charging then
				if flr(level) < potion.brew_length then
					if (stat(18) == 23) sfx(-1, 2)
					self:remove(layer)
				else
					sfx"24"
					pc:add_potion(col)
					self:remove(layer)
				end
			end
		end
		if level <= 0 then
			self:remove(layer)
		elseif flr(level) > potion.brew_length then
			self:pop()
			self:remove(layer)
		end
	end,
	draw = function(self)
		local _ENV = self
		circfill(x, y, level, col)
	end,
}

local player = goblin{
	type = "player",
	max_health = 4,
	health = 4,
	invuln = 0,
	accx = 15,
	max_speed = 2.5,
	jump_height = 0,
	jump_max = 0.3,
	throw_charge = 0,
	potion = false,
	potions = {},
	init = function(self) self:set_anim"1" end,
	draw_hud = noop,
	hurt = function(self, o)
		local _ENV = self
		o = o or {}
		dx = o.dx or 5 * (o.x and sgn(x - o.x) or dir * -1)
		dy = (o.dy or -3)
		health -= 1
		invuln += 1
		frozen = 0
		recoil = true
		self:set_anim"4"
		if (o.dir) dir = o.dir
		sfx"21"
	end,
	die = function(self)
		local checkpoint = split(last_checkpoint)
		deaths += 1
		local _ENV = self
		dx, dy, health, invuln, potion, throw_charge, frozen, x, y = 0, 0, max_health, 1, nil, 0, 0, unpack(checkpoint)
		cam:attach(self)
		sfx"21"
		for enemy in all(foreground) do
			if enemy.type == "enemy" then
				enemy:die(true)
			end
		end
		if not _G.boss_dead then
			_G.boss_fight = false
			music(1)
			add(foreground, demilich())
		end
	end,
	add_potion = function(self)
		self.potion = self.potions[self.potion_recipe]
	end,
	throw_potion = function(self)
		local _ENV = self
		local pot = potion{
			x = x + 4,
			y = y,
			dx = mid(0, abs(throw_charge), 5) * dir,
			dy = -4,
			dir = dir,
		}
		potion = false
		add(front, pot)
		sfx"27"
	end,
	update = function(self)
		local _ENV = self
		if (health <= 0) self:die()
		local is_frozen, old_x = frozen > 0, x
		local left, right, up, down, jump, throw = btn(0) and not is_frozen, btn(1) and not is_frozen,  btnp(2), btnp(3), btn(4) and not is_frozen, btn(5)
		grounded, anim, sprite_n, potion_recipe = self:check_ground(), anim or anim_state.idle, sprite_n or {}, potion_recipe
		if (not jump) jump_timeout = false

		if not recoil then
			if (left) dx -= accx * dt
			if (right) dx += accx * dt
			if (dx ~= 0) dir = sgn(dx)
		end

		if not grounded then
			if jumping then
				if not jump and dy < 0 and jump_height < jump_max then
					jumping = false
					jump_height = 0
					dy /= 2
				elseif jump and jump_height < jump_max then
					jump_height = min(jump_height + dt, jump_max)
				elseif jump and jump_height == jump_max then
					jumping = false
				end
			end
			if (not recoil) self:set_anim"3"
			dy += 0.5 -- gravity
		elseif jump and not jump_timeout then
			jumping = true
			jump_timeout = true
			dy -= 5
			self:set_anim"3"
			sfx"19,0"
		else
			if not (left or right) then
				dx *= (is_frozen and 0.94 or 0.8) -- slide if frozen while running
				if (abs(dx) < 0.1) dx = 0
			end
		end

		dx = mid(-max_speed, dx, max_speed)
		local fn = dx >= 0 and flr or ceil


		x += fn(dx)
		dy = mid(-5, dy, 5)
		y += dy

		local predictive_coords = { x = x + 1, y = y , width = 11, height = 16 }
		-- local predictive_coords = { x = x + 1, y = y , width = width - 2, height = height }

		if check_terrain(predictive_coords, 3) then
		-- if self.check_spikes{ x = x, y = y, width = width - 1, height = height } then
			if (invuln == 0) self:hurt()
		end

		if sgn(dy) == 1 and check_ground(predictive_coords) then -- shave a pixel on either side to prevent climbing

			jump_height = 0
			jumping = 0
			grounded = true
			local in_water = check_terrain(predictive_coords, 4)

			if (recoil) dx = 0
			recoil = false
			y = keep_the_change(y)
			if dy > 0 and not in_water then
				local num = rnd(split"2,3")
				add(background, particle{
					x + 6.5,
					-- x = x + self.width / 2,
					ceil((y + 16) / 8) * 8 - 3 + num,
					num,
					13
				 })
				sfx"20"
			elseif dy > 0 and in_water then
				sfx"29"
			end

			dy = 0
		elseif dy < 0 and check_ceiling(predictive_coords) then
			jumping = false
			sfx"22"
			dy = 0
			y = ceil(y / 8) * 8
			if (grounded) sfx(-1, 0)
		end

		-- overwrite predictive_coords
		predictive_coords = { x = x, y = y, width = 13, height = 16, dir = dir, recoil = recoil and sgn(x - old_x) ~= dir }

		if check_terrain(predictive_coords, 7) then
			self:die()
			-- return self:update()
		end

		if (check_forward(predictive_coords, 6)) then
			local gate_no = x \ 8 + (sgn(dx) > 0 and 2 or 0)
			local gate = gateways[gate_no]
			if (gate and not (gate_no == 4 and (boss_fight or boss_dead))) return gate()-- breaking out with return
		end
	
		if abs(dx) > 0 and check_forward(predictive_coords, 1) then
			local dir = dir
			if (recoil) dir *= -1 -- facing one dir traveling another
			local fn = dir == 1 and flr or ceil
			local offset do
				if recoil and sgn(x - old_x) ~= dir then
					offset = dir == 1 and 8 or -6
				else
					offset = dir == -1 and 0 or 3
					-- offset = width / -8 % 1 * 8 -- (3)
				end
			end
			dx = 0
			x = fn(x / 8) * 8 + offset
		end

		if grounded and dy >= 0 then
			self:set_anim((abs(dx) > 0.5 and x ~= old_x) and "2" or "1")
		end

		if #potions == 2 and not (bubble or potion) then
			if up then
				potion_recipe += 1
				if (potion_recipe > #potions) potion_recipe = 1
				sfx"28"
			elseif down then
				potion_recipe -= 1
				if (potion_recipe < 1) potion_recipe = #potions
				sfx"28"
			end
		end

		if throw and not (recoil or is_frozen) then
			if potion then
				throw_charge = mid(0, throw_charge + dt * 10, 10)
			elseif potion_recipe then
				if bubble then
					bubble:charge()
				elseif not potion_timeout then
					local potion = potions[potion_recipe]
					local b = new_bubble{
						x = x + 6,
						y = y - 5,
						speed = potion.speed,
						volatility = potion.volatility,
						p = self,
						potion = potion,
						col = potion.col
					}
					bubble = b
					add(front, b)
					b:charge()
				end
			end
		elseif potion_timeout then
			potion_timeout = false
		elseif throw_charge > 0 then
			self:throw_potion()
			throw_charge = 0
		elseif bubble then
			bubble.charging = false
			cam.shake_level = 0
		end

		if not is_frozen then
			sprite_n = anim[flr(time() * (anim.speed or 1) % #anim) + 1]
		end

		frozen = max(0, frozen - dt)

		draw_sprite = function(self)
			if (self.frozen > 0) pal{[0] = 1, unpack(split"1,13,12")}
			sspr(unpack{ sprite_n[1], sprite_n[2], 13, 16, x, y, 13, 16, dir == -1 })
			pal{[0] = 0, unpack(split"1,2,3")}
		end

		if invuln > 0 then
			invuln = max(0, invuln - dt)
			if ((flr(time() * 24 % 24) + 1) % 4 == 0) draw_sprite = noop
		end

		do
			local has_potion = potion_recipe and potions[potion_recipe] or nil
			local amount = "\88" .. (potion and "1" or "0")

			function draw_hud(self)
				local camx, mx, camy, my = cam.x, cam.mx, cam.y, cam.my
				local heart_x, heart_y = camx + mx, camy + my

				for i = 1, max_health do
					if (i > health) palt(8, true)
					spr(65, heart_x + 9 * (i - 1), heart_y)
				end
				palt(8, false)

				if potion_recipe then
					pal{ [12] = (has_potion and has_potion.col), [13] = 1 }
					spr(80, camx + mx + 110, heart_y)
					pal(split"1,2,3,4,5,6,7,8,9,10,11,12,13")
					if potion_recipe then
						print(amount, camx + mx + 120, heart_y + 2, (potion and 7 or 1))
					end
				end
			end
		end
	end,
	draw = function(self)
		local x1, y1 = cam.x + cam.mx, cam.y + cam.my
		rectfill(x1, y1, x1 + 127, y1 + 8, 0)
		self:draw_sprite()
		self:draw_hud()
	end,
}

local dialog = class{
	sprite_x = 69,
	sprite_y = 32,
	w = 16,
	h = 16,
	mouth = 4,
	mouths = split"32,34,36,38,40",
	mouth_x = 85,
	open_mouths = "2,3,5",
	timeout = 0,
	voice = "33,34,35",
	display_message = "",
	callback = noop,
	init = function(self)
		self.init = function(self)
			local _ENV = self
			local coro = cocreate(_update)
			x1 = cam.x + cam.mx
			x2 = x1 + 127
			y1 = cam.y + cam.my + 127
			y2 = y1 + 20
			update = function(self)
				return coresume(coro, self)
			end
		end
	end,
	_update = function(self)
		local _ENV = self
		yield()
		repeat
			x1 = cam.x + cam.mx
			x2 = x1 + 127
			y1 = max(y1 - (y1 - (cam.y + cam.my + 105)) * 0.2, cam.y + cam.my + 105)
			y2 = y1 + 22
			yield()
		until flr(y1) == cam.y + cam.my + 105 or btnp(4)
		y1 = cam.y + cam.my + 105
		y2 = y1 + 22
		yield()
		local i, last_mouth = 1
		repeat
			if timeout > 0 then
				timeout = max(timeout - dt, 0)
			else
				local c, silent = sub(message, i, i)
				display_message ..= c
				for char in all(split(" ,.'!?\0a", "")) do
					if (c == char) silent = true
					mouth = 4
				end
				if not silent then
					local diff_mouths = split(open_mouths)
					del(diff_mouths, last_mouth)
					timeout = 0.05
					sfx(rnd(split(voice)))
					last_mouth = rnd(diff_mouths)
					mouth = last_mouth
				end
				i += 1
			end
			yield()
		until i > #message or btnp(4)
		if #message > 0 then
			display_message ..= sub(message, i)
			mouth = 4
			yield()
		end
		repeat yield() until btnp(4)
		return callback()
	end,
	draw_sprite = function(self)
		local _ENV = self
		sspr(sprite_x, sprite_y, w, h, x1 + 3, y1 + 3)
	end,
	draw_mouth = function(self)
		local _ENV = self
		local x, y = mouth_x, mouths[mouth]
		sspr(x, y, 4, 2, x1 + 9, y1 + 14)
	end,
	draw = function(self)
		local _ENV = self
		rectfill(x1, y1, x2, y2, 0)
		rect(x1, y1, x2, y2, 13)
		self:draw_sprite()
		self:draw_mouth()
		print(display_message, x1 + 20, y1 + 3, 13)
	end,
}

function goober_dialog(message, callback)
	return dialog{ message = message, callback = callback }
end

local function browngob_dialog(message)
	return dialog{
		message = message,
		draw_sprite = function(self)
			local _ENV = self
			pal(3, 5)
			sspr(sprite_x, sprite_y, w, h, x1 + 3, y1 + 3)
			pal(3, 3)
		end,
	}
end

function demilich_dialog(message, callback)
	return dialog{
		message = message,
		callback = callback,
		sprite_x = 104,
		sprite_y = 48,
		w = 13,
		h = 16,
		voice = "55,56,57,58",
		mouths = split"48,50,52,54",
		mouth_x = 117,
		open_mouths = "1,2,3",
		draw_mouth = function(self)
			local _ENV = self
			sspr(mouth_x, mouths[mouth], 4, 2, x1 + 10, y1 + 14)
		end,
	}
end

new_scene = class{
	callback = noop,
	init = function(self)
		self.init = function(self)
			_upd = function()
				self:update()
			end
			_drw = function()
				game_draw()
				self:draw()
			end
		end
	end,
	update = function(self)
		local _ENV = self
		if active_message then
			if (not active_message:update()) active_message = nil
		elseif #messages > 0 then
			active_message = messages[1]
			deli(messages, 1)
		else
			callback()
			_G._upd = game_update
			_G._drw = game_draw
		end
	end,
	draw = function(self)
		if (self.active_message) self.active_message:draw()
	end
}

local function new_title()
	local function draw_logo(y)
		for i = 0, 5 do
			spr(split"77,78,78,79,93,94"[i + 1], 30 + 8 * i, y)
		end
		sspr(125, 48, 3, 3, 78, y)
		spr(95, 81, y)
		print("in the mix", 40, y + 12, 13)
	end

	local function draw_potion_bg()
		pal(split"1,2,3,4,5,6,0,8,9,10,11,1,1")
		for i = 0, 7 do
			for j = -15, 15 do
				spr(80, 16 * i, 16 * j + time() % 16 * 8 * (i % 2 == 0 and -1 or 1))
			end
		end
		pal(split"1,2,3,4,5,6,7,8,9,10,11,12,13")
	end

	return cocreate(function()
		-- init
		local y, t = -8, 0
		music(1)
		yield()
		palt(0, false)
		palt(14, true)
		yield()
		repeat
			y = min(y + (41 - y) * .1, 40)
			if (btnp(4) or btnp(5)) y = 40
			yield()
			draw_potion_bg(-28, -28)
			draw_logo(y)
			yield()
		until y == 40
		repeat
			yield()
			draw_potion_bg()
			draw_logo(y)
			t += dt
			print("press \x8e to begin", 26, 84, 3)
			yield()
		until btnp(4)
		_upd = game_update
		yield()
		_drw = game_draw
	end)
end

title_update = function()
	coresume(title)
end

title_draw = function()
	cls()
	coresume(title)
end

game_update = function()
	menuitem(1, "die", function()
		pc:die()
		sfx"21"
	end)
	game_time += dt
	flash = max(0, flash - dt * 30)
	ui:update()
	cam:update()
end

game_draw = function()
	if flash == 0 then
		cls()
		palt(0, false)
		palt(14, true)
		cam:draw()
		map(unpack(split"0,0,0,0,256,64"))
		ui:draw()
	else
		cls(13)
	end
end

win_update = function()
	if type(game_time) == "number" then
		local str, h, m, s = "", game_time \ 3600
		s = game_time - h * 3600
		m = s \ 60
		s = s - m * 60
		if (h > 0) str ..= h .. "\x48" -- puny h
		if (m > 0) str ..= m .. "\x4d" -- puny m
		if (s > 0) str ..= flr(s) .. "\x53" -- puny s
		game_time = str
	end
	if (btnp(4) or btnp(5)) run()
end

win_draw = function()
	local str, letters = "", split("congratulations!", "")
	cls()
	camera(0, 0)
	palt(14, true)
	for i = 0, 255 do
		pal(split"1,2,3,4,3")
		spr(6, i * 8 - t() * 24 % 128, 119)
		pal(split"1,2,3,4,5")
	end
	sspr(split"0,13,26,39,52,65,78,91"[flr(t() * 12 % 8) + 1], 48, 13, 16, 56, 103)
	for i = 1, #letters do
		print(letters[i], center"congratulations!" + 4 * (i - 1), 32 + sin(t() + i * (1 / #letters)) * 1.5, rnd(split"9,10,11,12,13,14"))
	end
	-- print("congratulations!", center"congratulations" - 2, 32, rnd(split"9,10,11,12,13,14"))
	print("you escaped the caverns", center"you escaped the caverns", 48, 13)
	str = "time: " .. game_time
	print(str, center(str), 64, 9)
	print("time:", 6)
	print("deaths: " .. deaths, center("deaths: " .. deaths), 80, 9)
	print("deaths:", 6)
end

function _init()
	camera(0, 0)
	ui = new_ui()
	title, last_checkpoint, flash, deaths, game_time, time_now, background, foreground, front, immediate = new_title(), "16,208", 0, 0, 0, 0, unpack(ui.layers)

	pc = player{
		x = 16,
		y = 208,
	}
	add(foreground, pc)
	cam:attach(pc)
	-- entrance
	add(background, actor{ -- goblin boss
		x = 160,
		y = 232,
		active = true,
		update = function(self)
			if self.active then
				if same_screen(pc.y, self.y) and abs(pc.x - self.x) < 20 and pc.grounded then
					pc.dx = 0
					return new_scene{
						messages = {
							browngob_dialog"goober. there you are",
							goober_dialog"hey boss",
							browngob_dialog"we're getting reports of\x0astrange activity inside\x0athe cave",
							browngob_dialog"go down there and\x0ainvestigate",
							goober_dialog"it's not dangerous in\x0athere is it?",
							browngob_dialog"...",
							goober_dialog"...",
							browngob_dialog"ok. goodluck!"
						},
						callback = function()
							self.active = false
							for i = 0, 3 do
								mset(22, 27 + i, 0)
							end
							cam.shake_level = 1
						end,
					}
				end
			end
		end,
		draw = function(self)
			pal(3, 5)
			sspr(16, 32, 13, 16, self.x, self.y, 13, 16, true)
			pal(3, 3)
		end,
	})
	for coords in all(split("48,184;120,184;264,56;648,48;960,56;288,184;104,320", ";")) do
		add(background, torch(split(coords)))
	end
	for coords in all(split("704,112;790,240;408,240;800,368;440,496", ";")) do
		add(background, ratspawn(split(coords)))
	end
	add(background, ratspawn{ unit_type = rat{ max_stamina = 1.93 }, 720, 368 })
	add(background, batspawn(split"532,144"))
	add(background, batspawn{ unit_type = bat{ accy = 6, sight_range_y = 40 }, 800, 272 })
	add(background, batspawn{ unit_type = bat{ accy = 6, sight_range_y = 30 }, 608, 272 })
	add(background, batspawn{ unit_type = bat{ accy = 9 }, 552, 296 })
	add(background, batspawn{ unit_type = bat{ accy = 7.5 }, 776, 440 })
	add(foreground, demilich{ x = 90, y = 90 })
	add(background, treasure_chest{
		x = 952,
		y = 232,
		callback = function()
			local star = class{
				draw = function()
					cls()
					pc:draw()
					spr(50, pc.x + 4, pc.y - 10)
				end
			}
			return new_scene{
				messages = {
					goober_dialog("this must be the star\x0abonehead was talking about", function()
						add(front, star)
					end),
					goober_dialog("i don't know what it does\x0abut maybe it can at least\x0ahelp me get out of here", function()
						del(front, star)
						has_star = true
						last_checkpoint = "952,224"
					end)
				}
			}
		end,
	}) -- star
	add(background, treasure_chest{ -- blue potion
		x = 48,
		y = 360,
		flip = true,
		callback = function()
			local demonstration = class{
				draw = function()
					cls()
					pc:draw()
					circfill(pc.x + 8, pc.y - 8, 4, 12)
				end
			}
			pc.potion_recipe = 1
			last_checkpoint = "48,352"
			add(pc.potions, blue_potion)
			return new_scene{
				messages = {
					goober_dialog"there's a scroll inside!",
					goober_dialog"it shows how to make\x0aice potions",
					goober_dialog"it describes the process\x0aas slow and steady like\x0aglacial ice",
					goober_dialog("i need to gather the right\x0aamount of energy. less\x0awill fail, more will burst", function()
						add(immediate, demonstration)
					end),
					goober_dialog("there! i need to summon\x0athis much! i should\x0aremember how it looks!", function() del(immediate, demonstration) end),
					goober_dialog"this will chill enemies.\x0ait might even cool hot\x0asurfaces for a while",
				}
			}
		end,
	})
	add(background, treasure_chest{ -- red potion
		x = 24,
		y = 480,
		flip = true,
		callback = function()
			local demonstration = class{
				draw = function()
					cls()
					pc:draw()
					circfill(pc.x + 8, pc.y - 8, 2, 8)
				end
			}
			pc.potion_recipe = 2
			last_checkpoint = "24,472"
			add(pc.potions, red_potion)
			return new_scene{
				messages = {
					goober_dialog"there's a scroll inside!",
					goober_dialog"it shows how to make\x0aexplosive potions",
					goober_dialog"it describes the process\x0aas harsh and fast like a\x0aflash of flame",
					goober_dialog("i need to gather the right\x0aamount of energy. less\x0awill fail, more will burst", function()
						add(immediate, demonstration)
					end),
					goober_dialog("there! i need to summon\x0athis much! i should\x0aremember how it looks!", function() del(immediate, demonstration) end),
					goober_dialog"these will make short work\x0aof dungeon pests. it might\x0aeven break some weak walls",
				}
			}
		end,
	})
	add(front, class{
		-- water in front of player
		draw = function()
			if (pc.y \ 128 == 2) rectfill(unpack(split"8,380,103,383,1"))
		end
	})
	for coords in all(split("68,368;76,368;24,368;32,360;40,312;48,312",";")) do
		add(background, water_generator(split(coords)))
	end
	add(background, shrine{ x = 928, y = 352 })
	for x in all(split"12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,32,33,34,35,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,83,84,85,86,87,88,89,102,103,104,105,106,107,108,109,110,111,112,113") do
		add(foreground, lavatile{ _x = x, _y = 63 })
	end
	_upd, _drw = title_update, title_draw
end

function _update()
	old_time = time_now
	time_now = time()
	dt = time_now - old_time
	menuitem(1)
	_upd()
end

function _draw()
	_drw()
end
