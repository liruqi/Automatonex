assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_QuestHook = Automaton:NewModule("QuestHook")
Automaton_QuestHook.modulename = "姓名版显示任务目标"
Automaton_QuestHook.moduledesc = "识别任务相关单位（基于pfQuest数据）"

------------------------------
--      Initialization      --
------------------------------

function Automaton_QuestHook:OnInitialize()
    -- 初始化数据库命名空间
    self.db = Automaton:AcquireDBNamespace("QuestHook")
    -- 注册默认配置
    Automaton:RegisterDefaults("QuestHook", "profile", {
        disabled = false 
    })
    -- 设置默认禁用状态
    Automaton:SetDisabledAsDefault(self, "QuestHook")
    -- 注册模块配置选项（至少包含启用开关）
    self:RegisterOptions(self:GetOptions())
end

-- 模块启用时的操作
function Automaton_QuestHook:OnEnable()
    -- 注册为全局函数，供其他模块调用
    _G.IsQuestUnit = function(name) 
        return self:IsQuestUnit(name) 
    end
    -- 注册任务日志更新事件
    self:RegisterEvent("QUEST_LOG_UPDATE")
    DEFAULT_CHAT_FRAME:AddMessage("姓名版任务目标已启用")
end

-- 模块禁用时的操作
function Automaton_QuestHook:OnDisable()
    -- 注销所有事件并移除全局函数
    self:UnregisterAllEvents()
    _G.IsQuestUnit = nil
    DEFAULT_CHAT_FRAME:AddMessage("姓名版任务目标已禁用")
end

------------------------------
--      Configuration       --
------------------------------

function Automaton_QuestHook:GetOptions()
    return {
        enabled = {
            order = 1,
            type = "toggle",
            name = "启用",
            desc = "开启/关闭姓名版任务目标功能",
            get = function() return Automaton:IsModuleActive(self.name) end,
            set = function(v) Automaton:ToggleModuleActive(self.name, v) end,
        }
    }
end

------------------------------
--      Core Function       --
------------------------------

-- 定义图标路径
local cluster_mob = "Interface\\AddOns\\Automatonex\\Texture\\npc.tga"   -- 怪物任务图标
local cluster_item = "Interface\\AddOns\\Automatonex\\Texture\\vendor.tga"  -- 物品任务图标

-- 检查任务是否已完成
local function IsQuestCompleted(questName, unitName)
    -- 检查任务历史记录
    if pfQuest_history then
        for questId, _ in pairs(pfQuest_history) do
            local questData = pfDB["quests"]["data"][questId]
            if questData and pfDB["quests"]["loc"] and pfDB["quests"]["loc"][questId] == questName then
                return true -- 任务已完成
            end
        end
    end
    
    -- 检查当前任务日志
    for i = 1, GetNumQuestLogEntries() do
        local title, _, _, _, isHeader, _, isComplete = GetQuestLogTitle(i)
        if not isHeader and title and title == questName then
            -- 如果任务标记为完成，返回true
            if isComplete then
                return true
            end
            
            -- 检查具体任务目标
            local numObjectives = GetNumQuestLeaderBoards(i)
            for j = 1, numObjectives do
                local text, _, finished = GetQuestLogLeaderBoard(j, i)
                if text and finished then
                    -- 如果任务目标已完成且与当前单位相关
                    if string.find(text, unitName) then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- 判断是否为物品任务（增强的检测逻辑）
local function IsItemQuest(meta, name)
    -- 方法1：检查描述中包含的关键词
    if meta.description then
        local desc = string.lower(meta.description)
        local itemKeywords = {
            "拾取", "收集", "获得", "找到", "物品", "道具", 
            "pick", "collect", "gather", "loot", "item"
        }
        
        for _, keyword in ipairs(itemKeywords) do
            if string.find(desc, keyword) then
                return true
            end
        end
    end
    
    -- 方法2：检查目标类型（如果pfQuest有提供）
    if meta.type and (meta.type == "object" or meta.type == "item") then
        return true
    end
    
    -- 方法3：检查是否是容器、宝箱等
    if meta.objective and string.find(string.lower(meta.objective), "object") then
        return true
    end
    
    return false
end

-- 判断单位是否为任务相关目标（修复版本）
function Automaton_QuestHook:IsQuestUnit(name)
    -- 若模块未启用或pfQuest未加载，直接返回
    if not Automaton:IsModuleActive("QuestHook") or not name or not IsAddOnLoaded("pfQuest") then
        return false
    end
    
    -- 初始化pfQuest.node存储
    if not pfQuest then
        return false
    end
    
    if not pfQuest.node then
        pfQuest.node = {}
    end
    
    -- 优先从缓存获取结果
    local cachedResult = pfQuest.node[name]
    if cachedResult ~= nil then
        return cachedResult
    end
    
    -- 获取当前地图ID
    local zone = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
    
    -- 调试信息（可选）
    -- DEFAULT_CHAT_FRAME:AddMessage("检查单位: " .. (name or "未知"))
    
    -- 检查pfMap的tooltip数据
    if pfMap.tooltips and pfMap.tooltips[name] then
        local meta
        -- 遍历单位的所有tooltip数据，匹配当前地图
        for _, obj in pairs(pfMap.tooltips[name]) do
            if obj[zone] then
                meta = obj[zone]
                break
            end
        end
        
        -- 无匹配数据，缓存结果为false
        if not meta then
            pfQuest.node[name] = false
            return false
        end
        
        -- 若为任务目标，检查是否已完成
        if meta["quest"] then
            -- 调试信息（可选）
            -- DEFAULT_CHAT_FRAME:AddMessage("找到任务: " .. meta["quest"] .. " 描述: " .. (meta.description or "无"))
            
            -- 检查任务是否已完成
            if IsQuestCompleted(meta["quest"], name) then
                pfQuest.node[name] = false
                return false
            end
            
            -- 检查当前任务状态
            local isOnQuest = false
            for i = 1, GetNumQuestLogEntries() do
                local title, _, _, _, isHeader = GetQuestLogTitle(i)
                if not isHeader and title and title == meta["quest"] then
                    isOnQuest = true
                    break
                end
            end
            
            -- 只有当前正在进行的任务才显示图标
            if not isOnQuest then
                pfQuest.node[name] = false
                return false
            end
            
            -- 任务未完成，返回对应的集群类型
            local resultCluster = cluster_mob  -- 默认怪物集群
            
            -- 使用增强的物品任务检测
            if IsItemQuest(meta, name) then
                resultCluster = cluster_item
                -- 调试信息（可选）
                -- DEFAULT_CHAT_FRAME:AddMessage("识别为物品任务: " .. name)
            end
            
            pfQuest.node[name] = resultCluster
            return resultCluster
        end
    end
    
    -- 非任务目标，缓存结果
    pfQuest.node[name] = false
    return false
end

-- 添加任务日志更新事件来清除缓存
function Automaton_QuestHook:QUEST_LOG_UPDATE()
    if pfQuest and pfQuest.node then
        pfQuest.node = {} -- 清除缓存，强制重新检查所有单位
    end
end