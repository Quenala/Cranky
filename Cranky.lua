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
_addon.version = '1.0'
_addon.commands = {'cranky'}

packets = require('packets')
res = require('resources')
texts = require('texts')

-- === Configurable display toggles ===
local show_name = true
local show_ws = true
local show_damage = true
local total_row = 5
local GUI_size = 11

-- === Track WS data ===
local ws_history = {}

-- === Set up text box ===
local ws_box = texts.new({
    pos = {x = 150, y = 300},
    bg = {alpha = 128},
    flags = {right = false, bottom = false, draggable = true},
    text = {size = GUI_size, font = 'Consolas', stroke = {width = 1, alpha = 255}, alpha = 255},
    padding = 10,
})

ws_box:show()

-- === Get party/alliance members ===
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


-- === Update display text ===
local function update_box()
    local lines = {}
    for _, ws in ipairs(ws_history) do
        local line = ''

        if show_name then
            line = line .. ws.name .. ' '
        end
        if show_ws then
            line = line .. '\\cs(0,255,0)' .. ws.ws_name .. '\\cr'
        end
        if show_damage then
            line = line .. ' - \\cs(255,0,0)' .. ws.damage .. '\\cr'
        end

        table.insert(lines, line)
    end
    ws_box:text(table.concat(lines, '\n'))
end

-- === Capture WS from action packets ===
windower.register_event('action', function(act)
    if act.category == 3 and act.targets and act.param then -- WS category
        local actor_id = act.actor_id
    --    if not is_party_or_alliance_member(actor_id) then return end

        local mob = windower.ffxi.get_mob_by_id(actor_id)
    --    if not mob then return end

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
            ws_name = ws_name,
            damage = total_damage,
        }

        table.insert(ws_history, 1, entry)
        if #ws_history > total_row then
            table.remove(ws_history)
        end

        update_box()
    end
end)


-- === Handle commands ===
windower.register_event('addon command', function(cmd, arg)
    cmd = cmd and cmd:lower()
    arg = arg and arg:lower()

    if cmd == 'toggle' then
        if arg == 'name' then
            show_name = not show_name
        elseif arg == 'ws' then
            show_ws = not show_ws
        elseif arg == 'damage' then
            show_damage = not show_damage
        else
            windower.add_to_chat(207, '[Cranky] //cranky toggle [name/ws/damage]')
            return
        end
        update_box()
    elseif cmd == 'reset' then
        ws_history = {}
        update_box()
	elseif cmd == 'rows' then
		tempcheck = tonumber(arg)
		if type(tempcheck) == 'number' and tempcheck >= 1 and tempcheck <= 20 then
			total_row = tonumber(arg)
			windower.add_to_chat(207, '[Cranky] Number of WS set to: '..total_row)
		else 
			windower.add_to_chat(207, '[Cranky] Number of WS need to be set between 1 and 20')
            return
		end
	elseif cmd == 'size' then
		tempcheck = tonumber(arg)
		if type(tempcheck) == 'number' and tempcheck >= 8 and tempcheck <= 15 then
			GUI_size = tonumber(arg)
			ws_box:size(GUI_size)
			windower.add_to_chat(207, '[Cranky] Font size set to: '..GUI_size)
		else 
			windower.add_to_chat(207, '[Cranky] Font size need to be set between 8 and 15')
            return
		end
    else
		windower.add_to_chat(207, '[Cranky] Commands:')
        windower.add_to_chat(207, '[Cranky] //cranky toggle [name/ws/damage]')
		windower.add_to_chat(207, '[Cranky] //cranky rows [1-20]')
		windower.add_to_chat(207, '[Cranky] //cranky size [8-15]')
		windower.add_to_chat(207, '[Cranky] //cranky reset')
    end
end) 