local Automaton_ChatEnhancer = Automaton:NewModule("ChatEnhancer")
Automaton_ChatEnhancer.modulename = "聊天增强"
Automaton_ChatEnhancer.moduledesc = "提供聊天关键字高亮、屏蔽、弹窗和硬核模式消息格式化功能，有Chatmod可禁用此模块"

-- 获取玩家名称
local playerName = UnitName('player')
local lastPopupText = "" -- 用于防止重复弹窗

-- 星期几的映射表
local WeekDays = {
    ["Mon"] = "一",
    ["Tue"] = "二",
    ["Wed"] = "三",
    ["Thu"] = "四",
    ["Fri"] = "五",
    ["Sat"] = "六",
    ["Sun"] = "日",
    ["Monday"] = "一",
    ["Tuesday"] = "二",
    ["Wednesday"] = "三",
    ["Thursday"] = "四",
    ["Friday"] = "五",
    ["Saturday"] = "六",
    ["Sunday"] = "日"
}

-- 默认颜色配置
local DEFAULT_COLORS = {
    highlight = { 0.96, 0.51, 0.13 }, -- F58220
    hardcore = { 0.90, 0.80, 0.50 }   -- e6cd80
}

-- 点击邀请功能配置
Automaton_ChatEnhancer.inviteKeywords = {"inv", "invite", "组我", "组", "求组", "组队"}
local originalSetItemRef = SetItemRef

-- 颜色选择器回调函数 - 修正：只在确定时保存
local function ColorPickerCallback(restore, colorType)
    local r, g, b
    
    if restore then
        -- 用户点击取消，恢复旧颜色
        r, g, b = unpack(restore)
        if colorType == "highlight" then
            Automaton_ChatEnhancer.db.profile.highlightColour = { r, g, b }
        elseif colorType == "hardcore" then
            Automaton_ChatEnhancer.db.profile.hcColour = { r, g, b }
        end
    else
        -- 用户点击确定，使用新颜色
        r, g, b = ColorPickerFrame:GetColorRGB()
        if colorType == "highlight" then
            Automaton_ChatEnhancer.db.profile.highlightColour = { r, g, b }
            Automaton_ChatEnhancer:Print("高亮颜色已更新")
        elseif colorType == "hardcore" then
            Automaton_ChatEnhancer.db.profile.hcColour = { r, g, b }
            Automaton_ChatEnhancer:Print("硬核频道颜色已更新")
        end
    end
end

-- 显示颜色选择器 - 修正：正确设置回调
local function ShowColorPicker(color, colorType)
    local r, g, b = unpack(color)
    
    -- 保存旧颜色用于恢复
    local oldColor = { r, g, b }
    
    -- 设置颜色选择器
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame.hasOpacity = false
    
    -- 设置确定和取消回调
    ColorPickerFrame.func = function()
        ColorPickerCallback(nil, colorType)
    end
    
    ColorPickerFrame.cancelFunc = function()
        ColorPickerCallback(oldColor, colorType)
    end
    
    -- 不设置opacityFunc，避免颜色改变时触发回调
    ColorPickerFrame.opacityFunc = nil
    ColorPickerFrame:Show()
end

-- 重置颜色到默认值
local function ResetColor(colorType)
    if colorType == "highlight" then
        Automaton_ChatEnhancer.db.profile.highlightColour = { unpack(DEFAULT_COLORS.highlight) }
        Automaton_ChatEnhancer:Print("高亮颜色已重置为默认值")
    elseif colorType == "hardcore" then
        Automaton_ChatEnhancer.db.profile.hcColour = { unpack(DEFAULT_COLORS.hardcore) }
        Automaton_ChatEnhancer:Print("硬核频道颜色已重置为默认值")
    end
end

-- RGB值转换为十六进制颜色字符串
local function RGBToHex(rgb)
    local r = math.floor(rgb[1] * 255 + 0.5)
    local g = math.floor(rgb[2] * 255 + 0.5)
    local b = math.floor(rgb[3] * 255 + 0.5)
    return string.format("%02x%02x%02x", r, g, b)
end

