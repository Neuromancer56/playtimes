-- Define a table to store players' playtime
local playtime_data = {}

-- Function to initialize playtime for a player
local function init_playtime(player_name)
    if not playtime_data[player_name] then
        playtime_data[player_name] = {
            total_playtime = 0,
            last_login = os.time()
        }
    end
end

-- Function to update playtime for a player
local function update_playtime(player, dtime)
    local player_name = player:get_player_name()
    if player_name then
        init_playtime(player_name)
        playtime_data[player_name].total_playtime = playtime_data[player_name].total_playtime + dtime/1000
    end
end

-- Register callback to update playtime every 30 seconds
minetest.register_globalstep(function(dtime)
    local timer = 30 -- Update every 30 seconds
    for _, player in ipairs(minetest.get_connected_players()) do
        update_playtime(player, timer)
    end
end)

-- Function to handle /playtimes command
minetest.register_chatcommand("playtimes", {
    params = "",
    description = "Displays playtimes for all players",
    privs = {},
    func = function(name, param)
        local output = "Playtimes:\n"
        for player_name, data in pairs(playtime_data) do
            local total_seconds = math.floor(data.total_playtime)
            local hours = math.floor(total_seconds / 3600)
            local minutes = math.floor((total_seconds % 3600) / 60)
            local seconds = total_seconds % 60
            output = output .. player_name .. ": " .. hours .. " hours, " .. minutes .. " minutes, " .. seconds .. " seconds\n"
        end
        minetest.chat_send_player(name, output)
    end,
})

-- Load playtime data on server startup
local playtime_file = minetest.get_worldpath().."/playtime_data.json"
local file = io.open(playtime_file, "r")
if file then
    local content = file:read("*all")
    playtime_data = minetest.parse_json(content) or {}
    file:close()
end

-- Save playtime data on server shutdown
minetest.register_on_shutdown(function()
    local file = io.open(playtime_file, "w")
    if file then
        file:write(minetest.write_json(playtime_data))
        file:close()
    end
end)
