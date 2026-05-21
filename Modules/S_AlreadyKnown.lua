local COLOR = { r = 0.1, g = 1.0, b = 0.1 }

local tooltip = CreateFrame('GameTooltip')
tooltip:SetOwner(WorldFrame, 'ANCHOR_NONE')

local Automaton_AlreadyKnown = Automaton:NewModule("AlreadyKnown")
Automaton_AlreadyKnown.modulename = "已学物品标记"
Automaton_AlreadyKnown.moduledesc = "在拍卖行和商人界面标记已学物品和任务物品"
Automaton_AlreadyKnown.options = {}

local IsAlreadyKnown, IsQuest
do
    local lines = {}
    for i = 1, 40 do
        lines[i] = tooltip:CreateFontString()
        tooltip:AddFontStrings(lines[i], tooltip:CreateFontString())
    end

    function IsAlreadyKnown(itemLink)
        if (not itemLink) then return end

        tooltip:ClearLines()
        local item = gsub(itemLink, ".*(item:%d+:%d+:%d+:%d+).*", "%1", 1)
        tooltip:SetHyperlink(item)
        for i = 1, tooltip:NumLines() do
            if (lines[i]:GetText() == ITEM_SPELL_KNOWN) then
                return true
            end
        end
    end

    function IsQuest(itemLink)
        if (not itemLink) then return end

        tooltip:ClearLines()
        local item = gsub(itemLink, ".*(item:%d+:%d+:%d+:%d+).*", "%1", 1)
        tooltip:SetHyperlink(item)
        for i = 1, tooltip:NumLines() do
            if (lines[i]:GetText() == ITEM_BIND_QUEST) then
                return true
            end
        end
    end
end

function Automaton_AlreadyKnown:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("AlreadyKnown")
    Automaton:RegisterDefaults("AlreadyKnown", "profile", {
        disabled = false,
    })
    Automaton:SetDisabledAsDefault(self, "AlreadyKnown")
    self:RegisterOptions(self.options)
end

function Automaton_AlreadyKnown:OnEnable()
    -- 拍卖行钩子
    hooksecurefunc("AuctionFrame_LoadUI", function()
        if AuctionFrameBrowse_Update then
            hooksecurefunc("AuctionFrameBrowse_Update", function()
                local numItems = GetNumAuctionItems('list')
                local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)

                for i = 1, NUM_BROWSE_TO_DISPLAY do
                    local index = offset + i
                    if (index > numItems) then return end

                    local texture = _G['BrowseButton' .. i .. 'ItemIconTexture']
                    if (texture and texture:IsShown()) then
                        local _, _, _, _, canUse = GetAuctionItemInfo('list', index)
                        if (canUse and IsAlreadyKnown(GetAuctionItemLink('list', index))) then
                            texture:SetVertexColor(COLOR.r, COLOR.g, COLOR.b)
                        end
                    end
                end
            end)
        end
    end)

    -- 商人钩子
    hooksecurefunc("MerchantFrame_Update", function()
        local numItems = GetMerchantNumItems()

        for i = 1, MERCHANT_ITEMS_PER_PAGE do
            local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
            if (index > numItems) then return end

            local merchantButton = _G['MerchantItem' .. i]
            local itemButton = _G['MerchantItem' .. i .. 'ItemButton']
            if (itemButton and itemButton:IsShown()) then
                local _, _, _, _, numAvailable, isUsable = GetMerchantItemInfo(index)
                if (isUsable and IsAlreadyKnown(GetMerchantItemLink(index))) then
                    local r, g, b = COLOR.r, COLOR.g, COLOR.b
                    if (numAvailable == 0) then
                        r, g, b = r * 0.5, g * 0.5, b * 0.5
                    end
                    SetItemButtonNameFrameVertexColor(merchantButton, r, g, b)
                    SetItemButtonSlotVertexColor(merchantButton, r, g, b)
                    SetItemButtonTextureVertexColor(itemButton, r, g, b)
                    SetItemButtonNormalTextureVertexColor(itemButton, r, g, b)
                end
                if (isUsable and IsQuest(GetMerchantItemLink(index))) then
                    SetItemButtonNameFrameVertexColor(merchantButton, 1, 1, 0)
                    SetItemButtonSlotVertexColor(merchantButton, 1, 1, 0)
                    SetItemButtonTextureVertexColor(itemButton, 1, 1, 0)
                    SetItemButtonNormalTextureVertexColor(itemButton, 1, 1, 0)
                end			
            end
        end
    end)
end

function Automaton_AlreadyKnown:OnDisable()
    -- 可以在这里添加禁用时的清理逻辑
end