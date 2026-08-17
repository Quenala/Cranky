--[[

Copyright © 2025, Quenala of Asura
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright
	  notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright
	  notice, this list of conditions and the following disclaimer in the
	  documentation and/or other materials provided with the distribution.
	* Neither the name of Cranky nor the
	  names of its contributors may be used to endorse or promote products
	  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL QUENALA BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]

_addon.name = 'Cranky'
_addon.author = 'Quenala'
_addon.version = '2.0'
_addon.commands = {'cranky'}

packets = require('packets')
res = require('resources')
texts = require('texts')
config = require('config')

-- === Defaults ===
local defaults = {
	pos = {x = 150, y = 300},
	bg = {alpha = 128,visible = false},
	flags = {right = false, bottom = false, draggable = true, blod = true},
	text = {
		size = 11,
		font = 'Consolas',
		stroke = {
			width = 4, 
			alpha = 255,
			red = 0,          -- black outline
			green = 0,
			blue = 0,
		},
		alpha = 255,
	},
	padding = 10,

	show_name = true,
	show_ws = true,
	show_damage = true,
	total_row = 5,
	shake = true, -- shake effect on 99999 damage
	-- Column order: any combination of 'name', 'ws', 'damage'
	column_order = {'name', 'damage', 'ws'},
}

local settings = config.load(defaults)

-- === Track WS data ===
local ws_history = {}

-- === Job cache (name -> job abbr) ===
local job_cache = {}

local function update_own_job()
	local player = windower.ffxi.get_player()
	if player and player.name and player.main_job then
		job_cache[player.name] = player.main_job
	end
end

-- Populate own job on load / login / job change
update_own_job()
windower.register_event('login', update_own_job)
windower.register_event('job change', update_own_job)

-- Cache jobs from party / character update packets
windower.register_event('incoming chunk', function(id, data)
	if id == 0x0DD then -- Party member update
		local p = packets.parse('incoming', data)
		if p and p.Name and p['Main job'] and p['Main job'] > 0 then
			local job = res.jobs[p['Main job']]
			if job then
				job_cache[p.Name] = job.ens -- short form e.g. WAR
			end
		end
	elseif id == 0x0DF then -- Character update
		local p = packets.parse('incoming', data)
		if p and p.ID and p['Main job'] and p['Main job'] > 0 then
			local mob = windower.ffxi.get_mob_by_id(p.ID)
			if mob and mob.name then
				local job = res.jobs[p['Main job']]
				if job then
					job_cache[mob.name] = job.ens
				end
			end
		end
	end
end)

-- === Text box ===
local ws_box = texts.new(settings)
ws_box:show()

local was_dragged = false
texts.register_event(ws_box, 'drag', function()
	was_dragged = true
end)

windower.register_event('mouse', function(type, x, y, delta, blocked)
	if type == 2 and was_dragged then
		settings:save('all')
		was_dragged = false
	end
end)

-- === Shake effect (triggers on 99999 damage) ===
local shake = {
	active = false,
	start_time = 0,
	duration = 1.0, -- seconds
	orig_x = 0,
	orig_y = 0,
}

local function start_shake()
	local x, y = ws_box:pos()
	shake.orig_x = x
	shake.orig_y = y
	shake.start_time = os.clock()
	shake.active = true
end

windower.register_event('prerender', function()
	if not shake.active then return end

	local elapsed = os.clock() - shake.start_time
	if elapsed >= shake.duration then
		ws_box:pos(shake.orig_x, shake.orig_y)
		shake.active = false
		return
	end

	-- Intensity fades out over the duration
	local intensity = (1 - elapsed / shake.duration) * 5
	local ox = math.sin(elapsed * 45) * intensity
	local oy = math.cos(elapsed * 38) * intensity
	ws_box:pos(shake.orig_x + ox, shake.orig_y + oy)
end)

-- === Helpers ===
local function is_party_or_alliance_member(actor_id)
	local party = windower.ffxi.get_party()
	for i = 0, 5 do
		local p = party['p' .. i]
		if p and p.id == actor_id then return true end
	end
	for i = 0, 17 do
		local a = party['a' .. i]
		if a and a.id == actor_id then return true end
	end
	return false
end

local function get_job_abbr(name)
	return job_cache[name]
end

-- Damage colour grading
-- 99999 (cap)     → Red
-- > 80 000        → Dark Orange
-- 50 001 – 80 000 → Orange
-- 20 001 – 50 000 → Yellow
-- < 20 000        → Gray
local function damage_color(dmg)
	if dmg >= 99999 then
		return 255, 0, 0 -- Red for damage cap
	elseif dmg > 80000 then
		return 255, 100, 0 -- Dark Orange
	elseif dmg > 50000 then
		return 255, 188, 0 -- Orange
	elseif dmg > 20000 then
		return 255, 255, 0 -- Yellow
	else
		return 192, 192, 192 -- Gray
	end
end

-- === WS name aliases (for compact display) ===
local ws_aliases = {
	-- Sword
	['Knights of Round'] = 'KoR',
	['Savage Blade'] = 'SB',
	['Expiacion'] = 'Expi',
	['Requiescat'] = 'Req',
	['Chant du Cygne'] = 'CdC',
	['Sanguine Blade'] = 'Sang',
	['Death Blossom'] = 'DB',
	['Atonement'] = 'Atone',
	-- Great Sword
	['Resolution'] = 'Reso',
	['Torcleaver'] = 'Torc',
	['Scourge'] = 'Scourge',
	['Ground Strike'] = 'GS',
	-- Axe / Great Axe
	['Ruinator'] = 'Ruin',
	['Decimation'] = 'Deci',
	['Cloudsplitter'] = 'Cloud',
	["Ukko's Fury"] = 'Ukko',
	["King's Justice"] = 'KJ',
	['Upheaval'] = 'Upheav',
	['Steel Cyclone'] = 'SC',
	-- Scythe
	['Entropy'] = 'Entr',
	['Insurgency'] = 'Insurg',
	['Quietus'] = 'Quiet',
	['Spiral Hell'] = 'Spiral',
	['Guillotine'] = 'Guill',
	-- Polearm
	['Stardiver'] = 'Star',
	['Impulse Drive'] = 'Imp',
	['Drakesbane'] = 'Drake',
	["Camlann's Torment"] = 'Camlann',
	-- Hand-to-Hand
	['Victory Smite'] = 'VS',
	['Shijin Spiral'] = 'Shijin',
	['Asuran Fists'] = 'Asuran',
	['Stringing Pummel'] = 'String',
	['Howling Fist'] = 'Howl',
	['Dragon Kick'] = 'DK',
	['Tornado Kick'] = 'Tornado',
	-- Dagger
	["Rudra's Storm"] = 'Rudra',
	['Evisceration'] = 'Evis',
	['Exenterator'] = 'Exent',
	['Pyrrhic Kleos'] = 'Pyrrhic',
	['Mercy Stroke'] = 'Mercy',
	['Aeolian Edge'] = 'Aeolian',
	['Mordant Rime'] = 'Mordant',
	-- Club / Staff
	['Realmrazer'] = 'Realm',
	['Black Halo'] = 'Halo',
	['Hexa Strike'] = 'Hexa',
	['Judgment'] = 'Judge',
	['Shattersoul'] = 'Shatter',
	['Retribution'] = 'Retrib',
	['Vidohunir'] = 'Vido',
	['Gate of Tartarus'] = 'GoT',
	-- Archery / Marksmanship
	["Jishnu's Radiance"] = 'Jishnu',
	['Namas Arrow'] = 'Namas',
	['Apex Arrow'] = 'Apex',
	['Last Stand'] = 'LS',
	['Trueflight'] = 'TF',
	['Wildfire'] = 'WF',
	['Leaden Salute'] = 'Leaden',
	['Coronach'] = 'Coro',
	['Detonator'] = 'Det',
}

-- Returns a short display name for the WS
local function get_ws_display_name(ws_name)
	if not ws_name then return 'Unknown' end

	-- Explicit alias first
	local alias = ws_aliases[ws_name]
	if alias then
		return alias
	end

	-- Strip "Tachi: " (Great Katana)
	if ws_name:sub(1, 7) == 'Tachi: ' then
		return ws_name:sub(8)
	end

	-- Strip "Blade: " (Katana)
	if ws_name:sub(1, 7) == 'Blade: ' then
		return ws_name:sub(8)
	end

	return ws_name
end

-- === Column widths (Consolas is monospace) ===
local NAME_WIDTH = 14 -- name + optional (JOB)
local WS_WIDTH = 10 -- weapon skill name
local DMG_WIDTH = 6 -- damage number (max 99999)

local function pad(str, width)
	str = tostring(str or '')
	if #str > width then
		return str:sub(1, width)
	end
	return str .. string.rep(' ', width - #str)
end

local function pad_left(str, width) -- right-align
	str = tostring(str or '')
	if #str > width then
		return str:sub(1, width)
	end
	return string.rep(' ', width - #str) .. str
end

-- === Update display ===
-- Respects settings.column_order (e.g. {'name','damage','ws'})
local function update_box()
	local lines = {}
	for _, ws in ipairs(ws_history) do
		local parts = {}

		for _, col in ipairs(settings.column_order) do
			if col == 'damage' and settings.show_damage then
				local r, g, b = damage_color(ws.damage)
				local dmg_str = pad_left(ws.damage, DMG_WIDTH)
				table.insert(parts, '\\cs(' .. r .. ',' .. g .. ',' .. b .. ')' .. dmg_str .. '\\cr')
			elseif col == 'name' and settings.show_name then
				local name_str
				if ws.job then
					-- Keep the job visible; trim the name if needed
					local job_part = ' (' .. ws.job .. ')'
					local max_name_len = NAME_WIDTH - #job_part
					if max_name_len < 1 then max_name_len = 1 end
					local trimmed_name = ws.name
					if #trimmed_name > max_name_len then
						trimmed_name = trimmed_name:sub(1, max_name_len)
					end
					name_str = trimmed_name .. job_part
				else
					name_str = ws.name
				end
				table.insert(parts, pad(name_str, NAME_WIDTH))
			elseif col == 'ws' and settings.show_ws then
				local display_ws = get_ws_display_name(ws.ws_name)
				table.insert(parts, '\\cs(0,255,0)' .. pad(display_ws, WS_WIDTH) .. '\\cr')
			end
		end

		-- single space between columns for compact layout
		table.insert(lines, table.concat(parts, ' '))
	end
	ws_box:text(table.concat(lines, '\n'))
end

-- === Capture WS ===
windower.register_event('action', function(act)
	if act.category == 3 and act.targets and act.param then
		local actor_id = act.actor_id
		-- if not is_party_or_alliance_member(actor_id) then return end

		local mob = windower.ffxi.get_mob_by_id(actor_id)
		if not mob then return end

		local ws_id = act.param
		local ws_name = res.weapon_skills[ws_id] and res.weapon_skills[ws_id].name or 'Unknown'

		local total_damage = 0
		for _, target in ipairs(act.targets) do
			for _, action in ipairs(target.actions) do
				if action.param then
					total_damage = total_damage + action.param
				end
			end
		end

		local entry = {
			name = mob.name,
			job = get_job_abbr(mob.name),
			ws_name = ws_name,
			damage = total_damage,
		}

		table.insert(ws_history, 1, entry)
		if #ws_history > settings.total_row then
			table.remove(ws_history)
		end

		update_box()

		-- Trigger shake on damage cap (if enabled)
		if settings.shake and total_damage >= 99999 then
			start_shake()
		end
	end
end)

-- === Commands ===
windower.register_event('addon command', function(cmd, ...)
	cmd = cmd and cmd:lower()
	local args = {...}

	if cmd == 'toggle' then
		local arg = args[1] and args[1]:lower()
		if arg == 'name' then
			settings.show_name = not settings.show_name
		elseif arg == 'ws' then
			settings.show_ws = not settings.show_ws
		elseif arg == 'damage' then
			settings.show_damage = not settings.show_damage
		else
			windower.add_to_chat(207, '[Cranky] //cranky toggle [name/ws/damage]')
			return
		end
		settings:save('all')
		update_box()
	elseif cmd == 'order' then
		-- //cranky order name damage ws
		-- //cranky order damage name ws
		local valid = {name = true, ws = true, damage = true}
		local new_order = {}
		for _, v in ipairs(args) do
			v = v:lower()
			if valid[v] then
				table.insert(new_order, v)
			end
		end
		if #new_order == 0 then
			windower.add_to_chat(207, '[Cranky] Current order: ' .. table.concat(settings.column_order, ' '))
			windower.add_to_chat(207, '[Cranky] Usage: //cranky order name damage ws')
			return
		end
		settings.column_order = new_order
		settings:save('all')
		windower.add_to_chat(207, '[Cranky] Column order set to: ' .. table.concat(new_order, ' '))
		update_box()
	elseif cmd == 'shake' then
		settings.shake = not settings.shake
		settings:save('all')
		windower.add_to_chat(207, '[Cranky] Shake effect: ' .. (settings.shake and 'ON' or 'OFF'))
	elseif cmd == 'reset' then
		ws_history = {}
		update_box()
	elseif cmd == 'rows' then
		local tempcheck = tonumber(args[1])
		if type(tempcheck) == 'number' and tempcheck >= 1 and tempcheck <= 20 then
			settings.total_row = tempcheck
			while #ws_history > settings.total_row do
				table.remove(ws_history)
			end
			settings:save('all')
			windower.add_to_chat(207, '[Cranky] Number of WS set to: ' .. settings.total_row)
			update_box()
		else
			windower.add_to_chat(207, '[Cranky] Number of WS need to be set between 1 and 20')
		end
	elseif cmd == 'size' then
		local tempcheck = tonumber(args[1])
		if type(tempcheck) == 'number' and tempcheck >= 8 and tempcheck <= 15 then
			settings.text.size = tempcheck
			ws_box:size(settings.text.size)
			settings:save('all')
			windower.add_to_chat(207, '[Cranky] Font size set to: ' .. settings.text.size)
		else
			windower.add_to_chat(207, '[Cranky] Font size need to be set between 8 and 15')
		end
	elseif cmd == 'hide' then
		ws_box:hide()
	elseif cmd == 'show' then
		ws_box:show()
	else
		windower.add_to_chat(207, '[Cranky] Commands:')
		windower.add_to_chat(207, '[Cranky] //cranky toggle [name/ws/damage]')
		windower.add_to_chat(207, '[Cranky] //cranky order name damage ws')
		windower.add_to_chat(207, '[Cranky] //cranky shake')
		windower.add_to_chat(207, '[Cranky] //cranky rows [1-20]')
		windower.add_to_chat(207, '[Cranky] //cranky size [8-15]')
		windower.add_to_chat(207, '[Cranky] //cranky reset')
		windower.add_to_chat(207, '[Cranky] //cranky show / hide')
	end
end)
