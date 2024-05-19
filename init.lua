-- Define a table to store players' playtime
local playtime_data = {}

-- Function to initialize or update playtime for a player
local function init_playtime(player_name)
    if not playtime_data[player_name] then
        playtime_data[player_name] = {
            total_playtime = 0,
            last_login = os.time()
        }
    else
        playtime_data[player_name].last_login = os.time()
    end
end

-- Function to update playtime for a player
local function update_playtime(player, elapsed_time)
    local player_name = player:get_player_name()
    if player_name then
        init_playtime(player_name)
        playtime_data[player_name].total_playtime = playtime_data[player_name].total_playtime + elapsed_time
    end
end

-- Register callback to update playtime every update_interval seconds
local update_interval = 7 -- Update every update_interval seconds
local update_timer = 0
minetest.register_globalstep(function(dtime)
    update_timer = update_timer + dtime
    if update_timer >= update_interval then
        update_timer = 0
        for _, player in ipairs(minetest.get_connected_players()) do
            update_playtime(player, update_interval) -- Pass update_interval as the elapsed time in seconds
        end
    end
end)


-- Register callback to initialize playtime data when a player joins
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    init_playtime(player_name)
end)

-- Function to convert timestamp to date and time string
local function format_datetime(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

-- Function to handle /playtimes command
minetest.register_chatcommand("playtimes", {
    params = "[--top N] [--prefix prefix]",
    description = "Displays playtimes for players",
    privs = {},
    func = function(name, param)
        local top_count = tonumber(param:match("%-t%s*(%d+)")) or 0
        if top_count <= 0 then
            top_count = nil
        end
        
        local prefix = param:match("%-p%s*(%a+)")
        
        local output = "Playtimes:\n"
        
        -- Sort playtime data by total_playtime
        local sorted_players = {}
        for player_name, data in pairs(playtime_data) do
            if not prefix or player_name:lower():sub(1, #prefix) == prefix:lower() then
                table.insert(sorted_players, {name = player_name, playtime = data.total_playtime, last_login = data.last_login})
            end
        end
        table.sort(sorted_players, function(a, b) return a.playtime > b.playtime end)
        
        -- Display top N players or all players if N is not specified
        local count = 0
        for _, player_info in ipairs(sorted_players) do
            local total_seconds = math.floor(player_info.playtime)
            local hours = math.floor(total_seconds / 3600)
            local minutes = math.floor((total_seconds % 3600) / 60)
            local seconds = total_seconds % 60
            local last_login_str = format_datetime(player_info.last_login)
            output = output .. player_info.name .. ": " .. hours .. " hours, " .. minutes .. " minutes, " .. seconds .. " seconds; Last login: " .. last_login_str .. "\n"
            count = count + 1
            if top_count and count >= top_count then
                break
            end
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

-- Save playtime data every 20 minutes
local save_interval = 1200 -- Save every 1200 seconds (20 minutes)
local save_timer = 0
minetest.register_globalstep(function(dtime)
    save_timer = save_timer + dtime
    if save_timer >= save_interval then
        save_timer = 0
        local file = io.open(playtime_file, "w")
        if file then
            file:write(minetest.write_json(playtime_data))
            file:close()
        end
    end
end)
