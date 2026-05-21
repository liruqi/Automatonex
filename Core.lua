------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton")
local waterfall = AceLibrary("Waterfall-1.0")

-- 安全地获取职业颜色
local function GetSafeClassColor()
    local _, playerClass = UnitClass('player')
    if playerClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass] then
        return RAID_CLASS_COLORS[playerClass]
    end
    return { r = 0.5, g = 0.5, b = 0.5 } -- 默认灰色
end

local classColor = GetSafeClassColor()
local colorR, colorG, colorB = classColor.r, classColor.g, classColor.b
local CHAT_FORMAT_STRING = "CHATITEMINFO:%s:%s:%s"
local loc = GetLocale()

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Enabled"] = "启用",
		["Suspend/resume this module"] = "暂停/恢复该模块",
		["Debugging"] = "调试",
		["Toggle debugging for this module"] = "开关该模块的调试模式",
		["Search Modules"] = "搜索",
		["Search for modules by name or description"] = "按名称或描述搜索模块",
		["Clear Search"] = "清除搜索",
	}
end)

---------------------------------
--      Addon Declaration      --
---------------------------------

Automaton = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "FuBarPlugin-2.0", "AceEvent-2.0", "AceDebug-2.0",
    "AceDB-2.0", "AceModuleCore-2.0", "AceHook-2.1")
Automaton:SetModuleMixins("AceConsole-2.0", "AceEvent-2.0", "AceDebug-2.0", "AceHook-2.1")

-- 简化的 print 函数，避免所有可能的索引问题
function Automaton:print(text, title)
    if text == nil or text == "" then return end
    
    if DEFAULT_CHAT_FRAME then
        if title then
            DEFAULT_CHAT_FRAME:AddMessage("|CFF00AB00" .. title .. "：|r " .. text)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[|r|cff00ffffAutomaton|r|cffffcc00]|r " .. text)
        end
    end
end

-- 将 print 函数添加到模块原型中
Automaton.modulePrototype.print = Automaton.print

Automaton.version = tonumber(string.sub("$1.1.2$", 12, -3))

-- 创建搜索选项表
local searchOptions = {
    searchBox = {
        order = 1,
        type = 'text',
        name = L["Search Modules"],
        desc = L["Search for modules by name or description"],
        get = function() return Automaton.db.profile.searchText or "" end,
        set = function(value)
            Automaton.db.profile.searchText = value
            Automaton:UpdateModuleVisibility()
        end,
        usage = "<搜索关键词>",
    },
    clearSearch = {
        order = 2,
        type = 'execute',
        name = L["Clear Search"],
        desc = L["Clear Search"],
        func = function()
            Automaton.db.profile.searchText = ""
            Automaton:UpdateModuleVisibility()
        end,
    },
}

Automaton.options = {
    name = "主页",
    type = 'group',
    args = {
        search = {
            type = 'group',
            name = L["Search Modules"],
            desc = L["Search for modules by name or description"],
            order = 1,
            args = searchOptions,
        },
        -- 其他模块将在这里动态添加
    },
}

Automaton.t = {}
Automaton:RegisterDB("AutomatonDB")

-- 修复聊天命令注册：使用正确的参数顺序
Automaton:RegisterChatCommand({ "/autocl", "/automatoncl" }, Automaton.options)
Automaton:RegisterChatCommand({ "/auto", "/automaton" }, function() 
    if waterfall:IsOpen('Automaton') then
        waterfall:Close('Automaton')
    else
        waterfall:Open('Automaton') 
    end
end)

waterfall:Register('Automaton', 'aceOptions', Automaton.options, 'title', 'Automaton工具箱强化版', 'colorR', colorR,
    'colorG', colorG, 'colorB', colorB, "head", "Automaton")

------------------------------
--      Initialization      --
------------------------------
CHATITEMDB = {}

function Automaton:OnInitialize()
    Automaton.gratuity = AceLibrary("Gratuity-2.0")
    Automaton.Deformat = AceLibrary("Deformat-2.0")
    
    -- 不再存储enClass，避免索引问题
    self.ver = 20241222

    -- 初始化搜索文本
    self.db.profile.searchText = self.db.profile.searchText or ""

    -- 已删除：self:RegisterEvent('CHAT_MSG_CHANNEL')
    
    -- 注册搜索测试命令
    self:RegisterChatCommand({ "/autosearch" }, function(msg)
        self.db.profile.searchText = msg or ""
        self:UpdateModuleVisibility()
        self:print("搜索设置为: " .. (msg or "空"), "测试")
    end)
    
    -- 初始化 FuBar 插件数据，避免 SetPluginSide 错误
    if not self.db.profile.position then
        self.db.profile.position = "LEFT"
    end