-- 配置选项
Automaton_ChatEnhancer.options = {
    keywords = {
        type = "group",
        name = "关键字设置",
        desc = "高亮、屏蔽和弹窗关键字设置",
        args = {
            -- 高亮关键字设置
            highlight_header = {
                type = "header",
                name = "高亮关键字",
                order = 1,
            },
            highlight_colour = {
                type = "execute",
                name = "选择高亮颜色",
                desc = "点击打开颜色选择器设置高亮关键字颜色",
                order = 2,
                func = function()
                    ShowColorPicker(Automaton_ChatEnhancer.db.profile.highlightColour, "highlight")
                end,
            },
            highlight_colour_reset = {
                type = "execute",
                name = "重置高亮颜色",
                desc = "重置高亮颜色为默认值",
                order = 3,
                func = function()
                    ResetColor("highlight")
                end,
            },
            highlight_colour_preview = {
                type = "description",
                name = function()
                    local hex = RGBToHex(Automaton_ChatEnhancer.db.profile.highlightColour)
                    return "当前高亮颜色: |cff" .. hex .. "■" .. hex .. "|r"
                end,
                order = 4,
            },
            highlight_list = {
                type = "execute",
                name = "打印高亮关键字",
                desc = "打印输出所有已经保存的高亮关键字列表",
                order = 5,
                func = function() 
                    if table.getn(Automaton_ChatEnhancer.db.profile.highlightKeywords) == 0 then
                        Automaton_ChatEnhancer:Print("高亮关键字列表为空")
                    else
                        Automaton_ChatEnhancer:Print("高亮关键字:")
                        for _, v in ipairs(Automaton_ChatEnhancer.db.profile.highlightKeywords) do
                            Automaton_ChatEnhancer:Print("- " .. v)
                        end
                    end
                end
            },
            highlight_add = {
                type = "text",
                name = "添加高亮关键字",
                desc = "添加高亮关键字，按回车确认",
                usage = "<关键字>",
                order = 6,
                get = false,
                set = function(v) 
                    if v and v ~= "" then
                        table.insert(Automaton_ChatEnhancer.db.profile.highlightKeywords, v)
                        Automaton_ChatEnhancer:Print("已添加高亮关键字: " .. v)
                    end
                end,
            },
            highlight_remove = {
                type = "text",
                name = "删除高亮关键字",
                desc = "删除高亮关键字，按回车确认",
                usage = "<关键字>",
                order = 7,
                get = false,
                set = function(v) 
                    for i, keyword in ipairs(Automaton_ChatEnhancer.db.profile.highlightKeywords) do
                        if keyword == v then
                            table.remove(Automaton_ChatEnhancer.db.profile.highlightKeywords, i)
                            Automaton_ChatEnhancer:Print("已删除高亮关键字: " .. v)
                            return
                        end
                    end
                    Automaton_ChatEnhancer:Print("未找到高亮关键字: " .. v)
                end,
            },
            highlight_clear = {
                type = "execute",
                name = "清除所有高亮关键字",
                desc = "清除所有高亮关键字",
                order = 8,
                func = function()
                    local count = table.getn(Automaton_ChatEnhancer.db.profile.highlightKeywords)
                    Automaton_ChatEnhancer.db.profile.highlightKeywords = {}
                    Automaton_ChatEnhancer:Print("已清除所有高亮关键字 (" .. count .. "个)")
                end
            },
            
            -- 高亮关键字弹窗设置
            highlight_alert_header = {
                type = "header",
                name = "高亮关键字弹窗设置",
                order = 9,
            },
            highlight_alert_enable = {
                type = "toggle",
                name = "高亮关键字弹窗",
                desc = "启用后，高亮关键字同时也会触发弹窗",
                order = 10,
                get = function() return Automaton_ChatEnhancer.db.profile.highlightAlertEnabled end,
                set = function(v) Automaton_ChatEnhancer.db.profile.highlightAlertEnabled = v end,
            },
            highlight_alert_in_combat = {
                type = "toggle",
                name = "战斗中弹窗",
                desc = "启用后，高亮关键字在战斗中也触发弹窗",
                order = 11,
                get = function() return Automaton_ChatEnhancer.db.profile.highlightAlertInCombat end,
                set = function(v) Automaton_ChatEnhancer.db.profile.highlightAlertInCombat = v end,
            },
            
            -- 分隔线
            separator = {
                type = "header",
                name = "屏蔽关键字",
                order = 12,
            },
            
            -- 屏蔽关键字设置
            checkName = {
                type = "toggle",
                name = "检查角色名",
                desc = "是否同时对角色名进行关键字检查",
                order = 13,
                get = function() return Automaton_ChatEnhancer.db.profile.checkName end,
                set = function(v) Automaton_ChatEnhancer.db.profile.checkName = v end,
            },
            filter_list = {
                type = "execute",
                name = "打印屏蔽关键字",
                desc = "打印输出所有已经保存的屏蔽关键字列表",
                order = 14,
                func = function() 
                    if table.getn(Automaton_ChatEnhancer.db.profile.filterKeywords) == 0 then
                        Automaton_ChatEnhancer:Print("屏蔽关键字列表为空")
                    else
                        Automaton_ChatEnhancer:Print("屏蔽关键字:")
                        for _, v in ipairs(Automaton_ChatEnhancer.db.profile.filterKeywords) do
                            Automaton_ChatEnhancer:Print("- " .. v)
                        end
                    end
                end
            },
            filter_add = {
                type = "text",
                name = "添加屏蔽关键字",
                desc = "添加屏蔽关键字，按回车确认",
                usage = "<关键字>",
                order = 15,
                get = false,
                set = function(v) 
                    if v and v ~= "" then
                        table.insert(Automaton_ChatEnhancer.db.profile.filterKeywords, v)
                        Automaton_ChatEnhancer:Print("已添加屏蔽关键字: " .. v)
                    end
                end,
            },
            filter_remove = {
                type = "text",
                name = "删除屏蔽关键字",
                desc = "删除屏蔽关键字，按回车确认",
                usage = "<关键字>",
                order = 16,
                get = false,
                set = function(v) 
                    for i, keyword in ipairs(Automaton_ChatEnhancer.db.profile.filterKeywords) do
                        if keyword == v then
                            table.remove(Automaton_ChatEnhancer.db.profile.filterKeywords, i)
                            Automaton_ChatEnhancer:Print("已删除屏蔽关键字: " .. v)
                            return
                        end
                    end
                    Automaton_ChatEnhancer:Print("未找到屏蔽关键字: " .. v)
                end,
            },
            filter_clear = {
                type = "execute",
                name = "清除所有屏蔽关键字",
                desc = "清除所有屏蔽关键字",
                order = 17,
                func = function()
                    local count = table.getn(Automaton_ChatEnhancer.db.profile.filterKeywords)
                    Automaton_ChatEnhancer.db.profile.filterKeywords = {}
                    Automaton_ChatEnhancer:Print("已清除所有屏蔽关键字 (" .. count .. "个)")
                end
            }
        },
    },
    hardcore = {
        type = "group",
        name = "硬核模式",
        desc = "硬核聊天消息格式化设置",
        args = {
            frame = {
                type = "range",
                name = "聊天窗口",
                desc = "设置硬核消息显示的聊天窗口编号",
                min = 1,
                max = 9,
                step = 1,
                get = function() return Automaton_ChatEnhancer.db.profile.hcFrame end,
                set = function(v) Automaton_ChatEnhancer.db.profile.hcFrame = v end,
            },
            prefix = {
                type = "text",
                name = "前缀文本",
                desc = "设置硬核消息的前缀标识",
                get = function() return Automaton_ChatEnhancer.db.profile.hcPrefix end,
                set = function(v) Automaton_ChatEnhancer.db.profile.hcPrefix = v end,
            },
            colour = {
                type = "execute",
                name = "选择硬核频道颜色",
                desc = "点击打开颜色选择器设置硬核频道颜色",
                order = 1,
                func = function()
                    ShowColorPicker(Automaton_ChatEnhancer.db.profile.hcColour, "hardcore")
                end,
            },
            colour_reset = {
                type = "execute",
                name = "重置硬核频道颜色",
                desc = "重置硬核频道颜色为默认值",
                order = 2,
                func = function()
                    ResetColor("hardcore")
                end,
            },
            colour_preview = {
                type = "description",
                name = function()
                    local hex = RGBToHex(Automaton_ChatEnhancer.db.profile.hcColour)
                    return "当前硬核频道颜色: |cff" .. hex .. "■" .. hex .. "|r"
                end,
                order = 3,
            }
        }
    },
    -- 新增功能设置
    additional_features = {
        type = "group",
        name = "增强功能",
        desc = "额外的聊天增强功能",
        args = {
            highlight_roll = {
                type = "toggle",
                name = "高亮自己的ROLL点信息",
                desc = "高亮显示自己的roll点信息，包括装绑自动ROLL点和自己手动ROLL点信息",
                order = 1,
                get = function() return Automaton_ChatEnhancer.db.profile.highlightRoll end,
                set = function(v) Automaton_ChatEnhancer.db.profile.highlightRoll = v end,
            },
            mention_popup = {
                type = "toggle",
                name = "弹窗显示有自己名字的聊天",
                desc = "当聊天中包含自己的名字时屏幕中间弹窗显示",
                order = 2,
                get = function() return Automaton_ChatEnhancer.db.profile.mentionPopup end,
                set = function(v) Automaton_ChatEnhancer.db.profile.mentionPopup = v end,
            },
            mention_in_combat = {
                type = "toggle",
                name = "提到名字时战斗中弹窗",
                desc = "启用后，提到自己名字时在战斗中也触发弹窗",
                order = 3,
                get = function() return Automaton_ChatEnhancer.db.profile.mentionInCombat end,
                set = function(v) Automaton_ChatEnhancer.db.profile.mentionInCombat = v end,
            },
            -- 点击邀请功能设置
            click_invite_header = {
                type = "header",
                name = "点击邀请功能",
                order = 20,
            },
            click_invite_enable = {
                type = "toggle",
                name = "启用点击邀请",
                desc = "启用后，聊天中的关键字会被转换为可点击的组队邀请链接",
                order = 21,
                get = function() return Automaton_ChatEnhancer.db.profile.clickInvite end,
                set = function(v) Automaton_ChatEnhancer.db.profile.clickInvite = v end,
            },
            click_invite_keywords = {
                type = "group",
                name = "邀请关键字设置",
                desc = "设置点击邀请功能的关键字",
                order = 22,
                disabled = function() return not Automaton_ChatEnhancer.db.profile.clickInvite end,
                args = {
                    list_keywords = {
                        type = "execute",
                        name = "打印关键字列表",
                        desc = "打印所有点击邀请关键字",
                        func = function() Automaton_ChatEnhancer:PrintInviteKeywords() end
                    },
                    add_keyword = {
                        type = "text",
                        name = "添加关键字",
                        desc = "添加点击邀请关键字",
                        order = 1,
                        usage = "<关键字>",
                        get = false,
                        set = function(v) Automaton_ChatEnhancer:AddInviteKeyword(v) end,
                    },
                    remove_keyword = {
                        type = "text",
                        name = "删除关键字",
                        desc = "删除点击邀请关键字",
                        order = 2,
                        usage = "<关键字>",
                        get = false,
                        set = function(v) Automaton_ChatEnhancer:RemoveInviteKeyword(v) end,
                    },
                    clear_keywords = {
                        type = "execute",
                        name = "清空关键字",
                        desc = "清空所有点击邀请关键字",
                        func = function() Automaton_ChatEnhancer:ClearInviteKeywords() end
                    }
                }
            },
            -- 新增硬核死亡消息设置
            hardcore_death_header = {
                type = "header",
                name = "硬核死亡消息设置",
                order = 5,
            },
            hardcore_death_highlight = {
                type = "toggle",
                name = "高亮硬核死亡消息",
                desc = "高亮显示硬核角色死亡消息中的玩家名称、怪物名称和地点",
                order = 6,
                get = function() return Automaton_ChatEnhancer.db.profile.hardcoreDeathHighlight end,
                set = function(v) Automaton_ChatEnhancer.db.profile.hardcoreDeathHighlight = v end,
            },
            hardcore_death_popup = {
                type = "toggle",
                name = "弹窗显示硬核死亡消息",
                desc = "当出现硬核角色死亡消息时屏幕中间弹窗显示",
                order = 7,
                get = function() return Automaton_ChatEnhancer.db.profile.hardcoreDeathPopup end,
                set = function(v) Automaton_ChatEnhancer.db.profile.hardcoreDeathPopup = v end,
            },
            hardcore_death_in_combat = {
                type = "toggle",
                name = "硬核死亡消息战斗中弹窗",
                desc = "启用后，硬核死亡消息在战斗中也触发弹窗",
                order = 8,
                get = function() return Automaton_ChatEnhancer.db.profile.hardcoreDeathInCombat end,
                set = function(v) Automaton_ChatEnhancer.db.profile.hardcoreDeathInCombat = v end,
            }
        }
    }
}

