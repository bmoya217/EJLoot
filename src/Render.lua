local addonName, EJLoot = ...

local DIFFICULTIES = {"N", "H", "N10", "N25", "H10", "H25", "LFR", "M+", "N40", "", "HS", "NS", "", "N", "H", "M", "",
                      "", "", "", "", "", "M"}

local function getDifficultyName(difficultyID)
    if GetDifficultyInfo then
        local name = GetDifficultyInfo(difficultyID)
        if name and name ~= "" then
            return name
        end
    end

    return tostring(difficultyID)
end

local function getDifficultyLabelFromName(name)
    name = name or ""
    local lowerName = name:lower()

    local size, mode = name:match("^(%d+)%s+Player%s+(.+)$")
    if size and mode then
        return mode:sub(1, 1) .. size
    end

    size, mode = name:match("^(%d+)%s+player%s+(.+)$")
    if size and mode then
        return mode:sub(1, 1) .. size
    end

    if lowerName:find("raid finder", 1, true) or lowerName:find("looking for raid", 1, true) then
        return "LFR"
    elseif lowerName:find("keystone", 1, true) or lowerName:find("mythic+", 1, true) then
        return "M+"
    elseif lowerName:find("mythic", 1, true) then
        return "M"
    elseif lowerName:find("heroic", 1, true) then
        return "H"
    elseif lowerName:find("normal", 1, true) then
        return "N"
    end

    return name
end

local function getDifficultyLabel(difficultyID)
    local label = DIFFICULTIES[difficultyID]
    if label and label ~= "" then
        return label
    end

    return getDifficultyLabelFromName(getDifficultyName(difficultyID))
end

local function isDifficultyLocked(instanceName, difficultyID)
    local difficultyName = getDifficultyName(difficultyID)
    local difficultyLabel = getDifficultyLabelFromName(difficultyName)

    for instanceIndex = 1, GetNumSavedInstances() do
        local instance, _, _, savedDifficultyID, locked, _, _, _, _, savedDifficultyName = GetSavedInstanceInfo(instanceIndex)

        if instance == instanceName and locked and
            (savedDifficultyID == difficultyID or savedDifficultyName == difficultyName or
                getDifficultyLabelFromName(savedDifficultyName) == difficultyLabel) then
            return true
        end
    end

    return false
end

function EJLoot:GetInstanceStatus(instanceName, collectibles)
    local difficulties = {}
    local status = {}

    for _, collectible in ipairs(collectibles or {}) do
        for difficultyID in pairs(collectible.encounters or {}) do
            difficulties[difficultyID] = true
        end
    end

    for difficultyID in pairs(difficulties) do
        local normalizedDifficultyID = tonumber(difficultyID) or difficultyID
        local color = "|cff00FF00"

        if isDifficultyLocked(instanceName, normalizedDifficultyID) then
            color = "|cffA8A8A8"
        end

        table.insert(status, {
            difficultyID = normalizedDifficultyID,
            text = color .. getDifficultyLabel(normalizedDifficultyID) .. "|r"
        })
    end

    table.sort(status, function(a, b)
        return (tonumber(a.difficultyID) or 0) < (tonumber(b.difficultyID) or 0)
    end)

    for index, difficulty in ipairs(status) do
        status[index] = difficulty.text
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
                if rowSelf.collectibleType == "mount" and rowSelf.collectibleID then
                    DressUpMount(rowSelf.collectibleID)
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

function EJLoot:AddLink(item, y)
    local row = self:GetRow()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", self.LINK_LEFT_OFFSET, y)
    row:SetSize(self.LINK_ROW_WIDTH, 20)
    row.link = item.link
    row.collectibleType = item.type
    row.collectibleID = item.collectibleID
    row.text:SetFontObject("GameFontHighlight")

    row.text:SetText(row.link)

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
                if item.link and (not item.type or self:IsCollectibleShown(item)) then
                    if not addedBoss then
                        y = self:AddHeader(bossName, y)
                        addedBoss = true
                    end

                    y = self:AddLink(item, y)
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
    local instances = {}
    local groups = {}

    for _, collectible in ipairs(EJLootDB.collectibles or {}) do
        if self:IsCollectibleTypeShown(collectible.type) and self:IsCollectibleShown(collectible) then
            local instance = collectible.instance or "Unknown instance"

            if not groups[instance] then
                groups[instance] = {}
                table.insert(instances, instance)
            end

            table.insert(groups[instance], collectible)
        end
    end

    table.sort(instances)

    for _, instance in ipairs(instances) do
        local status = self:GetInstanceStatus(instance, groups[instance])
        local header = status ~= "" and (instance .. " " .. status) or instance
        y = self:AddHeader(header, y)

        for _, collectible in ipairs(groups[instance]) do
            y = self:AddLink(collectible, y)
            hasAny = true
        end

        if #groups[instance] > 0 then
            y = y - 8
        end
    end

    if not hasAny then
        y = self:AddHeader("No missing collectibles to show!", y)
    end

    self.content:SetHeight(math.abs(y) + 20)
end
