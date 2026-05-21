assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Trigger")
local compost = AceLibrary("Compost-2.0")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
    return {
        ["Trigger"] = "触发技能提醒",
        ["Decline all incoming duels. Like the Trigger you are."] = "触发类技能提醒：回击，压制，反击",
        --["Canceling duel..."] = "取消决斗...",
    }
end)


----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Trigger = Automaton:NewModule("Trigger")
Automaton_Trigger.modulename = L["Trigger"]
Automaton_Trigger.moduledesc = L["Decline all incoming duels. Like the Trigger you are."]

local function set(field, value)
    PlaySoundFile("Interface\\AddOns\\Automaton\\sounds\\" .. value .. ".mp3")
    Automaton_Trigger.db.profile[field] = value
end

local function get(field)
    return Automaton_Trigger.db.profile[field]
end

Automaton_Trigger.options = {
    offsh = {
        type = "toggle",
        name = "取消姿态检查",
        desc = "取消触发技能提示的姿态检查",
        order = 2,
        get = function() return Automaton_Trigger.db.profile.offsh end,
        set = function(v) Automaton_Trigger.db.profile.offsh = v end,
    },
    sound = {
        type = "toggle",
        name = "触发声音提示",
        desc = "技能触发声音提示",
        order = 3,
        get = function() return Automaton_Trigger.db.profile.sound end,
        set = function(v) Automaton_Trigger.db.profile.sound = v end,
    },
    soundname = {
        name = "提示音",
        desc = "选择提示音",
        type = "text",
        order = 4,
        get = get,
        set = set,
        validate = { "hr01", "hr02", "Alarm", "vctry" },
        passValue = "soundname",
    },
}

-- 说明:
-- es 表示技能触发累，无论是否命中只有施放技能就会获得的附加效果，s 技能名称 d 持续时间
-- tf 天赋获取的技能
-- sh 姿态
-- df 触发累，比如格挡，招架
local trigger = {
    SHAMAN = {
        ["节能施法"] = { ty = { bf = "b" }, tf = "元素集中", d = 15 },
        ["乱舞"] = { ty = { bf = "b" }, tf = "乱舞", d = 15 }
    },
    ROGUE = {
        ['还击'] = { ty = { df = { "pzj" } }, tf = '还击', d = 5 },
        ['无情打击'] = { ty = { bf = "b" }, tf = "无情打击", texture = [[Interface\Icons\Ability_Warrior_DecisiveStrike]], d = 30 },
        ['血腥气息'] = { ty = { bf = "b" }, tf = "血腥气息", texture = [[Interface\Icons\INV_Misc_Bone_09]], d = 15 },
        ['突袭'] = { ty = { df = { "tds" } }, tf = '突袭', d = 5 }
    },
    WARRIOR = {
        ["反击"] = { ty = { df = { "pzj" } }, d = 5 },
        ["压制"] = { ty = { df = { "tds" } }, sh = "战斗姿态", d = 5 },
        ["复仇"] = { ty = { df = { "pgd", "pzj", "pds" } }, sh = "防御姿态", d = 5 }
    },
    HUNTER = {
        ["反击"] = { ty = { df = { "pzj" } }, d = 5 },
        ["快速射击"] = { ty = { bf = "b" }, tf = "迅捷守护", d = 12 }
    },
    MAGE = {
        ["冰霜速冻"] = { ty = { bf = "b" }, tf = "冰霜速冻", texture = [[Interface\Icons\Spell_Fire_FrostResistanceTotem]], d = 10 },
        ["奥术涌动"] = { ty = { df = { "tdk" } }, d = 5 },
        ["时间融合"] = { ty = { bf = "b" }, tf = "时间融合", texture = [[Interface\Icons\Spell_Nature_StormReach]], d = 12 },
        ["法术连击"] = { ty = { bf = "b" }, tf = "法术连击", texture = [[Interface\Icons\Ability_Mage_Firestarter]], d = 180 },
        ["灵风专注"] = { ty = { bf = "b" }, texture = [[Interface\Icons\Spell_Shadow_Teleport]], d = 12 },
        ["火焰易伤"] = { ty = { bf = "d" }, tf = "强化灼烧", d = 30 },
    },
    WARLOCK = {
        ["暗影冥思"] = { ty = { bf = "b" ,id = 17941}, tf = "夜幕", texture = [[Interface\Icons\Spell_Shadow_Twilight]], d = 10 }
    },
    PALADIN = {
        ["神圣威能"] = { ty = { se = "神圣打击" }, tf = "复仇打击", d = 20, texture = [[Interface\Icons\Spell_Holy_HolyNova]] }
    },
}

