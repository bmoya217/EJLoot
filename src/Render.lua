local addonName, EJLoot = ...

local DIFFICULTIES = {"N", "H", "N10", "N25", "H10", "H25", "LFR", "M+", "N40", "", "HS", "NS", "", "N", "H", "M", "",
                      "", "", "", "", "", "M"}

function EJLoot:GetMountStatus(mount, instanceName)
    local status = {}

    for difficultyID, shorthand in ipairs(DIFFICULTIES) do
        local encounter = mount.encounters and mount.encounters[difficultyID]

        if encounter then
            local color = "|cff00FF00"

            for instanceIndex = 1, GetNumSavedInstances() do
                local instance, _, _, savedDifficultyID, locked = GetSavedInstanceInfo(instanceIndex)

                if instance == instanceName and savedDifficultyID == difficultyID and locked then
                    color = "|cffA8A8A8"
                    break
                end
            end

            table.insert(status, color .. shorthand .. "|r")
        end
    end

    return table.concat(status, " | ")
end

function EJLoot:ClearRows()
    self:CreateUI()
    self.rows = self.rows or {}

    for _, row in ipairs(self.rows) do
        row:Hide()
        row.link = nil
    end

    self.rowIndex = 1
end

function EJLoot:GetRow()
    self.rows = self.rows or {}

    local row = self.rows[self.rowIndex]

    if not row then
        row = CreateFrame("Button", nil, self.content)
        row:SetSize(self.ROW_WIDTH, 20)
        row:EnableMouse(true)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("LEFT")
        row.text:SetJustifyH("LEFT")

        row:SetScript("OnEnter", function(rowSelf)
            if rowSelf.link then
                GameTooltip:SetOwner(rowSelf, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:SetHyperlink(rowSelf.link)
                GameTooltip:Show()
            end
        end)

        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        row:SetScript("OnClick", function(rowSelf)
            if not rowSelf.link then
                return
            end

            if IsModifiedClick("DRESSUP") then
                if rowSelf.mountID then
                    DressUpMount(rowSelf.mountID)
                elseif rowSelf.link then
                    DressUpItemLink(rowSelf.link)
                end
            elseif IsModifiedClick("CHATLINK") and rowSelf.link then
                ChatEdit_InsertLink(rowSelf.link)
            end
        end)

        self.rows[self.rowIndex] = row
    end

    self.rowIndex = self.rowIndex + 1
    return row
end

function EJLoot:AddHeader(text, y)
    local row = self:GetRow()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 8, y)
    row:SetSize(self.ROW_WIDTH, 22)
    row.link = nil
    row.text:SetFontObject("GameFontNormal")
    row.text:SetText(text)
    row:Show()

    return y - 24
end

function EJLoot:AddSubHeader(text, y)
    local row = self:GetRow()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 8, y)
    row:SetSize(300, 32)
    row.link = nil
    row.text:SetFontObject("GameFontDisableSmall")
    row.text:SetText(text)
    row.text:SetWidth(self.ROW_WIDTH)
    row.text:SetJustifyH("LEFT")
    row:Show()

    return y - 34
end

function EJLoot:AddLink(item, status, y)
    local row = self:GetRow()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", self.LINK_LEFT_OFFSET, y)
    row:SetSize(self.LINK_ROW_WIDTH, 20)
    row.link = item.link
    row.mountID = item.mountID
    row.text:SetFontObject("GameFontHighlight")

    if status and status ~= "" then
        row.text:SetText(row.link .. " " .. status)
    else
        row.text:SetText(row.link)
    end

    row:Show()

    return y - 20
end

function EJLoot:RenderLoot()
    self:ClearRows()
    self.frame.title:SetText("EJ Loot")

    local y = -8
    local hasAny = false

    for _, bossName in ipairs(self.bosses or {}) do
        local items = self.missingItems and self.missingItems[bossName]

        if items and #items > 0 then
            local addedBoss = false

            for _, item in ipairs(items) do
                if item.link then
                    if not addedBoss then
                        y = self:AddHeader(bossName, y)
                        addedBoss = true
                    end

                    y = self:AddLink(item, nil, y)
                    hasAny = true
                end
            end

            if addedBoss then
                y = y - 8
            end
        end
    end

    if not hasAny then
        y = self:AddHeader("All appearances collected for this view.", y)
    end

    self.content:SetHeight(math.abs(y) + 20)
end

function EJLoot:RenderCollectibles()
    self:ClearRows()
    self.frame.title:SetText("EJ Collectibles")
    self:AddSubHeader("Select EJ instance to view items.", 12)

    local y = -8
    local hasAny = false

    for instance, collectibles in pairs(EJLootDB.collectibles or {}) do
        local addedInstance = false

        for _, collectible in pairs(collectibles) do
            if self:IsNoInstanceTypeShown(collectible.type) and not self:IsCollectibleCollected(collectible) then
                if not addedInstance then
                    y = self:AddHeader(instance, y)
                    addedInstance = true
                end

                local status = collectible.type == "mount" and self:GetMountStatus(collectible, instance) or nil
                y = self:AddLink(collectible, status, y)
                hasAny = true
            end
        end

        if addedInstance then
            y = y - 8
        end
    end

    if not hasAny then
        y = self:AddHeader("No missing collectibles to show!", y)
    end

    self.content:SetHeight(math.abs(y) + 20)
end
