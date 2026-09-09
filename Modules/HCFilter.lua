-- 首先确保依赖检查
assert(Automaton, "Automaton not found!")

------------------------------
--      本地化配置          --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_HCFilter")

L:RegisterTranslations("zhCN", function() return {
    ["HCFilter"] = "硬核聊天过滤",
    ["Filters and formats hardcore chat messages."] = "过滤并格式化硬核模式聊天消息",
} end)

------------------------------
--      模块声明            --
------------------------------

local Automaton_HCFilter = Automaton:NewModule("HCFilter")
Automaton_HCFilter.modulename = L["HCFilter"]
Automaton_HCFilter.moduledesc = L["Filters and formats hardcore chat messages."]

-- 模块配置选项（整合原有的设置项）
Automaton_HCFilter.options = {
    frame = {
        type = "range",
        name = "聊天窗口",
        desc = "设置硬核消息显示的聊天窗口编号",
        min = 1,
        max = 9,
        step = 1,
        get = function() return Automaton_HCFilter.db.profile.frame end,
        set = function(v) Automaton_HCFilter.db.profile.frame = v end,
    },
    prefix = {
        type = "text",
        name = "前缀文本",
        desc = "设置硬核消息的前缀标识",
        get = function() return Automaton_HCFilter.db.profile.prefix end,
        set = function(v) Automaton_HCFilter.db.profile.prefix = v end,
    },
    colour = {
        type = "text",
        name = "颜色代码",
        desc = "设置消息文本的颜色代码（如e6cd80）",
        get = function() return Automaton_HCFilter.db.profile.colour end,
        set = function(v) Automaton_HCFilter.db.profile.colour = v end,
    },
}

------------------------------
--      初始化设置          --
------------------------------

function Automaton_HCFilter:OnInitialize()
    -- 注册数据库
    self.db = Automaton:AcquireDBNamespace("HCFilter")
    Automaton:RegisterDefaults("HCFilter", "profile", {
        disabled = false,  -- 模块默认启用
        frame = 1,         -- 默认聊天窗口1
        prefix = "HC",     -- 默认前缀
        colour = "e6cd80", -- 默认颜色
        spam = "",         -- 用于防刷屏的缓存
    })
    self:RegisterOptions(self.options)  -- 注册到核心配置面板
end

------------------------------
--      事件与逻辑          --
------------------------------

-- 模块启用时注册事件
function Automaton_HCFilter:OnEnable()
    -- 保存原始事件处理函数
    self.originalChatFrame_OnEvent = ChatFrame_OnEvent
    -- 替换为自定义处理函数
    ChatFrame_OnEvent = function(event) self:HandleChatEvent(event) end
end

-- 模块禁用时恢复原始逻辑
function Automaton_HCFilter:OnDisable()
    ChatFrame_OnEvent = self.originalChatFrame_OnEvent
end

-- 聊天事件处理逻辑
function Automaton_HCFilter:HandleChatEvent(event)
    if event == "CHAT_MSG_HARDCORE" then
        -- 防刷屏检查
        if self.db.profile.spam == arg1 then
            return false
        end
        
        -- 超级忽略支持
        if IsAddOnLoaded("SuperIgnore") and SI_BannedGetIndex(arg2) then
            return self.originalChatFrame_OnEvent(event)
        end

        -- 获取玩家等级（复用ChatMOD逻辑）
        local level = nil
        local playerName = arg2  -- 消息发送者名称
        local lowName = ChatMOD_prepName and ChatMOD_prepName(playerName)  -- 调用ChatMOD的名称格式化
        if lowName and string.len(lowName) > 2 and SCCN_storage and SCCN_storage[lowName] then
            level = tonumber(SCCN_storage[lowName]["l"])  -- 从ChatMOD的存储中获取等级
        end

        -- 构建等级标签（模仿ChatMOD格式）
        local levelTag = ""
        if level and SCCN_SHOWLEVEL and SCCN_SHOWLEVEL == 1 then  -- 检查ChatMOD等级显示开关
            local levelColor = GetDifficultyColorChatMod and GetDifficultyColorChatMod(level)  -- 调用ChatMOD的等级颜色函数
            if levelColor then
                levelTag = string.format("[%s%02d|r]", levelColor, level)
            end
        end
        
        -- 构建格式化消息（包含等级标签）
        local prefix = self.db.profile.prefix ~= "" and "["..self.db.profile.prefix.."] " or ""
        local msg = string.gsub(arg1, "|r", "|r|cff"..self.db.profile.colour)
        local output = string.format(
            "|cff%s%s%s|cff%s|Hplayer:%s|h[%s]|h|r|cff%s %s",
            self.db.profile.colour,
            prefix,
            levelTag,  -- 插入等级标签
            self.db.profile.colour,
            playerName, playerName,
            self.db.profile.colour,
            msg
        )
        
        -- 输出到指定聊天窗口
        local chatFrame = _G["ChatFrame"..self.db.profile.frame]
        if chatFrame then
            chatFrame:AddMessage(output)
        end
        
        self.db.profile.spam = arg1  -- 更新缓存
        return false
    end
    
    -- 其他事件交给原始处理函数
    return self.originalChatFrame_OnEvent(event)
end

------------------------------
--      命令行支持          --
------------------------------

SLASH_AUTOMATON_HCFILTER1, SLASH_AUTOMATON_HCFILTER2 = "/HCF", "/HCFilter"
SlashCmdList["AUTOMATON_HCFILTER"] = function(message)
    local args = {}
    for arg in string.gmatch(message, "%S+") do
        table.insert(args, arg)
    end
    
  local argsCount = 0
  for _ in ipairs(args) do
      argsCount = argsCount + 1
  end
  if argsCount == 0 then
      Automaton_HCFilter:print("可用命令: frame [编号], prefix [文本], colour [代码]")
      return
  end
    
    -- 处理帧设置
    if args[1] == "frame" and args[2] then
        local frame = tonumber(args[2])
        if frame and frame >=1 and frame <=9 then
            Automaton_HCFilter.db.profile.frame = frame
            Automaton_HCFilter:print("聊天窗口已设置为: "..frame)
        else
            Automaton_HCFilter:print("无效的窗口编号 (1-9)")
        end
    -- 处理前缀设置
    elseif args[1] == "prefix" then
        Automaton_HCFilter.db.profile.prefix = args[2] or ""
        Automaton_HCFilter:print("前缀已设置为: "..(args[2] or "无"))
    -- 处理颜色设置
    elseif args[1] == "colour" or args[1] == "color" then
        if args[2] then
            Automaton_HCFilter.db.profile.colour = args[2]
            Automaton_HCFilter:print("颜色代码已设置为: "..args[2])
        else
            Automaton_HCFilter.db.profile.colour = "e6cd80"  -- 恢复默认
            Automaton_HCFilter:print("颜色已恢复默认: e6cd80")
        end
    else
        Automaton_HCFilter:print("无效命令，请使用 /HCF 查看帮助")
    end
end