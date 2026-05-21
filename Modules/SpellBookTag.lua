assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_SpellBookTag = Automaton:NewModule("SpellBookTag")
Automaton_SpellBookTag.modulename = "法术书标记"
Automaton_SpellBookTag.moduledesc = "标记法术书中已放在动作条上的技能"

------------------------------
--      Local Variables      --
------------------------------

local SpellBookTagActionButtonList = {}
local SpellBookTagToolTip -- 声明工具提示变量

------------------------------
--      Initialization      --
------------------------------

function Automaton_SpellBookTag:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("SpellBookTag")
    Automaton:RegisterDefaults("SpellBookTag", "profile", {
        disabled = false
    })
    Automaton:SetDisabledAsDefault(self, "SpellBookTag")
    
    -- 创建工具提示框
    SpellBookTagToolTip = CreateFrame("GameTooltip", "SpellBookTagToolTip", UIParent, "GameTooltipTemplate")
    
    -- 注册模块选项到主界面
    self:RegisterOptions()
end

function Automaton_SpellBookTag:OnEnable()
    self:RegisterEvent("VARIABLES_LOADED")
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
end

------------------------------
--      Helper Functions      --
------------------------------

function Automaton_SpellBookTag:SlotConvert(slot)
    if slot > 6 then
        return (slot - 6) * 2
    else
        return (slot * 2) - 1
    end
end

function Automaton_SpellBookTag:RankConvert(rankstring)
    if not rankstring then return "" end
    for i in string.gmatch(rankstring, "%d+") do
        return tonumber(i)
    end
    return ""
end

function Automaton_SpellBookTag:Printout(msg)
    DEFAULT_CHAT_FRAME:AddMessage("[法术书标记] " .. msg, 1.0, 1.0, 0.0)
end

function Automaton_SpellBookTag:ResetSpellColors()
    -- 重置所有法术按钮颜色为默认值
    for i = 1, 12 do
        local buttonName = "SpellButton" .. self:SlotConvert(i) .. "SpellName"
        local textFrame = getglobal(buttonName)
        if textFrame then
            textFrame:SetTextColor(1.0, 0.82, 0)
        end
    end
end

function Automaton_SpellBookTag:OnDisable()
    self:UnregisterAllEvents()
    -- 重置法术名称颜色
    self:ResetSpellColors()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_SpellBookTag:VARIABLES_LOADED()
    self:Printout("法术书标记 0.41 已加载")
end

function Automaton_SpellBookTag:SPELLS_CHANGED()
    self:UpdateActionButtonList()
    self:ShowBorders()
end

function Automaton_SpellBookTag:ACTIONBAR_SLOT_CHANGED()
    if SpellBookFrame:IsVisible() then
        self:UpdateActionButtonList()
        self:ShowBorders()
    end
end

------------------------------
--      Core Functions      --
------------------------------

function Automaton_SpellBookTag:UpdateActionButtonList()
    SpellBookTagActionButtonList = {}
    local st_id, st_name, st_rank, spellname
    
    for st_id = 1, 108 do
        if HasAction(st_id) then
            SpellBookTagToolTip:SetOwner(UIParent, "ANCHOR_NONE")
            SpellBookTagToolTip:SetAction(st_id)
            st_name = SpellBookTagToolTipTextLeft1:GetText()
            
            if st_name and st_name ~= "" then
                st_rank = self:RankConvert(SpellBookTagToolTipTextRight1:IsShown() 
                    and SpellBookTagToolTipTextRight1:GetText() or "")
                spellname = st_name .. st_rank
                table.insert(SpellBookTagActionButtonList, spellname)
            end
            SpellBookTagToolTip:Hide()
        end
    end
end

function Automaton_SpellBookTag:ShowBorders()
    local spelltab = SpellBookFrame.selectedSkillLine
    local page = SpellBook_GetCurrentPage()
    local spelltabname, spelltabtexture, offset, numSpells = GetSpellTabInfo(spelltab)
    
    local startspell = offset + 12 * (page - 1)
    local endspell = startspell + 12
    endspell = math.min(endspell, offset + numSpells)
    
    local spellpos = 1
    for st_spellId = startspell + 1, endspell do
        local st_spellName, st_spellRank = GetSpellName(st_spellId, BOOKTYPE_SPELL)
        if st_spellName then
            st_spellRank = self:RankConvert(st_spellRank)
            local found = false
            
            for _, name in ipairs(SpellBookTagActionButtonList) do
                if name == st_spellName .. st_spellRank then
                    found = true
                    break
                end
            end
            
            local buttonName = "SpellButton" .. self:SlotConvert(spellpos) .. "SpellName"
            local textFrame = getglobal(buttonName)
            if textFrame then
                textFrame:SetTextColor(found and 1 or 1.0, found and 0 or 0.82, found and 0 or 0)
            end
            spellpos = spellpos + 1
        end
    end
    
    -- 重置未使用的按钮颜色
    for n = spellpos, 12 do
        local buttonName = "SpellButton" .. self:SlotConvert(n) .. "SpellName"
        local textFrame = getglobal(buttonName)
        if textFrame then
            textFrame:SetTextColor(1.0, 0.82, 0)
        end
    end
end