local detrigger = {
    ["清醒思维"] = { ty = { bf = "b" }, item = '55501', d = 18 },
    ["龙虾人的智慧"] = { ty = { bf = "b" }, item = '55501', d = 18 },
}

local maxbtn = 5

-- 状态映射
local statusMap = {
    pzj = "PARRY",    -- 招架
    tds = "DODGE",    -- 躲闪
    pgd = "BLOCK",    -- 格挡
    pds = "DEFLECT",  -- 偏斜
    tdk = "RESIST",   -- 抵抗
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Trigger:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("Trigger")
    Automaton:RegisterDefaults("Trigger", "profile", {
        disabled = false,
        sound = true,
        soundname = "hr01",
        offsh = false,
    })
    Automaton:SetDisabledAsDefault(self, "Trigger")
    self:RegisterOptions(self.options)
end

function Automaton_Trigger:OnEnable()
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("CHAT_MSG_SYSTEM")

    self.spell = compost:GetTable()
    self.icons = compost:GetTable()
    self.btns = {} -- 按钮表
end

function Automaton_Trigger:OnDisable()
    self:UnregisterAllEvents()
    if self.f then
        self.f:Hide()
    end

    for id, btn in pairs(self.btns) do
        btn:Hide()
    end
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Trigger:CHAT_MSG_SYSTEM(msg)
    -- 可以保留用于调试
end

function Automaton_Trigger:PlaySound()
    if self.db.profile.sound then
        PlaySoundFile("Interface\\AddOns\\Automaton\\sounds\\" .. self.db.profile.soundname .. ".mp3")
    end
end

-- 检查是否有指定名称的buff
function Automaton_Trigger:HasBuff(unit, buffName)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, i)
        if not name then break end
        if name == buffName or (spellId and tostring(spellId) == buffName) then
            return i, name, 1, nil -- 返回索引, 名称, 层数, 图标
        end
    end
    return nil
end

-- 检查是否有指定名称的debuff
function Automaton_Trigger:HasDebuff(unit, debuffName)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellId = UnitDebuff(unit, i)
        if not name then break end
        if name == debuffName or (spellId and tostring(spellId) == debuffName) then
            return i, name, 1, nil -- 返回索引, 名称, 层数, 图标
        end
    end
    return nil
end

-- 检查状态（招架、躲闪等）
function Automaton_Trigger:GetStatus(statusType, spellName)
    -- 这里需要根据实际情况实现状态检查
    -- 由于原代码中的状态检查逻辑不明确，这里返回false
    return false
end

-- 动态创建按钮
function Automaton_Trigger:CreateButton(index)
    local btn = CreateFrame("Button", "Automaton_Trigger" .. index, UIParent, "ActionButtonTemplate")
    btn:SetSize(36, 36)

    -- 设置图标
    btn.icon = _G["Automaton_Trigger" .. index .. "Icon"]
    btn.count = _G["Automaton_Trigger" .. index .. "Count"]
    btn.cooldown = _G["Automaton_Trigger" .. index .. "Cooldown"]
    
    -- 设置边框
    btn:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

    -- 定位按钮
    if index == 1 then
        btn:SetPoint("TOPLEFT", UIParent, 400, -400)
        btn:SetMovable(true)
        btn:RegisterForDrag("LeftButton")
        btn:SetScript("OnDragStart", function() this:StartMoving() end)
        btn:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    else
        btn:SetPoint("LEFT", self.btns[index - 1], "RIGHT", 6, 0)
    end

    btn:Hide()
    table.insert(self.btns, btn)
    return btn
end

-- 更新图标数据
function Automaton_Trigger:Icons_Updata(name)
    local spellData = self.spell[name]
    if not spellData then return end

    self.icons[name] = {
        icon = spellData.texture,
        apps = 1,
        time = spellData.d + GetTime(),
    }
end

-- 更新所有按钮显示
function Automaton_Trigger:UpdateButtons()
    local id = 1
    for name, val in pairs(self.icons) do
        local btn = self.btns[id]
        if not btn then btn = self:CreateButton(id) end
        
        if val.icon then
            btn.icon:SetTexture(val.icon)
        end
        
        if val.apps and val.apps > 1 then
            btn.count:SetText(val.apps)
        else
            btn.count:SetText("")
        end
        
        if val.time then
            CooldownFrame_SetTimer(btn.cooldown, GetTime(), val.time - GetTime(), 1)
        end
        
        btn:Show()
        id = id + 1
    end
    
    for i = id, maxbtn do
        local btn = self.btns[i]
        if btn then
            btn:Hide()
        end
    end
end

