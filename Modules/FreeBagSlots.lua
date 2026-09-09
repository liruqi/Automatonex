assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_FreeBagSlots = Automaton:NewModule("FreeBagSlots")
Automaton_FreeBagSlots.modulename = "背包剩余栏位显示"
Automaton_FreeBagSlots.moduledesc = "在背包栏位处显示背包剩余空位"
Automaton_FreeBagSlots.options = {}

-- 引入 OneStorage-2.0 库
local onestorage

------------------------------
--      Initialization      --
------------------------------
function Automaton_FreeBagSlots:OnInitialize()
    self:RegisterOptions(self.options)
    
    -- 尝试获取 OneStorage 库
    onestorage = AceLibrary and AceLibrary:HasInstance("OneStorage-2.0") and AceLibrary("OneStorage-2.0")
end

function Automaton_FreeBagSlots:OnEnable()
    -- 如果 OneStorage 可用，注册事件
    if onestorage then
        self:RegisterEvent('BAG_UPDATE')
        self:RegisterEvent('PLAYER_LOGIN')
        self:RegisterEvent('BANKFRAME_OPENED')
        self:RegisterEvent('BANKFRAME_CLOSED')
        self:UpdateDisplay()
    else
        self:Print("OneStorage-2.0 库未找到，无法启用背包空位显示")
    end
end

function Automaton_FreeBagSlots:OnDisable()
    self:UnregisterAllEvents()
end

-- 使用 OneStorage 库的方法获取背包信息
function Automaton_FreeBagSlots:GetBagInfo()
    if not onestorage then return 0, 0 end
    
    local usedSlots, usedAmmoSlots, usedSoulSlots, usedProfSlots, ammoQuantity, totalSlots = 0, 0, 0, 0, 0, 0
    local Bags = {0, 1, 2, 3, 4}
    
    for _, bag in ipairs(Bags) do
        local tmp, qty = 0, 0
        for slot = 1, GetContainerNumSlots(bag) do
            local texture, itemCount = GetContainerItemInfo(bag, slot)
            if texture then
                tmp = tmp + 1
                qty = qty + itemCount
            end
        end
            
        local isAmmo, isSoul, isProf = onestorage:GetBagTypes(bag)
            
        if isAmmo then
            usedAmmoSlots = usedAmmoSlots + tmp
            ammoQuantity = ammoQuantity + qty
        elseif isSoul then
            usedSoulSlots = usedSoulSlots + tmp
        elseif isProf then
            usedProfSlots = usedProfSlots + tmp
        else
            usedSlots = usedSlots + tmp
            totalSlots = totalSlots + GetContainerNumSlots(bag)
        end
    end
    
    local freeSlots = totalSlots - usedSlots
    return freeSlots, totalSlots
end

-- 更新显示的函数
function Automaton_FreeBagSlots:UpdateDisplay()
    local freeSlots, totalSlots = self:GetBagInfo()
    
    local bagIconBtn = MainMenuBarBackpackButton or MyBagButton
    if MyBagButton and MyBagButton:IsVisible() then
        bagIconBtn = MyBagButton
    end
    if not bagIconBtn then return end
    
    if not bagIconBtn.text then
        bagIconBtn.text = bagIconBtn:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
        bagIconBtn.text:SetTextColor(1, 1, 1)
        bagIconBtn.text:SetFont(STANDARD_TEXT_FONT, 24, 'OUTLINE')
        bagIconBtn.text:SetPoint('CENTER', bagIconBtn, 'CENTER', 0, 0)
        bagIconBtn.text:SetDrawLayer('OVERLAY', 2)
    end
    
    local slotText
    if freeSlots == 0 then
        slotText = "|CFFFF0000已满|r"  -- 红色显示"已满"
    else
        slotText = string.format('|CFF00FF00%s|r', freeSlots)  -- 绿色显示数字
    end
    
    bagIconBtn.text:SetText(slotText)
end

-- 事件处理
function Automaton_FreeBagSlots:BAG_UPDATE()
    self:UpdateDisplay()
end

function Automaton_FreeBagSlots:PLAYER_LOGIN()
    self:UpdateDisplay()
end

function Automaton_FreeBagSlots:BANKFRAME_OPENED()
    self:UpdateDisplay()
end

function Automaton_FreeBagSlots:BANKFRAME_CLOSED()
    self:UpdateDisplay()
end
---------------------------------------------------


---------------------------------------------------
