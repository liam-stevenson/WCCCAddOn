--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
-- Core AddOn module-style functionality not intended to be shared across modules.
local name, ns = ...
local WCCCAD = ns.WCCCAD

WCCCAD.version = 1018
WCCCAD.versionString = "1.0.18"
WCCCAD.newVersionAvailable = false


local COMM_KEY_SHARE_VERSION = "shareVersionRequest"

local wcccCoreData = 
{
    profile =
    {
        firstTimeUser = true
    }
}

local WCCCADCore = WCCCAD:CreateModule("WCCC_Core", wcccCoreData)

-- Array of player names
WCCCADCore.knownAddonUsers = 
{
    [ns.utils.GetGuildMemberInfo("player").memberId] = ns.utils.GetGuildMemberInfo("player")
    -- [playername] = {}
}


function WCCCADCore:InitializeModule()
    WCCCADCore:RegisterModuleSlashCommand("ver", WCCCADCore.VersionCommand)

    WCCCADCore:RegisterModuleComm(COMM_KEY_SHARE_VERSION, WCCCADCore.OnShareVersionCommReceieved)
end

function WCCCADCore:OnEnable()
    WCCCADCore:InitiateSync()

    if WCCCADCore.moduleDB.firstTimeUser == true then
        WCCCADCore:ShowFTUEWindow()
    end

    -- TODO: Possibly bake this pattern into the ModuleBase?
    LibStub("AceEvent-3.0"):Embed(WCCCADCore) 
    LibStub("AceHook-3.0"):Embed(WCCCADCore) 
    
    WCCCADCore:RegisterEvent("ADDON_LOADED", function(event, addonName)
        if addonName == "Blizzard_Communities" then
            WCCCADCore:SecureHook(CommunitiesFrame.MemberList, "RefreshListDisplay", function()
                WCCCADCore:UpdateGuildRosterAddonIndicators()
            end)
            WCCCADCore:UpdateGuildRosterAddonIndicators()
        end

    end)    
end

function WCCCADCore:OnDisable()
    WCCCADCore:UnhookAll()
end

function WCCCADCore:UpdateGuildRosterAddonIndicators() 
    if CommunitiesFrame == nil then
        return
    end

    numButtons = #CommunitiesFrame.MemberList.ListScrollFrame.buttons
    for i=1, numButtons do
        local guildieButton = CommunitiesFrame.MemberList.ListScrollFrame.buttons[i]
        local memberInfo = guildieButton.memberInfo

        if memberInfo == nil or WCCCADCore.knownAddonUsers[memberInfo.memberId] == nil then
            if guildieButton.addonIndicator ~= nil then
                guildieButton.addonIndicator:Hide()
            end
            
            return
        end

        if guildieButton.addonIndicator ~= nil then
            guildieButton.addonIndicator:Show()
        else
            guildieButton.addonIndicator = CreateFrame("Button", nil, guildieButton)
            guildieButton.addonIndicator:SetNormalTexture("Interface\\AddOns\\WCCCAddOn\\assets\\wccc-logo.tga")
            guildieButton.addonIndicator:SetPoint("RIGHT", -10, 0)
            guildieButton.addonIndicator:SetWidth(12)
            guildieButton.addonIndicator:SetHeight(12)
            guildieButton.addonIndicator:Show()
        end
    end
end

function WCCCADCore:ShowFTUEWindow()
    WCCCADCore.moduleDB.firstTimeUser = false

    local AceGUI = LibStub("AceGUI-3.0")

    local ftueFrame = AceGUI:Create("Frame")
    ftueFrame:SetTitle("Welcome!")
    ftueFrame:SetLayout("Flow")
    ftueFrame:SetWidth(540)
    ftueFrame:SetHeight(300)

    local wcccLogo = AceGUI:Create("Label")
    wcccLogo:SetImage("Interface\\AddOns\\WCCCAddOn\\assets\\wccc-header.tga")
    wcccLogo:SetImageSize(512, 128)
    wcccLogo:SetWidth(512)
    ftueFrame:AddChild(wcccLogo)

    local welcomeText = AceGUI:Create("Label")
    welcomeText:SetWidth(450)
    welcomeText:SetText("Welcome to the official AddOn of the <Worgen Cub Clubbing Club>.\
Participate in the Clubbing Competition and view guild and raid information on the Info HUD, along with more features to come!\
\
Use the 'WCCC Companion' button on the WoW main menu (press Escape) or type '/wccc' to access the main UI window with instructions on using the AddOn.\
\
Happy Clubbing!")
    ftueFrame:AddChild(welcomeText)
