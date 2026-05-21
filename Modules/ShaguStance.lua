assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

Automaton_ShaguStance = Automaton:NewModule("ShaguStance")
Automaton_ShaguStance.modulename = "自动姿态切换"
Automaton_ShaguStance.moduledesc = "根据技能需要自动切换战士和德鲁伊的姿态"
Automaton_ShaguStance.options = {
  
}
------------------------------
--      Initialization      --
------------------------------

function Automaton_ShaguStance:OnInitialize()
  self.db = Automaton:AcquireDBNamespace("ShaguStance")
  Automaton:RegisterDefaults("ShaguStance", "profile", {
    disabled = true,
  })
  Automaton:SetDisabledAsDefault(self, "ShaguStance")
  self:RegisterOptions(self.options)
  self.scanString = string.gsub(SPELL_FAILED_ONLY_SHAPESHIFT, "%%s", "(.+)")
end

function Automaton_ShaguStance:OnEnable()
  self:RegisterEvent("UI_ERROR_MESSAGE")
  self.DoCast = CastSpellByName
  self:Hook("CastSpell")
  self:Hook("CastSpellByName")
  self:Hook("UseAction")
  self.lastError = ""
end

function Automaton_ShaguStance:OnDisable()
  self:UnregisterAllEvents()
  self:UnhookAll()
  self.lastError = ""
  --CastSpellByName = self.Cast
end

------------------------------
--      Event Handlers      --
------------------------------

local function strsplit(delimiter, subject)
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields) + 1] = c end)
  return unpack(fields)
end
local formatstr = {
  ["豹形态"] = "猎豹形态"
}
function Automaton_ShaguStance:UI_ERROR_MESSAGE()
  self.lastError = arg1
  --Print(self.lastError)
end

function Automaton_ShaguStance:SwitchStance()
  for stances in string.gfind(self.lastError, self.scanString) do

    for _, stance in pairs({ strsplit(",", stances) }) do
      self.DoCast(string.gsub(formatstr[stance] or stance, "^%s*(.-)%s*$", "%1"))
    end
  end
  self.lastError = ""
end

function Automaton_ShaguStance:CastSpell(spellId, spellbookTabNum)
  self:SwitchStance()
  return self.hooks.CastSpell(spellId, spellbookTabNum)
end

function Automaton_ShaguStance:CastSpellByName(spellName, onSelf)
  self:SwitchStance()
  return self.hooks.CastSpellByName(spellName, onSelf)
end

function Automaton_ShaguStance:UseAction(slot, checkCursor, onSelf)
  self:SwitchStance()
  return self.hooks.UseAction(slot, checkCursor, onSelf)
end
