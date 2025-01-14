--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--

local _, ns = ...

local WCCCAD = LibStub("AceAddon-3.0"):NewAddon("WCCC Clubbing Companion", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0", "AceComm-3.0", "AceTimer-3.0")

ns.WCCCAD = WCCCAD
ns.modules = {}

local dataDefaults = 
{
    profile = 
    {

    }
}

function WCCCAD:OnInitialize()
        -- Addon is deactivated if the player is not in the WCCC.
        self.addonActive = true

        -- Custom root commands set by modules. Any args parsed to /wccc command are checked against this table.
        self.moduleCommands = {}

        -- Load database
        self.db = LibStub("AceDB-3.0"):New("WCCCDB", dataDefaults, true)

        self:RegisterComm("WCCCAD")    

        self.UI:PrintAddOnMessage("AddOn Loaded. Type /wccc for options.")
end

function WCCCAD:OnEnable()
    self:RegisterChatCommand("wccc", "WCCCCommand")
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", WCCCAD.SystemChatFilter)
end

function WCCCAD:OnDisable()
    self:UnregisterChatCommand("wccc")
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", WCCCAD.SystemChatFilter)
end

---
--- Register a slash command for a module. This is the first argument entered after "/wccc"
--- Use ModuleBase.RegisterModuleSlashCommand for convenience.
---
function WCCCAD:RegisterModuleSlashCommand(moduleObj, command, func) 
    self.moduleCommands[command] = function(args) func(moduleObj, args) end
end

---
-- Generic chat command, opens the config panel when the wccc command is entered.
--
function WCCCAD:WCCCCommand(input)
    local args = {}
    for word in input:gmatch("%w+") do 
        table.insert(args, word) 
    end

    -- Open UI if no args were passed.
    if args == nil or next(args) == nil then
        self.UI:Show()

        self:CheckAddonActive(true)
    else 
        if self:CheckAddonActive(true) == false then
            return
        end

        local moduleCmd = args[1]
        local cmdFunc = self.moduleCommands[moduleCmd]
        if cmdFunc ~= nil then
            table.remove(args, 1)
            cmdFunc(args)
        end
    end
end

---
--- Returns whether the addon is active (enabled for the current character).
--- If printMsg is true and the addon is disabled, the disabled message will be shown.
--- This is used to prevent commands if we're "disabled".
--- @param printMsg boolean @Whether to print the addon disabled message.
---
function WCCCAD:CheckAddonActive(printMsg)
    local guildName = IsInGuild() and GetGuildInfo("player") or nil
    self.addonActive = guildName == ns.utils.WCCC_GUILD_NAME

    if printMsg and not self.addonActive then
        self.UI:PrintAddonDisabledMessage() 
    end

    return self.addonActive
end

function WCCCAD:IsPlayerOfficer()
    if not self:CheckAddonActive() then
        return false
    end

    local _, _, rankIdx = GetGuildInfo("player")
    return rankIdx <= 2
end


---
--- AddOn Comms API
--- For modules, use the methods included in the ModuleBase for auto filtering and custom callbacks.
---
WCCCAD.moduleCommBindings =
{
    -- [module] = { [messageKey] = func }
}

---
--- Bind module function for a specific message key. Callback will be passed the message deserialized data.
---
function WCCCAD:RegisterModuleComm(moduleObj, moduleName, messageKey, func)
    if self.moduleCommBindings[moduleName] == nil then
        self.moduleCommBindings[moduleName] = {}
    end

    -- TODO: Error about table being passed to format??
    if self.moduleCommBindings[moduleName][messageKey] ~= nil then
        self.UI:PrintAddOnMessage(format("Multiple comms registered for %s.%s, this should not happen! Please let Aerthok know.", moduleName, messageKey), ns.consts.MSG_TYPE.ERROR)
        return
    end

    self.moduleCommBindings[moduleName][messageKey] = function(data) func(moduleObj, data) end
end

--- Dict of target players to the time the last message was sent.
--- Used for filtering no player online messages.
WCCCAD.RecentCommTargets = {}
--- Duration to filter "No player named <name > is currently playing" messages when sending comms.
--- This covers latency and throttling.
WCCCAD.CommErrorFilterDurationSecs = 180

---
--- Send a module comms message. 
--- Data can be an object and will be automatically  serialized on send and deserialized on receive.
-- @param targetplayer only used for whisper channel.
---
function WCCCAD:SendModuleComm(moduleName, messageKey, data, channel, targetPlayer)
    if channel == ns.consts.CHAT_CHANNEL.GUILD and not IsInGuild() then return end
    local modulePrefix = format("%s[WCCCMOD]%s[WCCCKEY]", moduleName, messageKey)

    local serialisedData = self:Serialize(data)
    serialisedData = modulePrefix..serialisedData

    if targetPlayer then
        WCCCAD.RecentCommTargets[targetPlayer] = GetServerTime()
    end
    self:SendCommMessage("WCCCAD", serialisedData, channel, targetPlayer)
end

function WCCCAD:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= "WCCCAD" then
        return
    end

    local moduleName, messageKey, messageData = string.match(message, "(.-)%[WCCCMOD%](.-)%[WCCCKEY%](.+)")

    -- If no module attributes were found it's a core message so just use the original data.
    if messageData == nil then
        messageData = message
    end    

    if self.moduleCommBindings[moduleName] == nil or self.moduleCommBindings[moduleName][messageKey] == nil then
        return
    end

    local _, deserialisedData = self:Deserialize(messageData)
    self.moduleCommBindings[moduleName][messageKey](deserialisedData)    
end

-- When we send a large comm message, the chunks get throttled which means the target can log out during the transmission.
-- Sending a comm message to an offline player results in the client showing the "No player named <player> is currently playing." message.
-- With large data sets, this can cause a lot of spam.
-- Unfortunately, there's no straight forward way to check the target is online before sending a comm, especially wit AceComm & ChatThrottleLib in the pipeline.
-- This workaround filters error messages to targets of our comm messages during the transmission period (an arbitrary duration).
local ERR_CHAT_PLAYER_NOT_FOUND_S_FILTER_PATTERN = string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "(.+)")
WCCCAD.SystemChatFilter = function(frame, event, msg, ...)
    local errorTargetPlayer = msg:match(ERR_CHAT_PLAYER_NOT_FOUND_S_FILTER_PATTERN)
    if errorTargetPlayer then
        local lastMsgTime = WCCCAD.RecentCommTargets[errorTargetPlayer]
        if lastMsgTime then
            if  GetServerTime() - lastMsgTime <= WCCCAD.CommErrorFilterDurationSecs then
                return true
            else
                -- Filter duration expired.
                WCCCAD.RecentCommTargets[errorTargetPlayer] = nil
            end
        end
    end
    return false
end