-- 处理战斗日志事件
function Automaton_Trigger:COMBAT_LOG_EVENT_UNFILTERED()
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
          destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    
    if sourceGUID == UnitGUID("player") then
        for name, v in pairs(self.spell) do
            if v.ty.df then
                for _, st in pairs(v.ty.df) do
                    local status = statusMap[st]
                    if status and event == "SWING_" .. status .. "_EVENT" then
                        self:Icons_Updata(name)
                        self:PlaySound()
                        return
                    end
                end
            end
        end
    end
end

function Automaton_Trigger:UNIT_AURA(unit)
    if unit == "player" then
        -- 检查buff变化
        self:ScheduleEvent(function() self:CheckBuffs() end, 0.1)
    end
end

function Automaton_Trigger:UNIT_SPELLCAST_SUCCEEDED(unit, spellName, rank, lineId, spellId)
    if unit == "player" and self.spell[spellName] then
        self:PlaySound()
        self:Icons_Updata(spellName)
    end
end

function Automaton_Trigger:CheckBuffs()
    local isdo = true
    local oldicons = self.icons
    local newicons = compost:GetTable()

    for spell, v in pairs(self.spell) do
        if v.sh and not self.db.profile.offsh then 
            isdo = self:GetCurrentShapeshiftIndex(v.sh) 
        end
        
        local idx, txt, apps, icon, time
        if isdo then
            if v.ty.bf and v.ty.bf == "b" then
                idx, txt, apps, icon = self:HasBuff("player", v.ty.id or spell)
            elseif v.ty.bf and v.ty.bf == "d" then
                idx, txt, apps, icon = self:HasDebuff("target", spell)
            elseif v.ty.df then
                for _, st in pairs(v.ty.df) do
                    if self:GetStatus(st, spell) then
                        idx = true
                        apps = 1
                        break
                    end
                end
            elseif v.ty.se and oldicons[spell] and oldicons[spell].time - GetTime() > 0 then
                idx = true
            end
        end

        if idx then
            if not oldicons[spell] then
                self:PlaySound()
                time = v.d + GetTime()
            else
                time = oldicons[spell].time
            end
            newicons[spell] = {
                icon = icon or v.texture,
                apps = tonumber(apps) or 0,
                time = time
            }
        end
    end

    self.icons = newicons
    self:UpdateButtons()
    compost:Reclaim(oldicons)
end

function Automaton_Trigger:OnUpdate()
    if (this.tick or 0) > GetTime() then return else this.tick = GetTime() + 0.2 end
    self:CheckBuffs()
end

function Automaton_Trigger:GetCurrentShapeshiftIndex(sh)
    local active, name
    for i = 1, GetNumShapeshiftForms() do
        _, name, active = GetShapeshiftFormInfo(i);
        if active then
            return name == sh;
        end
    end
end

-- 检查天赋是否已学习
function Automaton_Trigger:IsTalentLearned(talentName)
    -- 简化实现，实际需要根据天赋名称查找
    -- 这里返回true假设天赋已学习
    return true
end

-- 检查物品是否拥有
function Automaton_Trigger:HasItem(itemId)
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, _, itemString = string.find(itemLink, "|Hitem:(%d+):")
                if itemString and tonumber(itemString) == tonumber(itemId) then
                    return true
                end
            end
        end
    end
    return false
end

function Automaton_Trigger:InitLoad()
    self.spell = compost:Erase(self.spell, 2)
    local _, enclass = UnitClass("player")
    local spellslot, book, icon
    local info

    for spellname, val in pairs(detrigger) do
        if val.item and self:HasItem(val.item) then
            self.spell[spellname] = val
        end
    end
    
    if not trigger[enclass] then
        return
    end
    
    for spellname, val in pairs(trigger[enclass]) do
        if val.tf then
            if self:IsTalentLearned(val.tf) then
                if not val.texture then 
                    -- 尝试获取法术图标
                    local spellId = val.ty.id or spellname
                    val.texture = GetSpellTexture(spellId) or val.texture
                end
                self.spell[spellname] = val
            end
        elseif val.ty.bf then
            self.spell[spellname] = val
        elseif val.ty.se then
            self.spell[spellname] = val
        else
            -- 尝试通过法术名称获取信息
            local texture = GetSpellTexture(spellname)
            if texture then
                val.texture = texture
                self.spell[spellname] = val
            end
        end
    end
    return next(self.spell) ~= nil
end

function Automaton_Trigger:PLAYER_TALENT_UPDATE()
    if not self:InitLoad() then
        if self.f then
            self.f:Hide()
        end
        return
    end

    -- 创建主更新帧
    if not self.f then
        self.f = CreateFrame("Frame")
        self.f:Hide()
        self.f:SetScript("OnUpdate", function() self:OnUpdate() end)
    end

    self.f:Show()
end