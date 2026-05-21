if not SUPERWOW_VERSION then return end
assert(Automaton, "Automaton not found!")

-- 引入 AceLocale-2.2 库
local L = AceLibrary("AceLocale-2.2"):new("SuperAPI")

-- 注册英文翻译
L:RegisterTranslations("enUS", function() return {
    ["No SuperWoW detected"] = true,
    ["%d/511 Characters Used"] = true,
    ["Shows whisper, party, raid, and battleground chat text in speech bubbles above characters' heads."] = true,
    ["Show Whisper and Group Chat Bubbles"] = true,
    ["|cffffcc00SuperAPI|cffffaaaa Loaded.  Check the minimap icon for options."] = true,
    ["Raw GUID logging enabled."] = true,
    ["Raw GUID logging disabled."] = true,

    ["Always on"] = true,
    ["Always off"] = true,
    ["Shift to toggle on"] = true,
    ["Shift to toggle off"] = true,
    ["Default - incomplete circle"] = true,
    ["Full circle (must download texture)"] = true,
    ["Full circle with arrow for facing direction (must download texture)"] = true,
    ["Classic incomplete circle oriented in facing direction"] = true,
    ["Autoloot (Read tooltip)"] = true,
    ["Specifies autoloot behavior.  If using Vanilla Tweaks quickloot all of these will be reversed (always on will actually be always off, Shift to toggle on will be Shift to toggle off etc)."] = true,
    ["Clickthrough corpses"] = true,
    ["Allows you to click through corpses to loot corpses underneath them."] = true,
    ["Field of view (Requires reload)"] = true,
    ["Changes the field of view of the game.  Requires reload to take effect."] = true,
    ["Selection circle style"] = true,
    ["Changes the style of the selection circle."] = true,
    ["Background sound"] = true,
    ["Allows game sound to play even when the window is in the background."] = true,
    ["Uncapped sounds"] = true,
    ["Allows more game sounds to play at the same time by removing hardcoded limit.  This will also set SoundSoftwareChannels and SoundMaxHardwareChannels to 64.  If you experience any weird crashes you may want to turn this off."] = true,
    ["Loot Sparkle"] = true,
    ["Toggle loot sparkle effect on lootable treasure."] = true,
    ["GUID Combat Log"] = true,
    ["Changes the combat log to print GUIDs instead of names, will break a lot of addons."] = true,
} end)