end

---
--- Version Command
---
local lastVerTimestamp = 0
local verSendDelay = 20
function WCCCADCore:VersionCommand(args)
    if GetServerTime() < lastVerTimestamp + verSendDelay then
        WCCCAD.UI:PrintAddOnMessage("Please wait a short time before sending another version request.", ns.consts.MSG_TYPE.WARN)
        return
    end

    lastVerTimestamp = GetServerTime()
    WCCCADCore:SenRequestVersionComm()
end

function WCCCADCore:SenRequestVersionComm()
    local data = 
    {
        requestingPlayer = ns.utils.GetPlayerNameRealmString()
    }

    WCCCAD.UI:PrintDebugMessage("Sending version request", WCCCAD.db.profile.debugMode)
    WCCCAD.UI:PrintAddOnMessage(format("Your version: v%s", WCCCAD.versionString))
    WCCCADCore:SendModuleComm(COMM_KEY_SHARE_VERSION, data, ns.consts.CHAT_CHANNEL.GUILD)
end

function WCCCADCore:OnShareVersionCommReceieved(data)
    if data.requestingPlayer ~= nil then
        -- We've received a request.
        WCCCAD.UI:PrintDebugMessage("Received version request from " .. data.requestingPlayer, WCCCAD.db.profile.debugMode)
        local responseData = 
        {
            respondingPlayer = ns.utils.GetPlayerNameRealmString(),
            version = WCCCAD.version,
            versionString = WCCCAD.versionString
        }
        WCCCADCore:SendModuleComm(COMM_KEY_SHARE_VERSION, responseData, ns.consts.CHAT_CHANNEL.WHISPER, data.requestingPlayer)
    
    elseif data.respondingPlayer ~= nil then
        -- It's a response to a request we made.
        WCCCAD.UI:PrintDebugMessage("Received version response from " .. data.respondingPlayer, WCCCAD.db.profile.debugMode)
        local versionOutput = "v"..data.versionString
        if data.version < WCCCAD.version then
            versionOutput =  "|cFFE91100"..versionOutput.."|r (out of date)"
        elseif data.version > WCCCAD.version then
            versionOutput =  "|cFF00D42D"..versionOutput.."|r (newer version)"
            WCCCAD.newVersionAvailable = true
        end
        WCCCAD.UI:PrintAddOnMessage(format("%s - %s", data.respondingPlayer, versionOutput))
    end
end

---
--- Sync functions
---
function WCCCADCore:GetSyncData() 
    local syncData =
    {
        version = WCCCAD.version,
        versionString = WCCCAD.versionString,
        guildMemberId = ns.utils.GetGuildMemberInfo("player").memberId
    }

    return syncData
end

function WCCCADCore:CompareSyncData(remoteData)
    if remoteData.version > WCCCAD.version then
        return 1
    elseif remoteData.version == WCCCAD.version then
        return 0
    else 
        return -1
    end
end

function WCCCADCore:OnSyncDataReceived(data)
    if data.version > WCCCAD.version and WCCCAD.newVersionAvailable == false then
        WCCCAD.UI:PrintAddOnMessage(format("A new version (%s) of the WCCC Clubbing Companion is available, please update.", data.versionString), ns.consts.MSG_TYPE.WARN)
        newVersionAvailable = true
    end

    WCCCADCore.knownAddonUsers[data.guildMemberId] = ns.utils.GetGuildMemberInfo(data.guildMemberId)
    WCCCADCore:UpdateGuildRosterAddonIndicators()
end