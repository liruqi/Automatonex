assert(Automaton, "Automaton not found!")
----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_ZoneInfo = Automaton:NewModule("ZoneInfo")
Automaton_ZoneInfo.modulename = "地图显示适应等级"
Automaton_ZoneInfo.moduledesc = "打开大地图，地图上显示本地图适应的玩家等级"
Automaton_ZoneInfo.options = {}
local table_setn = table.setn
local Tourist = AceLibrary("Tourist-2.0")
local L = {
	["%d-man"] = "%d人"
}
local lastZone
local t = {}
------------------------------
--      Initialization      --
------------------------------

function Automaton_ZoneInfo:OnInitialize()
	self:RegisterOptions(self.options)
end

function Automaton_ZoneInfo:OnEnable()
	if not self.frame then
		self.frame = CreateFrame("Frame", "ZoneInfo", WorldMapFrameAreaFrame)
		WorldMapFrameAreaFrame:SetFrameLevel(3)
		self.frame:SetScript("OnUpdate", self.OnUpdate)
		self.frame.text = WorldMapFrameAreaFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		local text = self.frame.text
		local font = GameFontNormal:GetFont()
		text:SetFont(font, 16.5, "OUTLINE")
		text:SetPoint("TOP", WorldMapFrameAreaDescription, "BOTTOM", 0, -5)
		text:SetWidth(1024)
	end
	self.frame:Show()
end

function Automaton_ZoneInfo:OnDisable()
	self.frame:Hide()
	self.frame.text:Hide()
	WorldMapFrameAreaLabel:SetTextColor(1, 1, 0)
end

function Automaton_ZoneInfo:OnUpdate()
	self = Automaton_ZoneInfo
	if not WorldMapDetailFrame:IsShown() or not WorldMapFrameAreaLabel:IsShown() then
		self.frame.text:SetText("")
		lastZone = nil
		return
	end
	local underAttack = false
	local zone = WorldMapFrameAreaLabel:GetText()
	if zone then
		zone = string.gsub(WorldMapFrameAreaLabel:GetText(), " |cff.+$", "")
		if WorldMapFrameAreaDescription:GetText() then
			underAttack = true
			zone = string.gsub(WorldMapFrameAreaDescription:GetText(), " |cff.+$", "")
		end
	end
	if GetCurrentMapContinent() == 0 then
		local c1, c2 = GetMapContinents()
		if zone == c1 or zone == c2 then
			WorldMapFrameAreaLabel:SetTextColor(1, 1, 1)
			self.frame.text:SetText("")
			return
		end
	end
	if not zone or not Tourist:IsZoneOrInstance(zone) then
		zone = WorldMapFrame.areaName
	end
	WorldMapFrameAreaLabel:SetTextColor(1, 1, 1)
	if zone and (Tourist:IsZoneOrInstance(zone) or Tourist:DoesZoneHaveInstances(zone)) then
		if not underAttack then
			WorldMapFrameAreaLabel:SetTextColor(Tourist:GetFactionColor(zone))
			WorldMapFrameAreaDescription:SetTextColor(1, 1, 1)
		else
			WorldMapFrameAreaLabel:SetTextColor(1, 1, 1)
			WorldMapFrameAreaDescription:SetTextColor(Tourist:GetFactionColor(zone))
		end
		local low, high = Tourist:GetLevel(zone)

		if low > 0 and high > 0 then
			local r, g, b = Tourist:GetLevelColor(zone)
			local levelText
			if low == high then
				levelText = string.format(" |cff%02x%02x%02x[%d]|r", r * 255, g * 255, b * 255, high)
			else
				levelText = string.format(" |cff%02x%02x%02x[%d-%d]|r", r * 255, g * 255, b * 255, low, high)
			end
			local groupSize = Tourist:GetInstanceGroupSize(zone)
			local sizeText = ""
			if groupSize > 0 then
				sizeText = " " .. string.format(L["%d-man"], groupSize)
			end
			local zone = WorldMapFrameAreaLabel:GetText()
			if zone then
				if not underAttack then
					--Print(WorldMapFrameAreaLabel:GetText())
					WorldMapFrameAreaLabel:SetText(string.gsub(zone or "", " |cff.+$", "") ..
					levelText .. sizeText)
				else
					WorldMapFrameAreaDescription:SetText(string.gsub(zone, " |cff.+$",
						"") .. levelText .. sizeText)
				end
			end
		end

		if Tourist:DoesZoneHaveInstances(zone) then
			if lastZone ~= zone then
				lastZone = zone
				for instance in Tourist:IterateZoneInstances(zone) do
					local low, high = Tourist:GetLevel(instance)
					local r1, g1, b1 = Tourist:GetFactionColor(instance)
					local r2, g2, b2 = Tourist:GetLevelColor(instance)
					local groupSize = Tourist:GetInstanceGroupSize(instance)
					if low == high then
						if groupSize > 0 then
							table.insert(t,
								string.format("|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d]|r " .. L["%d-man"], r1 * 255,
									g1 * 255, b1 * 255, instance, r2 * 255, g2 * 255, b2 * 255, high, groupSize))
						else
							table.insert(t,
								string.format("|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d]|r", r1 * 255, g1 * 255, b1 * 255,
									instance, r2 * 255, g2 * 255, b2 * 255, high))
						end
					else
						if groupSize > 0 then
							table.insert(t,
								string.format("|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d-%d]|r " .. L["%d-man"], r1 * 255,
									g1 * 255, b1 * 255, instance, r2 * 255, g2 * 255, b2 * 255, low, high, groupSize))
						else
							table.insert(t,
								string.format("|cff%02x%02x%02x%s|r |cff%02x%02x%02x[%d-%d]|r", r1 * 255, g1 * 255,
									b1 * 255, instance, r2 * 255, g2 * 255, b2 * 255, low, high))
						end
					end
				end
				self.frame.text:SetText(table.concat(t, "\n"))
				for k in pairs(t) do
					t[k] = nil
				end
				table_setn(t, 0)
			end
		else
			lastZone = nil
			self.frame.text:SetText("")
		end
	elseif not zone then
		lastZone = nil
		self.frame.text:SetText("")
	end

	local mapFileName = GetMapInfo()
	if mapFileName == "Undercity" or mapFileName == "Ironforge" then
		self.frame.text:SetText("")
	end
end
