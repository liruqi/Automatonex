-- 使用 assert 函数进行条件检查。如果 Automaton 变量为 nil，则会抛出错误并显示 "Automaton not found!" 信息
-- 通常用于确保某个关键模块或对象已经被正确加载和定义
assert(Automaton, "Automaton not found!")

----------------------------
--      Localization      --
----------------------------

local L = AceLibrary("AceLocale-2.2"):new("Lern2Spell")

L:RegisterTranslations("zhCN", function() return {
    upgrade = "编号#%s按钮 更新技能为 %s (%s)",
} end)

------------------------------
--      Are you local?      --
------------------------------

-- AceLibrary("SpecialEvents-LearnSpell-2.0") -- Majick line for InBed
local gratuity = AceLibrary("Gratuity-2.0")

----------------------------------
--      Module Declaration      --
----------------------------------
-- 从 Automaton 中创建一个名为 "Lern2Spell" 的新模块，并将其赋值给 Automaton_Lern2Spell 变量
local Automaton_Lern2Spell = Automaton:NewModule("Lern2Spell")
-- 为该模块设置一个可读的名称，用于界面显示或日志记录等，这里名称为 "动作条新学技能更新"
Automaton_Lern2Spell.modulename = "动作条新学技能更新"
-- 为该模块设置一个描述信息，用于说明该模块的功能，这里描述为 "新学技能后，自动把动作条上现有技能更新到新学的最高等级"
Automaton_Lern2Spell.moduledesc = "新学技能后，自动把动作条上现有技能更新到新学的最高等级"
-- 初始化该模块的选项表，后续可用于存储和管理模块的配置选项
Automaton_Lern2Spell.options = {}

------------------------------
--      Initialization      --
------------------------------
-- 定义模块的初始化函数，当模块被加载时会调用此函数
function Automaton_Lern2Spell:OnInitialize()
    -- 调用模块的 RegisterOptions 方法，将之前定义的选项表 self.options 进行注册
    -- 通常用于将模块的配置选项集成到主配置系统中
    self:RegisterOptions(self.options)
end

-- 定义模块启用时调用的函数，当模块被启用时会执行此函数中的逻辑
function Automaton_Lern2Spell:OnEnable()
    -- 加载 AceLibrary 中的 Gratuity-2.0 库，并将其赋值给 self.gratuity 变量
    -- 这个库可能用于获取动作条上技能的详细信息
    self.gratuity = gratuity
    -- 注册 "SpecialEvents_LearnedSpell" 事件，当该事件触发时，模块会调用相应的处理函数
    self:RegisterEvent("SpecialEvents_LearnedSpell")
end

-- 定义模块禁用时调用的函数，当模块被禁用时会执行此函数中的逻辑
function Automaton_Lern2Spell:OnDisable()
    -- 注销模块注册的所有事件，确保模块禁用后不再响应任何事件
    self:UnregisterAllEvents()
end

-- 定义 "SpecialEvents_LearnedSpell" 事件的处理函数，当玩家学习新技能时会触发此函数
function Automaton_Lern2Spell:SpecialEvents_LearnedSpell(spell, rank)
    for btn = 1, 120 do
        local n, r = self:ActionIsSpell(btn)
        if n and n == spell and ((r or "") ~= rank) then
            local i = self:GetSpellIndex(spell, rank)
            if not i then return end

            local n, r = GetSpellName(i, BOOKTYPE_SPELL)
            self:Print(L.upgrade, btn, n, r or "??")
            PickupSpell(i, BOOKTYPE_SPELL)
            PlaceAction(btn)

            repeat
                if CursorHasItem() or CursorHasSpell() then PickupSpell(1, BOOKTYPE_SPELL) end
            until not CursorHasItem() and not CursorHasSpell()
        end
    end
end

-- 定义一个方法，用于获取指定技能和等级的索引
function Automaton_Lern2Spell:GetSpellIndex(spell, rank)
    assert(spell, "No spell passed")

    local i, n, r = 1
    repeat
        n, r = GetSpellName(i, BOOKTYPE_SPELL)
        if n and n == spell and r == rank then return i end
        i = i + 1
    until not n
end

-- 定义一个方法，用于检查指定动作条按钮上的动作是否为技能
function Automaton_Lern2Spell:ActionIsSpell(id)
    if not id or GetActionText(id) then return end

    self.gratuity:SetAction(id)
    return self.gratuity:GetLine(1)
end