-- 注册中文翻译
L:RegisterTranslations("zhCN", function() return {
    ["No SuperWoW detected"] = "未发现SuperWoW",
    ["%d/511 Characters Used"] = "已使用 %d/511 个字符",
    ["Shows whisper, party, raid, and battleground chat text in speech bubbles above characters' heads."] = "显示密语、小队、团队和战场聊天文本在角色头顶的气泡中。",
    ["Show Whisper and Group Chat Bubbles"] = "显示密语和团队聊天气泡",
    ["|cffffcc00SuperAPI|cffffaaaa Loaded.  Check the minimap icon for options."] = "|cffffcc00SuperAPI|cffffaaaa 已加载。使用小地图图标配置选项。",
    ["Raw GUID logging enabled."] = "原始 GUID 日志记录已启用。",
    ["Raw GUID logging disabled."] = "原始 GUID 日志记录已禁用。",

    ["Always on"] = "始终开启",
    ["Always off"] = "始终关闭",
    ["Shift to toggle on"] = "按Shift键开启",
    ["Shift to toggle off"] = "按Shift键关闭",
    ["Default - incomplete circle"] = "默认 - 不完整的圆，只显示视角方向的部分",
    ["Full circle (must download texture)"] = "完整圆形（必须下载纹理）",
    ["Full circle with arrow for facing direction (must download texture)"] = "带箭头指示方向的完整圆形（必须下载纹理）",
    ["Classic incomplete circle oriented in facing direction"] = "经典不完整圆形，朝向方向",
    ["Autoloot (Read tooltip)"] = "自动拾取",
    ["Specifies autoloot behavior.  If using Vanilla Tweaks quickloot all of these will be reversed (always on will actually be always off, Shift to toggle on will be Shift to toggle off etc)."] = "指定自动拾取行为。如果已使用Vanilla-Tweaks快速拾取，这些设置将会相反（开启自动拾取将会是不自动拾取，按Shift键开启将会是按Shift键关闭等）。",
    ["Clickthrough corpses"] = "点击穿透尸体",
    ["Allows you to click through corpses to loot corpses underneath them."] = "允许你点击穿透尸体以拾取下面的尸体。",
    ["Field of view (Requires reload)"] = "视野范围（需要重载）",
    ["Changes the field of view of the game.  Requires reload to take effect."] = "改变游戏的视野范围。需要重载才能生效。",
    ["Selection circle style"] = "选择目标脚下光圈样式",
    ["Changes the style of the selection circle."] = "改变目标光圈的样式。",
    ["Background sound"] = "背景声音",
    ["Allows game sound to play even when the window is in the background."] = "即使窗口位于后台，也允许游戏声音播放。",
    ["Uncapped sounds"] = "无限制声音",
    ["Allows more game sounds to play at the same time by removing hardcoded limit.  This will also set SoundSoftwareChannels and SoundMaxHardwareChannels to 64.  If you experience any weird crashes you may want to turn this off."] = "通过移除硬编码限制，允许更多游戏声音同时播放。这也将设置SoundSoftwareChannels和SoundMaxHardwareChannels为64。如果你遇到任何奇怪的崩溃，你可能想要关闭这个。",
    ["Loot Sparkle"] = "战利品闪光效果",
    ["Toggle loot sparkle effect on lootable treasure."] = "切换战利品闪光效果。",
    ["GUID Combat Log"] = "GUID战斗日志",
    ["Changes the combat log to print GUIDs instead of names, will break a lot of addons."] = "将战斗日志更改为打印GUID而不是名称，将会破坏很多插件。",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Superwow = Automaton:NewModule("Superwow")
Automaton_Superwow.modulename = "SuperWoW模块"
Automaton_Superwow.moduledesc = "客户端增强模块设置（需要登录器增强模式开启Super模式）"
Automaton_Superwow.options = {
    autoloot = {
        type = "toggle",
        name = L["Autoloot (Read tooltip)"],
        desc = L["Specifies autoloot behavior.  If using Vanilla Tweaks quickloot all of these will be reversed (always on will actually be always off, Shift to toggle on will be Shift to toggle off etc)."],
        get = function()
            return Automaton_Superwow.db.profile.autoloot
        end,
        set = function(v)
            if v then
                Automaton_Superwow.db.profile.shiftloot = false
            end
            Automaton_Superwow.db.profile.autoloot = v
            Automaton_Superwow:TurnOnAutoloot()
        end,
    },
    clickthrough = {
        type = "toggle",
        name = L["Clickthrough corpses"],
        desc = L["Allows you to click through corpses to loot corpses underneath them."],
        get = function() return Automaton_Superwow.db.profile.clickthrough end,
        set = function(v)
            if v == true then
                Clickthrough(1)
            else
                Clickthrough(0)
            end
            Automaton_Superwow.db.profile.clickthrough = v
        end,
    },
    shiftloot = {
        type = "toggle",
        name = L["Shift to toggle on"].."手动拾取",
        desc = "按住Shift拾取物品，不按shift就自动拾取。\n如果非必要建议开启自动拾取模式。",
        get = function() return Automaton_Superwow.db.profile.shiftloot end,
        set = function(v) 
            if v then
                Automaton_Superwow.db.profile.autoloot = false
            end
            Automaton_Superwow.db.profile.shiftloot = v
            Automaton_Superwow:TurnOnAutoloot()
        end,
    },
    fov = {
        type = "range",
        name = L["Field of view (Requires reload)"],
        desc = L["Changes the field of view of the game.  Requires reload to take effect."],
        min = 0.1,
        max = 3.14,
        step = 0.05,
        get = function()
            return Automaton_Superwow.db.profile.fov
        end,
        set = function(v)
            Automaton_Superwow.db.profile.fov = v
            SetCVar("FoV", v)
        end,
    },
    backgroundsound = {
        type = "toggle",
        name = L["Background sound"],
        desc = L["Allows game sound to play even when the window is in the background."],
        get = function()
            return Automaton_Superwow.db.profile.backgroundsound
        end,
        set = function(v)
            if v == true then
                SetCVar("BackgroundSound", "1")
            else
                SetCVar("BackgroundSound", "0")
            end
            Automaton_Superwow.db.profile.backgroundsound = v
        end,
    },
    LootSparkle = {
        type = "toggle",
        name = L["Loot Sparkle"],
        desc = L["Toggle loot sparkle effect on lootable treasure."],
        get = function()
            return Automaton_Superwow.db.profile.LootSparkle 
        end,
        set = function(v)
            if v == true then
                SetCVar("LootSparkle", "1")
            else
                SetCVar("LootSparkle", "0")
            end
            Automaton_Superwow.db.profile.LootSparkle = v
        end,
    },
    SelectionCircleStyle = {
        type = "range",
        name = L["Selection circle style"],
        desc = L["Changes the style of the selection circle."],
        min = 1,
        max = 4,
        step = 1,
        get = function()
            return Automaton_Superwow.db.profile.SelectionCircleStyle
        end,
        set = function(v)
            Automaton_Superwow.db.profile.SelectionCircleStyle = v
            SetCVar("SelectionCircleStyle", tostring(v))
        end,
    },
    uncappedsounds = {
        type = "toggle",
        name = L["Uncapped sounds"],
        desc = L["Allows more game sounds to play at the same time by removing hardcoded limit.  This will also set SoundSoftwareChannels and SoundMaxHardwareChannels to 64.  If you experience any weird crashes you may want to turn this off."],
        get = function()
            return GetCVar("UncapSounds") == "1"
        end,
        set = function(v)
            if v == true then
                SetCVar("UncapSounds", "1")
                SetCVar("SoundSoftwareChannels", "64")
                SetCVar("SoundMaxHardwareChannels", "64")
            else
                SetCVar("UncapSounds", "0")
                SetCVar("SoundSoftwareChannels", "12")
                SetCVar("SoundMaxHardwareChannels", "12")
            end
            Automaton_Superwow.db.profile.uncappedsounds = v
        end,
    },
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Superwow:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("Superwow")
    Automaton:RegisterDefaults("Superwow", "profile", {
        disabled = false,
        autoloot = true,
        clickthrough = false,
        shiftloot = false,
        fov = 1.5,
        backgroundsound = false,
        SelectionCircleStyle = 1,
        LootSparkle = true,
        uncappedsounds = false,
    })
    Automaton:SetDisabledAsDefault(self, "Superwow")

    self:RegisterOptions(self.options)
end

function Automaton_Superwow:OnEnable()
    if not self.superwowver then self.superwowver = SUPERWOW_VERSION end
    if self.superwowver ~= SUPERWOW_VERSION then
        print("SuperWoW有最新版<"..SUPERWOW_VERSION..">需要升级!")
    end
    -- MacroFrame_LoadUI()
    -- MacroFrameText:SetMaxLetters(511)
    MACROFRAME_CHAR_LIMIT = L["%d/511 Characters Used"]
    -- Change chat bubbles options name
    OPTION_TOOLTIP_PARTY_CHAT_BUBBLES = L["Shows whisper, party, raid, and battleground chat text in speech bubbles above characters' heads."]
    PARTY_CHAT_BUBBLES_TEXT = L["Show Whisper and Group Chat Bubbles"]

    self.options.clickthrough.set(self.db.profile.clickthrough)
    self.options.LootSparkle.set(self.db.profile.LootSparkle)
    self.options.SelectionCircleStyle.set(self.db.profile.SelectionCircleStyle)
    self.options.backgroundsound.set(self.db.profile.backgroundsound)
    self.options.uncappedsounds.set(self.db.profile.uncappedsounds)

    self:TurnOnAutoloot()
    if CombatText_AddMessage then
        self:Hook("CombatText_AddMessage")
    end
    self:Hook("SpellButton_OnClick")
    self:Hook("SetItemRef")
    self:Hook("UnitFrame_OnEnter")
    self:Hook("UnitFrame_OnLeave")
end

function Automaton_Superwow:OnDisable()
end

------------------------------
--      Event Handlers      --
------------------------------
function Automaton_Superwow:TurnOnAutoloot()
    -- 清理之前的OnUpdate脚本
    if self.f then
        self.f:SetScript("OnUpdate", nil)
        self.f = nil
    end
    
    if self.db.profile.shiftloot then        
        -- Shift拾取模式：按住Shift时开启自动拾取，不按时关闭
        self.f = CreateFrame("Frame")
        self.f:SetScript("OnUpdate", function()
            if IsShiftKeyDown() then
                SetAutoloot(1)
            else
                SetAutoloot(0)
            end
        end)
    elseif self.db.profile.autoloot then
        -- 始终自动拾取模式
        SetAutoloot(1)
    else
        -- 默认情况：关闭自动拾取
        SetAutoloot(0)
    end
end

-- Global function to get a spell link from its exact id
function Automaton_Superwow:GetSpellLink(id)
    local spellname = SpellInfo(id)
    local link = "\124cffffffff\124Henchant:" .. id .. "\124h[" .. spellname .. "]\124h\124r"
    return link
end

-- reformat "Enchant" itemlinks to better supported "Spell" itemlinks
function Automaton_Superwow:SetItemRef (link, text, button)
    link = gsub(link, "spell:", "enchant:")
    self.hooks.SetItemRef(link, text, button)
end

-- hooking spellbook frame to get a spell link on shift clicking a spell's button with chatframe open
function Automaton_Superwow:SpellButton_OnClick(drag)
    if ((not drag) and IsShiftKeyDown() and ChatFrameEditBox:IsVisible() and (not MacroFrame or not MacroFrame:IsVisible())) then
        local bookId = SpellBook_GetSpellID(this:GetID())
        local _, _, spellID = GetSpellName(bookId, SpellBookFrame.bookType)
        local link = self:GetSpellLink(spellID)
        ChatFrameEditBox:Insert(link)
    else
        self.hooks.SpellButton_OnClick(drag)
    end
end

-- Add Mouseover casting to default blizzard unitframes and all unitframe addons that use the same function
function Automaton_Superwow:UnitFrame_OnEnter()
    self.hooks.UnitFrame_OnEnter()
    SetMouseoverUnit(this.unit)
end

function Automaton_Superwow:UnitFrame_OnLeave()
    self.hooks.UnitFrame_OnLeave()
    SetMouseoverUnit()
end

function Automaton_Superwow:CombatText_AddMessage(message, scrollFunction, r, g, b, displayType, isStaggered)
    local newMessage = gsub(message, "(%s%[)(0x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x)(%])", function(bracket1, hex, bracket2)
        if UnitIsUnit(hex, "player") then return nil
        else
            local _, class = UnitClass(hex)
            if not class  then return " ["..UnitName(hex).."]" end
            local color = RAID_CLASS_COLORS[class].colorStr
            return " [|C"..color..UnitName(hex).."|r]" 
        end
    end)
    return self.hooks.CombatText_AddMessage(newMessage, scrollFunction, r, g, b, displayType, isStaggered)
end