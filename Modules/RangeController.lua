assert(Automaton, "Automaton not found!")

------------------------------
--      Localization      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_RangeController")


L:RegisterTranslations("zhCN", function() return {
	["RangeController"] = "战斗记录范围控制器",
	["Set combat log recording range"] = "设置战斗记录收集范围，控制战斗记录的收集距离，小退后会重置",
	["Range Value"] = "范围值",
	["Set the combat log recording range (0-200)"] = "设置战斗记录范围值 (0-200)",
	["Apply Range"] = "应用范围",
	["Apply the selected range value"] = "应用选中的范围值",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

Automaton_RangeController = Automaton:NewModule("RangeController")
Automaton_RangeController.modulename = L["RangeController"]
Automaton_RangeController.moduledesc = L["Set combat log recording range"]
Automaton_RangeController.options = {
	rangeValue = {
		type = "range",
		name = L["Range Value"],
		desc = L["Set the combat log recording range (0-200)"],
		get = function() 
			-- 从当前值读取，而不是数据库
			return Automaton_RangeController.currentRange or 150
		end,
		set = function(v) 
			-- 只设置当前值，不保存到数据库
			Automaton_RangeController.currentRange = v
		end,
		min = 0,
		max = 200,
		step = 5,
		bigStep = 10,
	},
	applyRange = {
		type = "execute",
		name = L["Apply Range"],
		desc = L["Apply the selected range value"],
		func = function()
			Automaton_RangeController:ApplyRangeSettings()
		end,
	},
	enabled = {
		type = "toggle",
		name = "启用模块",
		desc = "启用/禁用战斗记录范围控制器",
		get = function() return not Automaton_RangeController.db.profile.disabled end,
		set = function(v) 
			Automaton_RangeController.db.profile.disabled = not v 
			if v then
				Automaton_RangeController:OnEnable()
			else
				Automaton_RangeController:OnDisable()
			end
		end,
	}
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_RangeController:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("RangeController")
	Automaton:RegisterDefaults("RangeController", "profile", {
		disabled = false,
		-- 移除rangeValue的默认值设置，因为它不再保存
	})
	Automaton:SetDisabledAsDefault(self, "RangeController")
	self:RegisterOptions(self.options)
	
	-- 初始化当前范围为默认值150
	self.currentRange = 150
end

function Automaton_RangeController:OnEnable()
	-- 此模块已移除斜杠命令功能
end

function Automaton_RangeController:OnDisable()
	-- 此模块已移除斜杠命令功能
end

function Automaton_RangeController:ApplyRangeSettings()
	-- 使用当前范围值，而不是数据库中的值
	local range = self.currentRange or 150
	
	-- 设置战斗记录范围的命令
	local commands = {
		'CombatLogRangeHostilePlayers',
		'CombatLogRangeHostilePlayersPets',
		'CombatLogRangeParty',
		'CombatLogRangePartyPet',
		'CombatLogRangeFriendlyPlayers',
		'CombatLogRangeFriendlyPlayersPets',
		'CombatLogRangeCreature',
		'CombatDeathLogRange',
		'CombatModeMaxDistance'
	}
	
	-- 执行所有命令
	for _, cvar in ipairs(commands) do
		-- 使用 SetCVar 来设置控制台变量
		SetCVar(cvar, range)
	end
	
	print(string.format("|cFF00FF00[范围控制器] 战斗记录范围已设置为 %d 码|r", range))
end