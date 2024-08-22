script_name("Auto Welcome Back")
script_authors("Neutrinou")
script_version("0.0.1")

require "moonloader"
require "sampfuncs"
local sampev = require "lib.samp.events"

local inicfg = require "inicfg"

local greetings = {
    "Welcome back",
    "Welcome back %s",
    "wb",
    "wb %s",
    "Hello",
    "Hello %s",
    "Hi",
    "Hi %s",
    -- "Konichiwa",
    -- "Konichiwa %s",
    "Hiyya",
    "Hiyya %s",
}

-- Cache for logged out users time
local logged_out = {}

local config

local config_dir_path = getWorkingDirectory() .. "\\config\\"
if not doesDirectoryExist(config_dir_path) then createDirectory(config_dir_path) end
local config_file_path = config_dir_path .. "autowb.ini"
config_dir_path = nil

local function saveConfig()
    if not inicfg.save(config, config_file_path) then
        sampAddChatMessage("{E02222}OBS Record: {FFFFFF}Unable to write configuration file.", 0xFFFFFF)
    end
end

local function loadConfig()
    if doesFileExist(config_file_path) then
        config = inicfg.load(nil, config_file_path)

        if not type(config.AutoWelcomeBack.enabled) == "boolean" then config.AutoWelcomeBack.enabled = true end
        if not type(config.AutoWelcomeBack.cooldown) == "int" then config.OBS.cooldown = 300 end
    else
        local new_config = io.open(config_file_path, "w")
        new_config:close()
        new_config = nil

        config = {
            AutoWelcomeBack = {
                enabled = true,
                cooldown = 300
            }
        }
    end

    saveConfig()
end

loadConfig()

function cmd_autowb_toogle()
    config.AutoWelcomeBack.enabled = not config.AutoWelcomeBack.enabled
    if config.AutoWelcomeBack.enabled then
        sampAddChatMessage("{FFFFFF}Auto welcome back: {008000}ON", -1)
    else
        sampAddChatMessage("{FFFFFF}Auto welcome back: {800000}OFF", -1)
    end
end

function build_wb_message(name)
    local firstnameonly = (math.random(2) == 2)
    greeting_selection = math.random(#greetings)

    if firstnameonly then
        name = name:match("^([%w]+)")
    end

    local message = string.format(greetings[greeting_selection], name)
    return message
end

function cmd_autowb_help()
    sampAddChatMessage("{009000}Auto welcome back by {E84393}Laura A. Yamaguchi", -1)
    sampAddChatMessage("{FFFFFF}Based on the Auto welcome back by {FD79A8}Akagami Y. Sumiyoshi", -1)
    sampAddChatMessage("{FFFFFF}Available commands:", -1)
    sampAddChatMessage("{74B9FF}/autowb: {FFFFFF}toogle auto welcome back (enable or disable). Default: enabled", -1)
    sampAddChatMessage("{74B9FF}/autowbhelp: {FFFFFF}show this help message", -1)
end

function main()
    repeat wait(50) until isSampAvailable()
    repeat wait(50) until string.find(sampGetCurrentServerName(), "Horizon Roleplay")

    sampAddChatMessage("Auto welcome back. {74B9FF}/autowbhelp {FFFFFF}for commands list", 0xFFFFFF)

    sampRegisterChatCommand("autowb", cmd_autowb_toogle)
    sampRegisterChatCommand("autowbhelp", cmd_autowb_help)
end

function sampev.onServerMessage(c, text)
    if not config.AutoWelcomeBack.enabled then
        return
    end

    local message = text
    local name = message:match("^%*%*%* (.-) from your family has logged in%.$")
    
    if name then
        if logged_out[name] ~= nil then
            if (logged_out[name] + config.AutoWelcomeBack.cooldown) > os.time() then
                -- Don't welcome back because still on cooldown
                return
            end
        end

        local greeting_message = build_wb_message(name)
        
        lua_thread.create(function()
            wait(5000)
            sampSendChat("/f " .. greeting_message)
        end)
    end

    local name = message:match("^%*%*%* (.-) from your family has disconnected %(.-%)%.$")
    if name then
        logged_out[name] = os.time()
    end
end