end

function Automaton:OnEnable()
    self.itemDB = CHATITEMDB
end

function Automaton:SetDisabledAsDefault(object, name)
    if object.db.profile.disabled then
        object.db.profile.disabled = false
        self:ToggleModuleActive(name, false)
    end
end

--------------------------------
--      Module Prototype      --
--------------------------------

function Automaton.modulePrototype:RegisterOptions(options)
    -- 确保 options 表存在
    options = options or {}
    
    options.enabled = {
        order = 1,
        type = 'toggle',
        name = L["Enabled"],
        desc = L["Suspend/resume this module"],
        get = function() return Automaton:IsModuleActive(self.name) end,
        set = function(v) Automaton:ToggleModuleActive(self.name, v) end,
    }
    
    -- 确保模块有名称和描述
    local moduleName = self.modulename or self.name
    local moduleDesc = self.moduledesc or "模块选项"
    
    -- 注册模块到主选项表
    Automaton.options.args[self.name] = {
        type = 'group',
        name = moduleName,
        desc = moduleDesc,
        order = 10, -- 给模块一个基础排序值
        args = options,
    }
end

-- 更新所有模块的可见性
function Automaton:UpdateModuleVisibility()
    local searchText = self.db.profile.searchText or ""
    
    for moduleName, moduleData in pairs(self.options.args) do
        -- 跳过搜索组本身
        if moduleName ~= "search" then
            local shouldShow = false
            
            if searchText == "" then
                -- 空搜索显示所有模块
                shouldShow = true
            else
                -- 获取模块名称和描述
                local moduleNameText = moduleData.name or ""
                local moduleDescText = moduleData.desc or ""
                
                -- 转换为小写进行不区分大小写的搜索
                local searchLower = string.lower(searchText)
                local nameLower = string.lower(moduleNameText)
                local descLower = string.lower(moduleDescText)
                
                -- 简单直接匹配
                local nameMatch = string.find(nameLower, searchLower, 1, true)
                local descMatch = string.find(descLower, searchLower, 1, true)
                
                shouldShow = nameMatch or descMatch
            end
            
            moduleData.hidden = not shouldShow
        end
    end
    
    if waterfall:IsOpen('Automaton') then
        waterfall:Refresh('Automaton')
    end
end

----------------------------
--      FuBar Plugin      --
----------------------------

Automaton.name = "主页"
Automaton.hasIcon = "Interface\\Icons\\Trade_Engineering"
Automaton.hideWithoutStandby = true
Automaton.tooltipHiddenWhenEmpty = true

-- 添加缺失的 FuBar 方法以避免错误
function Automaton:SetPluginSide(side)
    self.db.profile.position = side
end

function Automaton:GetPluginSide()
    return self.db.profile.position or "LEFT"
end

Automaton.OnClick = function()
    if waterfall:IsOpen('Automaton') then
        waterfall:Close('Automaton')
    else
        waterfall:Open('Automaton')
    end
end

function Automaton:AddItem(t, item, title)
    local itemid = string.match(item, "%d+")
    if itemid then
        itemid = tonumber(itemid)
        -- 使用内置 GetItemInfo 获取物品链接（第二个返回值）
        local _, link = GetItemInfo(itemid)
        if link then
            if t[itemid] then
                self:print("物品已存在无需添加", title)
            else
                t[itemid] = link
                self:print("成功添加物品：" .. link, title)
            end
        else
            self:print("物品ID不存在或未加载", title)
        end
    else
        self:print("物品ID无效添加失败", title)
    end
end

function Automaton:RemoveItem(t, item, title)
    local itemid = string.match(item, "%d+")
    if itemid then
        itemid = tonumber(itemid)
        -- 使用内置 GetItemInfo 获取物品链接
        local _, link = GetItemInfo(itemid)
        if link then
            if t[itemid] then
                self:print("物品移除成功：" .. t[itemid], title)
                t[itemid] = nil
            else
                self:print("物品不存在于列表中", title)
            end
        else
            self:print("物品ID不存在或未加载", title)
        end
    else
        self:print("物品ID无效移除失败", title)
    end
end

function Automaton:ItemListAll(t, title)
    self:print("列表内容:", title)
    for k, v in pairs(t) do
        self:print('物品名称：' .. v .. " 物品ID:" .. k, title)
    end
end

-- ========== 已删除 CHAT_MSG_CHANNEL 函数 ==========