assert(Automaton, "Automaton not found!")

------------------------------
--      Localization      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_DrunkTracker")

L:RegisterTranslations("enUS", function() return {
    ["DrunkTracker"] = "Drunk Tracker",
    ["Tracks drunk states and displays color-coded GUI"] = "Tracks drunk states and displays color-coded GUI",
} end)

L:RegisterTranslations("zhCN", function() return {
    ["DrunkTracker"] = "酒仙挑战",
    ["Tracks drunk states and displays color-coded GUI"] = "追踪醉酒状态，完成酒仙挑战",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_DrunkTracker = Automaton:NewModule("DrunkTracker")
Automaton_DrunkTracker.modulename = L["DrunkTracker"]
Automaton_DrunkTracker.moduledesc = L["Tracks drunk states and displays color-coded GUI"]

------------------------------
--      Local Variables      --
------------------------------

local frame = nil
local DrunkTrackerDB = nil

local DRUNK_STATES = {
    SOBER = 0,    --未醉待饮
    TIPSY = 1,    --浅醉微醺
    DRUNK = 2,    --渐醉上头
    SMASHED = 3   --烂醉如泥
}

local currentState = DRUNK_STATES.SOBER

local CHAT_PATTERNS = {
    ["你再次感觉清醒。"] = DRUNK_STATES.SOBER,
    ["你感到喝醉了。喔哦！"] = DRUNK_STATES.TIPSY,
    ["你感觉喝醉了。喔哦！"] = DRUNK_STATES.DRUNK,
    ["你感觉完全喝醉了。"] = DRUNK_STATES.SMASHED,
    ["经验值"] = DRUNK_STATES.SMASHED
}

local STATE_COLORS = {
    [DRUNK_STATES.SOBER] = {r = 0.5, g = 0.5, b = 0.5}, -- 灰色
    [DRUNK_STATES.TIPSY] = {r = 1.0, g = 1.0, b = 0.0}, -- 黄色
    [DRUNK_STATES.DRUNK] = {r = 1.0, g = 0.0, b = 0.0}, -- 红色
    [DRUNK_STATES.SMASHED] = {r = 0.0, g = 1.0, b = 0.0} -- 绿色
}

local STATE_NAMES = {
    [DRUNK_STATES.SOBER] = "未醉待饮",
    [DRUNK_STATES.TIPSY] = "浅醉微醺",
    [DRUNK_STATES.DRUNK] = "渐醉上头", 
    [DRUNK_STATES.SMASHED] = "烂醉如泥"
}

------------------------------
--      Options      --
------------------------------

-- 移除重复的启用选项，使用框架自动生成的标准启用选项
Automaton_DrunkTracker.options = {}

------------------------------
--      Frame Functions      --
------------------------------

local function CreateMainFrame()
    frame = CreateFrame("Frame", "Automaton_DrunkTrackerFrame", UIParent)
    frame:SetWidth(105)
    frame:SetHeight(44)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    frame:SetBackdropColor(0.5, 0.5, 0.5, 1.0) -- 默认灰色（未醉状态）
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton", "Shift")
    frame:SetScript("OnDragStart", function()
        if IsShiftKeyDown() then
            this:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function() 
        this:StopMovingOrSizing()
        -- 保存位置到数据库
        local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
        if DrunkTrackerDB then
            DrunkTrackerDB.position = {
                point = point,
                relativePoint = relativePoint,
                xOfs = xOfs,
                yOfs = yOfs
            }
        end
    end)
    
    -- 创建状态文本
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetText(STATE_NAMES[currentState])
    frame.text = text
    
    Automaton_DrunkTracker:UpdateGUI()
end

function Automaton_DrunkTracker:UpdateGUI()
    if not frame then return end
    
    local color = STATE_COLORS[currentState]
    local name = STATE_NAMES[currentState]
    
    frame:SetBackdropColor(color.r, color.g, color.b, 1.0)
    frame.text:SetText(name)
    frame.text:SetTextColor(1, 1, 1) -- 白色文本
end

------------------------------
--      Event Handlers      --
------------------------------

local function OnChatMessage(msg)
    for pattern, state in pairs(CHAT_PATTERNS) do
        if string.find(msg, pattern) then
            local previousState = currentState
            currentState = state
            Automaton_DrunkTracker:UpdateGUI()
            
            -- 失去完全醉酒状态时发出警告
            if previousState == DRUNK_STATES.SMASHED and state ~= DRUNK_STATES.SMASHED then
                UIErrorsFrame:AddMessage("失去完全醉酒状态！！", 1.0, 0.1, 0.1, 1.0, UIERRORS_HOLD_TIME)
                DEFAULT_CHAT_FRAME:AddMessage("====>【失去完全醉酒状态】<=====", 0, 1, 1)
                PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\1.mp3")
            end

            -- 进入完全醉酒状态时播放提示音
            if previousState ~= DRUNK_STATES.SMASHED and state == DRUNK_STATES.SMASHED then
                PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\2.mp3")
            end

            return
        end
    end
end

local function RestorePosition()
    if DrunkTrackerDB and DrunkTrackerDB.position and frame then
        local pos = DrunkTrackerDB.position
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    end
end

------------------------------
--      Module Functions      --
------------------------------

function Automaton_DrunkTracker:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("DrunkTracker")
    Automaton:RegisterDefaults("DrunkTracker", "profile", {
        disabled = true,  -- 默认关闭
        position = {
            point = "CENTER",
            relativePoint = "CENTER", 
            xOfs = 0,
            yOfs = 200
        }
    })
    DrunkTrackerDB = self.db.profile
    
    Automaton:SetDisabledAsDefault(self, "DrunkTracker")
    
    self:RegisterOptions(self.options)
end

function Automaton_DrunkTracker:OnEnable()
    if not frame then
        CreateMainFrame()
        RestorePosition()
    else
        frame:Show()
    end
    self:RegisterEvent("CHAT_MSG_SYSTEM", "OnChatMessage")
    self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", "OnChatMessage")
end

function Automaton_DrunkTracker:OnDisable()
    if frame then
        frame:Hide()
    end
    self:UnregisterAllEvents()
end

function Automaton_DrunkTracker:OnChatMessage()
    OnChatMessage(arg1)
end