-- 数据库初始化
function Automaton_ChatEnhancer:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("ChatEnhancer")
    Automaton:RegisterDefaults("ChatEnhancer", "profile", {
        highlightKeywords = {},
        filterKeywords = {},
        checkName = false,
        hcFrame = 1,
        hcPrefix = "HC",
        hcColour = { 0.90, 0.80, 0.50 }, -- e6cd80
        hcSpam = "",
        highlightColour = { 0.96, 0.51, 0.13 }, -- F58220
        enabled = true,
        highlightRoll = true,
        mentionPopup = true,
        mentionInCombat = true, -- 提到名字时战斗中弹窗
        highlightAlertEnabled = false, -- 高亮关键字弹窗
        highlightAlertInCombat = false, -- 高亮关键字战斗中弹窗
        hardcoreDeathHighlight = true, -- 硬核死亡消息高亮
        hardcoreDeathPopup = false, -- 硬核死亡消息弹窗
        hardcoreDeathInCombat = false, -- 硬核死亡消息战斗中弹窗
        clickInvite = true, -- 点击邀请功能
        inviteKeywords = {"inv", "invite", "组我", "组", "求组", "组队", "1"}, -- 点击邀请关键字
    })
    Automaton:SetDisabledAsDefault(self, "ChatEnhancer")
    self:RegisterOptions(self.options)
end

-- 点击邀请功能管理函数
function Automaton_ChatEnhancer:AddInviteKeyword(keyword)
    table.insert(self.db.profile.inviteKeywords, keyword)
    self:Print("已添加邀请关键字: " .. keyword)
end

function Automaton_ChatEnhancer:RemoveInviteKeyword(keyword)
    local newKeywords = {}
    for _, v in ipairs(self.db.profile.inviteKeywords) do
        if v ~= keyword then
            table.insert(newKeywords, v)
        end
    end
    self.db.profile.inviteKeywords = newKeywords
    self:Print("已移除邀请关键字: " .. keyword)
end

function Automaton_ChatEnhancer:PrintInviteKeywords()
    if table.getn(self.db.profile.inviteKeywords) == 0 then
        self:Print("邀请关键字列表为空")
    else
        self:Print("邀请关键字列表:")
        for _, v in ipairs(self.db.profile.inviteKeywords) do
            self:Print("- " .. v)
        end
    end
end

function Automaton_ChatEnhancer:ClearInviteKeywords()
    local count = table.getn(self.db.profile.inviteKeywords)
    self.db.profile.inviteKeywords = {}
    self:Print("已清空所有邀请关键字 (" .. count .. "个)")
end

