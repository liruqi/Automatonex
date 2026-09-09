assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_ExpShow")

local Automaton_ExpShow = Automaton:NewModule("ExpShow")
Automaton_ExpShow.modulename = "经验文本显示增强"
Automaton_ExpShow.moduledesc = "动作条经验槽经验文本显示：当前经验：1/5 升级进度：30% 双倍经验：98%"
Automaton_ExpShow.options = {
    fontsize = {
		type = "range", name = "字体大小(重置界面后生效)", desc = "设置显示文本字体大小，需要重载界面",
		get = function() return Automaton_ExpShow.db.profile.fontsize end,
		set = function(v) Automaton_ExpShow.db.profile.fontsize = v end,
		min = 10,
		max = 16,
		step = 1,
		bigStep =2,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_ExpShow:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("ExpShow")
    Automaton:RegisterDefaults("ExpShow", "profile", {
        disabled = false,
        fontsize = 12
    })
    Automaton:SetDisabledAsDefault(self, "ExpShow")

    self:RegisterOptions(self.options)

    MainMenuBarExpText:ClearAllPoints()
    MainMenuBarExpText:SetPoint("CENTER", MainMenuExpBar, 0, 1)
    MainMenuBarExpText:SetFont(STANDARD_TEXT_FONT, self.db.profile.fontsize, 'OUTLINE')
end

function Automaton_ExpShow:OnEnable()
    self:RegisterEvent("UPDATE_EXHAUSTION", "FormatExpText")
    self:RegisterEvent("PLAYER_LOGIN", "FormatExpText")
    self:Hook("TextStatusBar_UpdateTextString")
    TextStatusBar_UpdateTextString(MainMenuExpBar)
end

function Automaton_ExpShow:OnDisable()
    self:UnregisterAllEvents()
    self:UnhookAll()
    TextStatusBar_UpdateTextString(MainMenuExpBar)

end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_ExpShow:UI_ERROR_MESSAGE()
    self.lastError = arg1
end

function Automaton_ExpShow:FormatExpText()
    local p = "player"
    local mxp = UnitXPMax(p)
    local cxp = UnitXP(p)
    if not cxp then return "" end
    local ex = GetXPExhaustion()
    local perxp = (Round(cxp / mxp * 100))
    local perex = ex and (Round(ex / (mxp * 1.125) * 100)) or 0
    local exptext = ""
    local pxptext = ""
    local xptext = MyXPBarText and MyXPBarText or MainMenuBarExpText
    xptext:SetFont(STANDARD_TEXT_FONT, self.db.profile.fontsize, "OUTLINE")
    if perex > 0 then
        exptext = format("|CFFFFFF00   当前双倍：|R%s%s%%|R", HexColors(SetPercentColor(ex, mxp * 1.125)), perex) --" |cffff00ff当前双倍: |R" .. HexColors(SetPercentColor(ex, mxp * 1.125))..(Round(ex / (mxp * 1.125) * 100)) .. "%|r"
    end
    if cxp and cxp > 0 then
        pxptext = format("|CFFFFFF00   升级进度：|R%s%s%%|R", HexColors(SetPercentColor(cxp, mxp)), perxp) --" |cffff00ff升级进度: |R" .. HexColors(SetPercentColor(cxp, mxp))..(Round(cxp / mxp * 100)) .. "%|r"
    end
    xptext:SetText(format("|CFFFFFF00当前经验：|r%d/%d %s %s", cxp, mxp, pxptext, exptext))
end

function Automaton_ExpShow:TextStatusBar_UpdateTextString(textStatusBar)
    self.hooks.TextStatusBar_UpdateTextString(textStatusBar)
    self:FormatExpText()
end

