--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local name, ns = ...
local WCCCAD = ns.WCCCAD

local infoHUDData = 
{
    profile =
    {
        activeRaidMsg = nil,
        activeRaidMsgUpdateTime = 0,

        activeGuildMsg = nil,
        activGuildMsgUpdateTime = 0,

        savedMessages = {},
    }
}

local InfoHUD = WCCCAD:CreateModule("WCCC_InfoHUD", infoHUDData)

function InfoHUD:InitializeModule()
    InfoHUD:RegisterModuleSlashCommand("infohud", InfoHUD.InfoHUDCommand)
    WCCCAD.UI:PrintAddOnMessage("Info HUD module loaded.")
end

function InfoHUD:OnEnable()
    InfoHUD:InitiateSync()
    InfoHUD:ToggleHUD()
end

function InfoHUD:InfoHUDCommand(args)
    if args ~= nil and args[1] ~= nil then
        if args[1] == "toggle" then
            InfoHUD:ToggleHUD()
        end
        return 
    end

    self.UI:Show()
end

function InfoHUD:ToggleHUD()
    if InfoHUD.hudFrame == nil then
        InfoHUD:CreateHUD()
        return
    end

    if InfoHUD.hudFrame:IsShown() then
        InfoHUD.hudFrame:Hide()
    else
        InfoHUD.hudFrame:Show()
    end
end

function InfoHUD:CreateHUD()
    -- TODO: Save points
    InfoHUD.hudFrame = ns.utils.CreateHUDPanel(
        "Info HUD",
        function() return "CENTER", 0, 0 end,
        function(point, offsetX, offsetY) end,
        function() print("TODO: Open Info HUD settings") end
    )

    InfoHUD.hudFrame:SetWidth(300)
    InfoHUD.hudFrame:SetHeight(300)

    InfoHUD.hudFrame.messageFrames = {}
    InfoHUD.hudFrame.CreateMessageFrame = function(self, frameName, tabName) 
        local messageFrame = CreateFrame("ScrollingMessageFrame", nil, InfoHUD.hudFrame)
        messageFrame:SetPoint("TOPLEFT", 5, -50)
        messageFrame:SetPoint("RIGHT", -5, 0)
        messageFrame:SetPoint("BOTTOM", 0, 5)
        messageFrame:SetSize(InfoHUD.hudFrame:GetWidth() - 5, InfoHUD.hudFrame:GetHeight() - 20)
        messageFrame:SetIndentedWordWrap(true)
        messageFrame:SetJustifyH("LEFT")
        messageFrame:SetFading(false)
        messageFrame:SetMaxLines(50)
        messageFrame:SetHyperlinksEnabled(false)
        messageFrame:SetFontObject(GameFontNormal)
        messageFrame:SetTextColor(1, 1, 1, 1)
        messageFrame:SetInsertMode(SCROLLING_MESSAGE_FRAME_INSERT_MODE_TOP)
        messageFrame:Hide()

        local tabButton = CreateFrame("Button", frameName.."_tab", InfoHUD.hudFrame, "OptionsFrameTabButtonTemplate")--"UIPanelButtonTemplate")
        local tabOffset = 0
        for k,v in pairs(InfoHUD.hudFrame.messageFrames) do
            tabOffset = tabOffset + v.tabButton:GetWidth() - 10
        end        
        tabButton:ClearAllPoints()
        --tabButton:SetPoint("TOPLEFT", 3 + (btnNum * 80), -20)
        tabButton:SetPoint("TOPLEFT", 3 + tabOffset, -20)
        tabButton:SetText(tabName)
        PanelTemplates_TabResize(tabButton, 2, nil, 30, 30, tabButton:GetFontString():GetStringWidth())
        tabButton:SetScript("OnClick", function()
            InfoHUD.hudFrame:SwitchTab(frameName)
        end)

        InfoHUD.hudFrame.messageFrames[frameName] = 
        {
            messageFrame = messageFrame,
            tabButton = tabButton
        }
        
    end

    InfoHUD.hudFrame.GetMessageFrame = function(self, frameName)
        return InfoHUD.hudFrame.messageFrames[frameName].messageFrame
    end

    InfoHUD.hudFrame.SwitchTab = function(self, targetFrame)
        for frameName, frameData in pairs(InfoHUD.hudFrame.messageFrames) do
            if frameName == targetFrame then
                frameData.tabButton:LockHighlight()
                frameData.messageFrame:Show()
            else
                frameData.tabButton:UnlockHighlight()
                frameData.messageFrame:Hide()
            end
        end
        
    end

    local tabDivider = CreateFrame("Frame", nil, InfoHUD.hudFrame)
    tabDivider:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
        tile = false, tileSize = 6, edgeSize = 6, 
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    tabDivider:SetFrameLevel(99)
    tabDivider:SetBackdropBorderColor(1, 0.62, 0, 0.8)
    tabDivider:SetPoint("TOPLEFT", 3, -45)
    tabDivider:SetHeight(3)
    tabDivider:SetWidth(InfoHUD.hudFrame:GetWidth() -3)
     
    InfoHUD.hudFrame:CreateMessageFrame("guild", "Guild")
    local guildFrame = InfoHUD.hudFrame:GetMessageFrame("guild")
    guildFrame:AddMessage("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("test")
    guildFrame:AddMessage("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t")
    guildFrame:AddMessage("Guild message")

    InfoHUD.hudFrame:CreateMessageFrame("raid", "Raid")
    InfoHUD.hudFrame:CreateMessageFrame("test", "Test")
    local raidFrame = InfoHUD.hudFrame:GetMessageFrame("raid")
    raidFrame:AddMessage("Raid message")
    
    InfoHUD.hudFrame:SwitchTab("guild")
end


---
--- Sync Data
---
function InfoHUD:GetSyncData() 
    local syncData =
    {
    }

    return syncData
end

function InfoHUD:CompareSyncData(remoteData)
    return 0
end

function InfoHUD:OnSyncDataReceived(data)

end