-- 处理点击邀请链接
local function ProcessClickInvite(msg, sender)
    if not msg or not sender then return msg end
    
    -- 跳过自己发送的消息
    if sender == UnitName("player") then return msg end
    
    -- 跳过已经在团队/小队中的消息
    local event = event or ""
    if event and (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING") then
        return msg
    end
    
    local foundInvite = false
    
    -- 检查所有关键字
    for _, keyword in ipairs(Automaton_ChatEnhancer.db.profile.inviteKeywords) do
        if not foundInvite then
            -- 更灵活的模式匹配，处理中文和英文
            local patterns = {
                "%s+(" .. keyword .. ")([%s%p]?)$",  -- 空格 + 关键字 + 可选标点/空格 + 结尾
                "%s+(" .. keyword .. ")([%s%p]?)%s", -- 空格 + 关键字 + 可选标点/空格 + 空格
                "^(" .. keyword .. ")([%s%p]?)%s",   -- 开头 + 关键字 + 可选标点/空格 + 空格
                "^(" .. keyword .. ")([%s%p]?)$",    -- 开头 + 关键字 + 可选标点/空格 + 结尾
            }
            
            for _, pattern in ipairs(patterns) do
                if not foundInvite then
                    local replacement = function(match, trail)
                        if (trail == nil or trail == " " or trail == "" or trail == "。" or trail == "!" or trail == "?" or trail == ".") then
                            foundInvite = true
                            return " |Hinvite:" .. sender .. "|h[|cffffff00" .. match .. "|r]|h" .. (trail or "")
                        else
                            return " " .. match .. trail
                        end
                    end
                    
                    local newMsg, count = string.gsub(msg, pattern, replacement, 1)
                    if count > 0 then
                        msg = newMsg
                        break
                    end
                end
            end
        end
    end
    
    return msg
end

-- 修改SetItemRef以处理点击邀请
local function HookedSetItemRef(link, text, button)
    if string.sub(link, 1, 6) == "invite" then
        local playerName = string.sub(link, 8)
        InviteByName(playerName)
    else
        originalSetItemRef(link, text, button)
    end
end

-- 获取聊天频道名称
function Automaton_ChatEnhancer:GetChatChannelName(event)
    local channelMap = {
        ["CHAT_MSG_SAY"] = "说",
        ["CHAT_MSG_YELL"] = "喊",
        ["CHAT_MSG_PARTY"] = "队伍",
        ["CHAT_MSG_PARTY_LEADER"] = "队伍",
        ["CHAT_MSG_RAID"] = "团队",
        ["CHAT_MSG_RAID_LEADER"] = "团队",
        ["CHAT_MSG_RAID_WARNING"] = "团队警告",
        ["CHAT_MSG_GUILD"] = "公会",
        ["CHAT_MSG_OFFICER"] = "官员",
        ["CHAT_MSG_WHISPER"] = "密语",
        ["CHAT_MSG_WHISPER_INFORM"] = "密语",
        ["CHAT_MSG_CHANNEL"] = "频道",
        ["CHAT_MSG_SYSTEM"] = "系统",
    }
    
    return channelMap[event] or "未知"
end

-- 显示弹窗（使用UIErrorsFrame）- 使用默认颜色，包含频道信息
function Automaton_ChatEnhancer:ShowAlert(message, sender, keyword, alertType, channel)
    -- 检查是否在战斗中
    local inCombat = UnitAffectingCombat("player")
    if inCombat then
        if alertType == "highlight" and not self.db.profile.highlightAlertInCombat then
            return
        elseif alertType == "mention" and not self.db.profile.mentionInCombat then
            return
        elseif alertType == "hardcore_death" and not self.db.profile.hardcoreDeathInCombat then
            return
        end
    end
    
    -- 防止重复弹窗
    local popupText = sender .. ": " .. message
    if popupText == lastPopupText then
        return
    end
    
    -- 对消息中的关键字应用自定义高亮颜色
    local highlightedMessage = self:ApplyHighlightToText(message)
    
    -- 使用UIErrorsFrame显示弹窗，格式为：[频道] 发送者: 消息内容
    local alertText = string.format("[%s] %s: %s", channel or "未知", sender or "未知", highlightedMessage)
    UIErrorsFrame:AddMessage(alertText)
    
    lastPopupText = popupText
end

-- 显示提到自己的弹窗（使用UIErrorsFrame）- 使用默认颜色，包含频道信息
function Automaton_ChatEnhancer:ShowMentionAlert(message, sender, channel)
    if not self.db.profile.mentionPopup then
        return
    end
    
    -- 检查是否在战斗中
    if UnitAffectingCombat("player") and not self.db.profile.mentionInCombat then
        return
    end
    
    -- 防止重复弹窗
    local popupText = sender .. ": " .. message
    if popupText == lastPopupText then
        return
    end
    
    -- 在弹窗中高亮自己的名字，使用自定义颜色并加上红色的》《标记
    local formattedMessage = self:HighlightPlayerName(message)
    
    -- 对消息中的关键字应用自定义高亮颜色
    formattedMessage = self:ApplyHighlightToText(formattedMessage)
    
    -- 使用UIErrorsFrame显示弹窗，格式为：[频道] 发送者 消息内容
    local alertText = string.format("[%s] %s  %s", channel or "未知", sender or "未知", formattedMessage)
    UIErrorsFrame:AddMessage(alertText)
    
    -- 播放声音
    PlaySound("FriendJoinGame");
    
    lastPopupText = popupText
end

-- 显示硬核死亡消息弹窗
function Automaton_ChatEnhancer:ShowHardcoreDeathAlert(message, sender, channel)
    if not self.db.profile.hardcoreDeathPopup then
        return
    end
    
    -- 检查是否在战斗中
    if UnitAffectingCombat("player") and not self.db.profile.hardcoreDeathInCombat then
        return
    end
    
    -- 防止重复弹窗
    local popupText = sender .. ": " .. message
    if popupText == lastPopupText then
        return
    end
    
    -- 对硬核死亡消息应用特殊高亮
    local formattedMessage = self:ApplyHardcoreDeathHighlight(message)
    
    -- 使用UIErrorsFrame显示弹窗，格式为：消息内容
    local alertText = string.format("%s  %s", sender or "未知", formattedMessage)
    UIErrorsFrame:AddMessage(alertText)
    
    -- 播放特殊声音
    PlaySound("FriendJoinGame");
    
    lastPopupText = popupText
end

-- 检查高亮关键字弹窗
function Automaton_ChatEnhancer:CheckHighlightAlert(text, sender, channel)
    if not self.db.profile.highlightAlertEnabled or table.getn(self.db.profile.highlightKeywords) == 0 then
        return false
    end
    
    local found = false
    for _, keyword in ipairs(self.db.profile.highlightKeywords) do
        if keyword and keyword ~= "" and string.find(string.lower(text), string.lower(keyword), 1, true) then
            self:ShowAlert(text, sender, keyword, "highlight", channel)
            found = true
        end
    end
    
    return found
end

-- 检查是否提到自己 - 已集成宠物排除逻辑
function Automaton_ChatEnhancer:CheckMention(text, sender, channel, event)
    if not self.db.profile.mentionPopup or sender == playerName then
        return false
    end
    
    -- 排除战斗日志中的宠物信息 (arg8 为 3 或 4)
    if arg8 == 3 or arg8 == 4 then
        return false
    end
    
    -- 检查消息长度是否足够
    if not text or not playerName or string.len(text) < string.len(playerName) then
        return false
    end
    
    local lowerPlayerName = string.lower(playerName)
    local lowerText = string.lower(text)
    
    -- 排除括号中的玩家名（如宠物技能中的玩家名）
    if string.find(lowerText, "%(" .. lowerPlayerName .. "%)") then
        return false
    end
    
    -- 排除宠物、图腾等相关信息
    if self.db.profile.ignorePetActions and self:IsPetOrTotemEvent(event, text, sender) then
        return false
    end
    
    -- 检查是否包含玩家名
    if string.find(lowerText, lowerPlayerName, 1, true) then
        self:ShowMentionAlert(text, sender, channel)
        return true
    end
    
    return false
end

-- 检查硬核死亡消息
function Automaton_ChatEnhancer:CheckHardcoreDeath(text, sender, channel)
    -- 检查是否是硬核死亡消息
    -- 原有的被怪物击杀格式
    local player, playerLevel, npc, npcLevel, zone = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (%d+)）被 (.+)（等级 (%d+)）击杀。这发生在 (.+)。愿这一牺牲不会被忘记。")
    if player and playerLevel and npc and npcLevel and zone then
        self:ShowHardcoreDeathAlert(text, sender, channel)
        return true
    end
    
    -- 新增：自然死亡（年老去世）
    player, playerLevel, year = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (%d+)）于 (.+) 年因年老而去世。愿这一牺牲不会被忘记。")
    if player and playerLevel and year then
        self:ShowHardcoreDeathAlert(text, sender, channel)
        return true
    end
    
    -- 新增：PvP死亡
    player, playerLevel, killer, killerLevel, location = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (%d+)）在 PvP 中落败于 (.+)（等级 (%d+)）。这件事发生在 (.+)。愿这一牺牲不会被忘记。")
    if player and playerLevel and killer and killerLevel and location then
        self:ShowHardcoreDeathAlert(text, sender, channel)
        return true
    end
    
    -- 新增：溺水死亡
    player, playerLevel, location = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (%d+)）已在 (.+) 中溺亡。愿这一牺牲永不被遗忘。")
    if player and playerLevel and location then
        self:ShowHardcoreDeathAlert(text, sender, channel)
        return true
    end

    -- 新增：被活活烧死
    player, playerLevel, location = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (.+)）在 (.+) 被活活烧死。愿这一牺牲永不被遗忘。")
    if player and playerLevel and location then
        self:ShowHardcoreDeathAlert(text, sender, channel)
        return true
    end
    
    return false
end

-- 高亮自己的ROLL点信息
function Automaton_ChatEnhancer:HighlightRollInfo(text)
    if not self.db.profile.highlightRoll then
        return text
    end
    
    -- 检查随机ROLL点消息
    local unit, roll, from, to = string.match(text, "(.+)掷出(%d+)点%((%d+)%-(%d+)%)")
    if unit and roll and from and to and unit == playerName then
        return string.format("%s掷出|CFF00FFFF%s|r点（%s-%s）", unit, roll, from, to)
    end
    
    -- 检查装备ROLL点消息
    local typ, roll, item, name = string.match(text, "（(.+)）(%d+)点：(.+)（(.+)）")
    if name and name == playerName then
        return string.format("（%s）|CFF00FFFF%d|r点： %s （%s）", typ, roll, item, name)
    end
    
    return text
end

-- 模块启用
function Automaton_ChatEnhancer:OnEnable()
    -- 保存原始的事件处理函数
    self.OriginalChatFrame_OnEvent = ChatFrame_OnEvent
    
    -- 替换为我们的处理函数
    ChatFrame_OnEvent = function(event)
        Automaton_ChatEnhancer:ProcessChatEvent(event)
    end
    
    -- 钩住SetItemRef以处理点击邀请
    if not self.hookedSetItemRef then
        originalSetItemRef = SetItemRef
        SetItemRef = HookedSetItemRef
        self.hookedSetItemRef = true
    end
    
    self:Print("聊天增强已启用")
end

-- 模块禁用
function Automaton_ChatEnhancer:OnDisable()
    -- 恢复原始的事件处理函数
    if self.OriginalChatFrame_OnEvent then
        ChatFrame_OnEvent = self.OriginalChatFrame_OnEvent
    end
    
    -- 恢复原始的SetItemRef
    if self.hookedSetItemRef then
        SetItemRef = originalSetItemRef
        self.hookedSetItemRef = false
    end
    
    self:Print("聊天增强已禁用")
end

-- 处理聊天事件
function Automaton_ChatEnhancer:ProcessChatEvent(event)
    if not event then return end
    
    -- 处理硬核消息
    if event == "CHAT_MSG_HARDCORE" then
        self:ProcessHardcoreMessage()
        return
    end
    
    -- 只处理聊天消息事件
    if not string.find(event, "CHAT_MSG_") and event ~= "CHAT_MSG_SYSTEM" then
        return self.OriginalChatFrame_OnEvent(event)
    end
    
    local msg = arg1
    local sender = arg2 or ""
    local channel = self:GetChatChannelName(event)
    local specificChannel = (event == "CHAT_MSG_CHANNEL") and arg9 or nil -- 获取具体频道名称

    -- 检查是否为需要过滤的频道 (lft 和 pwb)
    local filteredChannels = {
        ["lft"] = true,
        ["pwb"] = true,
        -- 可以在这里添加其他需要过滤的频道
    }
    
    local isFilteredChannel = specificChannel and filteredChannels[string.lower(specificChannel)]
    
    -- 系统消息翻译
    if event == "CHAT_MSG_SYSTEM" then
        -- 翻译拍卖行押金消息
        if string.find(msg, "You paid a total of") and string.find(msg, "in Auction deposit") then
            local gold, silver, copper = string.match(msg, "You paid a total of (%d+)g (%d+)s (%d+)c in Auction deposit%.")
            if gold and silver and copper then
                msg = string.format("你在拍卖行支付了总计%s金%s银%s铜的押金。", gold, silver, copper)
                arg1 = msg
            end
        end

        -- 翻译跨阵营队伍提示
        if msg == "This party has members from both factions. Engaging in PvP or attacking PvP enabled NPCs in the open world is forbidden." then
            msg = "队伍中同时存在部落联盟角色，将禁止开放世界中参与PvP或攻击PvP的NPC。"
            arg1 = msg
        end
        
        -- 翻译交易物品消息
        if string.find(msg, " trades .* to .*%.") then
            local playerA, item, playerB = string.match(msg, "(.+) trades (.+) to (.+)%.")
            if playerA and item and playerB then
                msg = string.format("%s 将 %s 交易给了 %s。", playerA, item, playerB)
                arg1 = msg
            end
        end

        -- 翻译天赋点数使用限制提示
        if msg == "You have a talent spec with 48 out of 51 points spent. Using changing of specs as a free talent reset is not allowed." then
            msg = "你当前天赋专精已分配48/51点。不允许通过切换专精来免费重置天赋。"
            arg1 = msg
        end
        
        -- 新增汉化：硬核成就消息
        local playerName, _ = string.match(msg, "(.+) has transcended death and reached level 60 on Hardcore mode without dying once! (.+) shall henceforth be known as the %ammortal!")
        if playerName then
            msg = string.format("|cfff86256[HC]|r 硬核玩家|cff00ffff|Hplayer:%s|h[%s]|h|r超越死亡，在硬核挑战中达成 |cffff9c0060|r 级！|cffff00ff渡劫飞升|r！", playerName, playerName)
            arg1 = msg
        end
        
        local playerName, _ = string.match(msg, "(.+) has laughed in the face of death in the Hardcore challenge. (.+) has begun the Inferno Challenge!")
        if playerName then
            msg = string.format("|cfff86256[HC]|r硬核玩家 |cff00ffff|Hplayer:%s|h[%s]|h|r 完成\"笑面死亡\"任务，成为|cffff00ff炼狱尊者|r！", playerName, playerName)
            arg1 = msg
        end

        -- 新增汉化：硬核消息最小等级
        local minLevel = string.match(msg, "Minimum level for Hardcore messages is now: (%d+)")
        if minLevel then
            msg = string.format("硬核消息的最小等级现在为：%s", minLevel)
            arg1 = msg
        end
        
        -- 新增汉化：服务器时间
        local D, dd, mm, yyyy, HHmmss = string.match(msg, "Server Time: (%a+), (%d+)%.(%d+)%.(%d+) (%d+:%d+:%d+)")
        if D and dd and mm and yyyy and HHmmss then
            msg = string.format('服务器时间: 星期%s, %s-%s-%s %s', WeekDays[D] or D, yyyy, mm, dd, HHmmss)
            arg1 = msg
        end

        -- 新增：处理只有分钟和秒的情况（中文前缀）
        local uptimeMinutes, uptimeSeconds = string.match(msg, "服务器运行时间： (%d+) Minutes? (%d+) Seconds?%.")
        if uptimeMinutes and uptimeSeconds then
            msg = string.format("服务器运行时间：%s分钟%s秒", uptimeMinutes, uptimeSeconds)
            arg1 = msg
        else
            -- 新增：处理只有分钟和秒的情况（英文前缀）
            uptimeMinutes, uptimeSeconds = string.match(msg, "Server Uptime: (%d+) Minutes? (%d+) Seconds?%.")
            if uptimeMinutes and uptimeSeconds then
                msg = string.format("服务器运行时间：%s分钟%s秒", uptimeMinutes, uptimeSeconds)
                arg1 = msg
            end
        end
        
        -- 新增汉化：服务器运行时间
        local uptimeDays, uptimeHours, uptimeMinutes, uptimeSeconds = string.match(msg, "服务器运行时间： (%d+) Days? (%d+) Hours? (%d+) Minutes? (%d+) Seconds?%.")
        if uptimeDays and uptimeHours and uptimeMinutes and uptimeSeconds then
            msg = string.format("服务器运行时间：%s天%s小时%s分钟%s秒", uptimeDays, uptimeHours, uptimeMinutes, uptimeSeconds)
            arg1 = msg
        else
            -- 尝试匹配英文格式带天数
            uptimeDays, uptimeHours, uptimeMinutes, uptimeSeconds = string.match(msg, "Server Uptime: (%d+) Days? (%d+) Hours? (%d+) Minutes? (%d+) Seconds?%.")
            if uptimeDays and uptimeHours and uptimeMinutes and uptimeSeconds then
                msg = string.format("服务器运行时间：%s天%s小时%s分钟%s秒", uptimeDays, uptimeHours, uptimeMinutes, uptimeSeconds)
                arg1 = msg
            else
                -- 尝试匹配不带标点的格式带天数
                uptimeDays, uptimeHours, uptimeMinutes, uptimeSeconds = string.match(msg, "服务器运行时间： (%d+) Days? (%d+) Hours? (%d+) Minutes? (%d+) Seconds")
                if uptimeDays and uptimeHours and uptimeMinutes and uptimeSeconds then
                    msg = string.format("服务器运行时间：%s天%s小时%s分钟%s秒", uptimeDays, uptimeHours, uptimeMinutes, uptimeSeconds)
                    arg1 = msg
                else
                    -- 尝试匹配更简化的格式带天数
                    uptimeDays, uptimeHours, uptimeMinutes, uptimeSeconds = string.match(msg, "Server Uptime: (%d+) D (%d+) H (%d+) M (%d+) S")
                    if uptimeDays and uptimeHours and uptimeMinutes and uptimeSeconds then
                        msg = string.format("服务器运行时间：%s天%s小时%s分钟%s秒", uptimeDays, uptimeHours, uptimeMinutes, uptimeSeconds)
                        arg1 = msg
                    else
                        -- 原有不带天数的匹配（保留原有逻辑）
                        local uptimeHours, uptimeMinutes, uptimeSeconds = string.match(msg, "服务器运行时间： (%d+) Hours? (%d+) Minutes? (%d+) Seconds?%.")
                        if uptimeHours and uptimeMinutes and uptimeSeconds then
                            msg = string.format("服务器运行时间：%s小时%s分钟%s秒", uptimeHours, uptimeMinutes, uptimeSeconds)
                            arg1 = msg
                        else
                            -- 尝试匹配英文格式不带天数
                            uptimeHours, uptimeMinutes, uptimeSeconds = string.match(msg, "Server Uptime: (%d+) Hours? (%d+) Minutes? (%d+) Seconds?%.")
                            if uptimeHours and uptimeMinutes and uptimeSeconds then
                                msg = string.format("服务器运行时间：%s小时%s分钟%s秒", uptimeHours, uptimeMinutes, uptimeSeconds)
                                arg1 = msg
                            else
                                -- 尝试匹配不带标点的格式不带天数
                                uptimeHours, uptimeMinutes, uptimeSeconds = string.match(msg, "服务器运行时间： (%d+) Hours? (%d+) Minutes? (%d+) Seconds")
                                if uptimeHours and uptimeMinutes and uptimeSeconds then
                                    msg = string.format("服务器运行时间：%s小时%s分钟%s秒", uptimeHours, uptimeMinutes, uptimeSeconds)
                                    arg1 = msg
                                else
                                    -- 尝试匹配更简化的格式不带天数
                                    uptimeHours, uptimeMinutes, uptimeSeconds = string.match(msg, "Server Uptime: (%d+) H (%d+) M (%d+) S")
                                    if uptimeHours and uptimeMinutes and uptimeSeconds then
                                        msg = string.format("服务器运行时间：%s小时%s分钟%s秒", uptimeHours, uptimeMinutes, uptimeSeconds)
                                        arg1 = msg
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- 新增汉化：经验获取状态
        if msg == "XP gain is ON" then
            msg = "经验获取：开启"
            arg1 = msg
        elseif msg == "XP gain is OFF" then
            msg = "经验获取：关闭"
            arg1 = msg
        elseif msg == "XP gain is now ON" then
            msg = "经验获取：开启"
            arg1 = msg
        elseif msg == "XP gain is now OFF" then
            msg = "经验获取：关闭"
            arg1 = msg
        end

        -- 新增汉化：
        if msg == "If you enjoy Mysteries of Azeroth, please consider backing the project by visiting our website's donation page." then
            msg = "如果您喜欢《艾泽拉斯之谜》，请考虑通过访问我们网站的捐赠页面来支持该项目。"
            arg1 = msg
        elseif msg == "All gold transactions are heavily monitored. Any form of RMT will result in severe actions taken against all parties involved. Please, don't support individuals who are actively harming our server." then
            msg = "所有金币交易都受到严格监控，任何形式的现金交易（RMT）都将导致对所有相关方采取严厉措施，请勿支持那些蓄意损害我们服务器的人。"
            arg1 = msg
        elseif msg == "Tune in to Everlook Broadcasting Co. for music, news, live shows, and community events! Find the radio on your minimap. Broadcast schedule is available on our website." then
            msg = "欢迎收听永望镇广播公司，提供音乐、新闻、直播节目和社区活动！请在小地图上找到收音机。广播时间表请在我们的网站上查看。"
            arg1 = msg
        elseif msg == "Please note that you do not have to be logged in for your ticket to be completed. " then
            msg = "请注意，您无需登录即可完成您的工单。"
            arg1 = msg
        elseif msg == "Delete your WDB folder regularly. This is your game cache, and deleting it can often fix minor game glitches. Always try this before submitting a ticket." then
            msg = "请定期删除您的WDB文件夹。这是您的游戏缓存，删除它通常可以修复小故障。在提交工单前请先尝试此方法。"
            arg1 = msg
        end

        -- 翻译天赋专精保存和激活消息
        if msg == "Primary Specialization Saved." then
            msg = "天赋专精已保存。"
            arg1 = msg
        elseif msg == "Primary Specialization Activated." then
            msg = "主天赋专精已激活。"
            arg1 = msg
        elseif msg == "Secondary Specialization Activated." then
            msg = "副天赋专精已激活。"
            arg1 = msg
        end
    end
    
    -- 首先检查是否需要屏蔽
    if self:ShouldFilter(msg, sender) then
        return -- 直接返回，不处理此消息
    end
    
    -- 如果不是过滤频道，才执行高亮和弹窗功能
    if not isFilteredChannel then
        -- 检查硬核死亡消息
        local hardcoreDeathMatch = self:CheckHardcoreDeath(msg, sender, channel)
        
        -- 检查高亮关键字弹窗
        local highlightAlertMatch = self:CheckHighlightAlert(msg, sender, channel)
        
        -- 检查是否提到自己（传递 event 参数）
        local mentionMatch = self:CheckMention(msg, sender, channel, event)
        
        -- 高亮ROLL点信息
        msg = self:HighlightRollInfo(msg)
        
        -- 然后应用高亮
        local newText = self:ApplyHighlight(msg)
        if newText ~= msg then
            arg1 = newText
        end
        
        -- 如果匹配到高亮关键字弹窗或提到自己，在消息中高亮自己的名字（仅对提到自己时）
        if mentionMatch then
            arg1 = self:HighlightPlayerName(arg1)
        end
        
        -- 处理点击邀请功能
        if self.db.profile.clickInvite and self.db.profile.inviteKeywords and table.getn(self.db.profile.inviteKeywords) > 0 then
            local chatEvents = {
                "CHAT_MSG_SAY",
                "CHAT_MSG_YELL", 
                "CHAT_MSG_CHANNEL",
                "CHAT_MSG_GUILD",
                "CHAT_MSG_PARTY",
                "CHAT_MSG_RAID"
            }
            
            for _, chatEvent in ipairs(chatEvents) do
                if event == chatEvent then
                    arg1 = ProcessClickInvite(arg1, sender)
                    break
                end
            end
        end
    else
        -- 对于过滤频道，只进行基本的消息处理，不应用任何高亮或弹窗
        -- 但仍然可以处理系统消息翻译和屏蔽
    end
    
    -- 调用原始事件处理
    return self.OriginalChatFrame_OnEvent(event)
end

-- 处理硬核模式消息
function Automaton_ChatEnhancer:ProcessHardcoreMessage()
    -- 防刷屏检查
    if self.db.profile.hcSpam == arg1 then
        return
    end
    
    -- 超级忽略支持
    if IsAddOnLoaded("SuperIgnore") and SI_BannedGetIndex(arg2) then
        return self.OriginalChatFrame_OnEvent("CHAT_MSG_HARDCORE")
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
    local prefix = self.db.profile.hcPrefix ~= "" and "["..self.db.profile.hcPrefix.."] " or ""
    local hexColor = RGBToHex(self.db.profile.hcColour)
    local msg = string.gsub(arg1, "|r", "|r|cff"..hexColor)
    local output = string.format(
        "|cff%s%s%s|cff%s|Hplayer:%s|h[%s]|h|r|cff%s %s",
        hexColor,
        prefix,
        levelTag,  -- 插入等级标签
        hexColor,
        playerName, playerName,
        hexColor,
        msg
    )
    
    -- 输出到指定聊天窗口
    local chatFrame = _G["ChatFrame"..self.db.profile.hcFrame]
    if chatFrame then
        chatFrame:AddMessage(output)
    end
    
    self.db.profile.hcSpam = arg1  -- 更新缓存
end

-- 从文本中提取等级
function Automaton_ChatEnhancer:ExtractLevelFromText(text)
    -- 尝试从文本中提取等级信息
    local level = string.match(text, "level (%d+)")
    if level then
        return tonumber(level)
    end
    
    level = string.match(text, "等级 (%d+)")
    if level then
        return tonumber(level)
    end
    
    level = string.match(text, "(%d+) level")
    if level then
        return tonumber(level)
    end
    
    level = string.match(text, "(%d+) 级")
    if level then
        return tonumber(level)
    end
    
    -- 从死亡消息中提取等级
    level = string.match(text, "at level (%d+)")
    if level then
        return tonumber(level)
    end
    
    level = string.match(text, "（等级 (%d+)）")
    if level then
        return tonumber(level)
    end
    
    return nil
end

-- 检查是否需要过滤消息
function Automaton_ChatEnhancer:ShouldFilter(text, playerName)
    local checkText = text
    if self.db.profile.checkName then
        checkText = playerName .. " " .. text
    end
    
    for _, keyword in ipairs(self.db.profile.filterKeywords) do
        if keyword and keyword ~= "" and string.find(string.lower(checkText), string.lower(keyword), 1, true) then
            return true
        end
    end
    
    return false
end

-- 高亮玩家名字，使用自定义颜色并加上红色的》《标记
function Automaton_ChatEnhancer:HighlightPlayerName(text)
    local highlighted = text
    local hexColor = RGBToHex(self.db.profile.highlightColour)
    
    -- 使用自定义颜色高亮玩家名字，并加上红色的》《标记
    highlighted = string.gsub(highlighted, playerName, "|cffff0000》|r|cff" .. hexColor .. playerName .. "|r|cffff0000《|r")
    
    return highlighted
end

-- 应用硬核死亡消息高亮效果
function Automaton_ChatEnhancer:ApplyHardcoreDeathHighlight(text)
    if not self.db.profile.hardcoreDeathHighlight then
        return text
    end
    
    local highlighted = text
    
    -- 原有的被怪物击杀格式
    local player, playerLevel, npc, npcLevel, zone = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (%d+)）被 (.+)（等级 (%d+)）击杀。这发生在 (.+)。愿这一牺牲不会被忘记。")
    if player and playerLevel and npc and npcLevel and zone then
        -- 高亮玩家名称（橙色）、怪物名称（红色）和地点（绿色）
        highlighted = string.gsub(highlighted, player, "|cffff9c00" .. player .. "|r")
        highlighted = string.gsub(highlighted, npc, "|cfff86256" .. npc .. "|r")
        highlighted = string.gsub(highlighted, zone, "|cff00ff00" .. zone .. "|r")
        return highlighted
    end
    
    -- 新增：自然死亡（年老去世）
    player, playerLevel, year = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (%d+)）于 (.+) 年因年老（假死）而去世。愿这一牺牲不会被忘记。")
    if player and playerLevel and year then
        -- 高亮玩家名称（橙色）、年份（黄色）
        highlighted = string.gsub(highlighted, player, "|cffff9c00" .. player .. "|r")
        highlighted = string.gsub(highlighted, year, "|cffffff00" .. year .. "|r")
        return highlighted
    end
    
    -- 新增：PvP死亡
    player, playerLevel, killer, killerLevel, location = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (%d+)）在 PvP 中落败于 (.+)（等级 (%d+)）。这件事发生在 (.+)。愿这一牺牲不会被忘记。")
    if player and playerLevel and killer and killerLevel and location then
        -- 高亮玩家名称（橙色）、杀手名称（红色）、地点（绿色）
        highlighted = string.gsub(highlighted, player, "|cffff9c00" .. player .. "|r")
        highlighted = string.gsub(highlighted, killer, "|cfff86256" .. killer .. "|r")
        highlighted = string.gsub(highlighted, location, "|cff00ff00" .. location .. "|r")
        return highlighted
    end
    
    -- 新增：溺水死亡
    player, playerLevel, location = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (%d+)）已在 (.+) 中溺亡。愿这一牺牲永不被遗忘。")
    if player and playerLevel and location then
        -- 高亮玩家名称（橙色）、地点（蓝色，因为是溺水）
        highlighted = string.gsub(highlighted, player, "|cffff9c00" .. player .. "|r")
        highlighted = string.gsub(highlighted, location, "|cff00aaff" .. location .. "|r")
        return highlighted
    end

    -- 新增：被活活烧死
    player, playerLevel, location = string.match(text, "悲剧发生了。硬核角色 (.+)（等级 (.+)）在 (.+) 被活活烧死。愿这一牺牲永不被遗忘。")
    if player and playerLevel and location then
        -- 高亮玩家名称（橙色）、地点（红色，因为是被烧死）
        highlighted = string.gsub(highlighted, player, "|cffff9c00" .. player .. "|r")
        highlighted = string.gsub(highlighted, location, "|cffff3333" .. location .. "|r")
        return highlighted
    end
    
    return highlighted
end

-- 应用高亮效果 - 使用自定义颜色高亮关键字
function Automaton_ChatEnhancer:ApplyHighlight(text)
    local highlighted = text
    
    -- 应用硬核死亡消息高亮
    highlighted = self:ApplyHardcoreDeathHighlight(highlighted)
    
    -- 高亮关键字
    for _, keyword in ipairs(self.db.profile.highlightKeywords) do
        if keyword and keyword ~= "" then
            local hexColor = RGBToHex(self.db.profile.highlightColour)
            highlighted = string.gsub(highlighted, keyword, "|cff" .. hexColor .. keyword .. "|r")
        end
    end
    
    -- 特殊事件处理
    if(string.find(highlighted,"已被重置")) and (GetNumRaidMembers()>0 or GetNumPartyMembers()>0) then
        SendChatMessage('副本可以进了！','PARTY')
    end
    
    if(string.find(highlighted,"该副本中仍有玩家")) and (GetNumRaidMembers()>0 or GetNumPartyMembers()>0) then
        SendChatMessage('正在重置副本，请尽快出本！','PARTY')
    end    
    
    if(string.find(highlighted,"你获得了物品") and (string.find(highlighted,"正义宝珠") or string.find(highlighted,"骨火"))) then
        DoEmote("CHEER")
    end
    
    if(string.find(highlighted,"你获得了物品") and (string.find(highlighted,"黑莲花") or string.find(highlighted,"恶魔布"))) then
        DoEmote("CHEER")
    end    
    
    return highlighted
end

-- 对文本应用高亮效果（用于弹窗）- 使用自定义颜色高亮关键字
function Automaton_ChatEnhancer:ApplyHighlightToText(text)
    local highlighted = text
    
    for _, keyword in ipairs(self.db.profile.highlightKeywords) do
        if keyword and keyword ~= "" then
            local hexColor = RGBToHex(self.db.profile.highlightColour)
            -- 使用自定义颜色高亮关键字
            highlighted = string.gsub(highlighted, keyword, "|cff" .. hexColor .. keyword .. "|r")
        end
    end
    
    return highlighted
end

-- 打印消息
function Automaton_ChatEnhancer:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ChatEnhancer:|r " .. (msg or ""))
end