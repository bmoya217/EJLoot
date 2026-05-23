local addonName, Things = ...

-- constants
local DIFFICULTIES = {"N", "H", "N10", "N25", "H10", "H25", "LFR", "M+", "N40", "", "HS", "NS", "", "N", "H", "M", "",
                      "", "", "", "", "", "M"}

-- utility helpers
function Things:GetMountStatus(mount, instanceName)
    local status = {}

    for difficultyID, shorthand in pairs(DIFFICULTIES) do
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

-- logic helpers 
function Things:IsEncounterJournalOpen()
    return EncounterJournal and EncounterJournal:IsShown()
end

function Things:ShouldRenderMounts()
    return not EncounterJournal.instanceID or
               (EncounterJournalInstanceSelect and EncounterJournalInstanceSelect:IsShown())
end

function Things:ShouldShowFrame()
    if not self:IsFrameShownSetting() then
        return false
    end

    if self:IsFrameAnchoredSetting() then
        return self:IsEncounterJournalOpen()
    end

    return true
end

-- functional helpers
function Things:ApplyFramePosition()
    if not self.frame then
        return
    end

    local settings = self:GetSettings()

    self.frame:ClearAllPoints()

    if self:IsFrameAnchoredSetting() and EncounterJournal then
        local offset = EncounterJournal.instanceID and 40 or 8
        self.frame:SetParent(EncounterJournal)
        self.frame:SetPoint("TOPLEFT", EncounterJournal, "TOPRIGHT", offset, 0)
        return
    end

    self.frame:SetParent(UIParent)

    ThingsDB.position = ThingsDB.position or {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0
    }

    self.frame:SetPoint(ThingsDB.position.point, UIParent, ThingsDB.position.relativePoint, ThingsDB.position.x,
        ThingsDB.position.y)
end

function Things:UpdateHeaderHint()
    if not self.frame or not self.frame.hint then
        return
    end

    if self:IsFrameAnchoredSetting() then
        self.frame.hint:SetText("")
    else
        self.frame.hint:SetText("drag to move")
    end
end

function Things:ShowUI()
    if not self:ShouldShowFrame() then
        self:HideUI()
        return
    end

    self:CreateUI()
    self.frame:Show()
end

function Things:HideUI()
    if self.frame then
        self.frame:Hide()
    end
end

function Things:ClearRows()
    self.rows = self.rows or {}

    for _, row in ipairs(self.rows) do
        row:Hide()
        row.link = nil
    end

    self.rowIndex = 1
end

function Things:GetRow()
    self.rows = self.rows or {}

    local row = self.rows[self.rowIndex]

    if not row then
        row = CreateFrame("Button", nil, self.content)
        row:SetSize(360, 20)
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
            if rowSelf.link and IsModifiedClick("CHATLINK") then
                ChatEdit_InsertLink(rowSelf.link)
            end
        end)

        self.rows[self.rowIndex] = row
    end

    self.rowIndex = self.rowIndex + 1
    return row
end

function Things:AddHeader(text, y)
    local row = self:GetRow()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 8, y)
    row:SetSize(360, 22)
    row.link = nil
    row.text:SetFontObject("GameFontNormal")
    row.text:SetText(text)
    row:Show()

    return y - 24
end

function Things:AddLink(link, status, y)
    local row = self:GetRow()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 20, y)
    row:SetSize(360, 20)
    row.link = link
    row.text:SetFontObject("GameFontHighlight")

    if status and status ~= "" then
        row.text:SetText(link .. " " .. status)
    else
        row.text:SetText(link)
    end

    row:Show()

    return y - 20
end

-- render
function Things:RenderMounts()
    self:ClearRows()

    local y = -8
    local hasAny = false

    y = self:AddHeader("Missing mounts", y)

    for instance, mounts in pairs(ThingsDB.mounts or {}) do
        local addedInstance = false

        for link, mount in pairs(mounts) do
            if not mount.hasMount then
                if not addedInstance then
                    y = self:AddHeader(instance, y)
                    addedInstance = true
                end

                y = self:AddLink(link, self:GetMountStatus(mount, instance), y)
                hasAny = true
            end
        end

        if addedInstance then
            y = y - 8
        end
    end

    if not hasAny then
        y = self:AddHeader("Has all the mounts!", y)
    end

    self.content:SetHeight(math.abs(y) + 20)
end

function Things:RenderThings()
    self:ClearRows()

    local y = -8
    local hasAny = false

    y = self:AddHeader("Missing things", y)

    for _, bossName in ipairs(self.bosses or {}) do
        local things = self.missingThings and self.missingThings[bossName]

        if things and #things > 0 then
            local addedBoss = false

            for _, thing in ipairs(things) do
                if thing.link then
                    if not addedBoss then
                        y = self:AddHeader(bossName, y)
                        addedBoss = true
                    end

                    y = self:AddLink(thing.link, nil, y)
                    hasAny = true
                end
            end

            if addedBoss then
                y = y - 8
            end
        end
    end

    if not hasAny then
        y = self:AddHeader("Has all the things!", y)
    end

    self.content:SetHeight(math.abs(y) + 20)
end

function Things:RenderMessage(title, message)
    self:ClearRows()

    local y = -8
    y = self:AddHeader(title, y)
    y = self:AddHeader(message, y)

    self.content:SetHeight(math.abs(y) + 20)
end

-- base ui logic
function Things:CreateUI()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame", "ThingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(420, 500)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })

    frame:SetScript("OnDragStart", function(frameSelf)
        if not self:IsFrameAnchoredSetting() then
            frameSelf:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(frameSelf)
        frameSelf:StopMovingOrSizing()

        if not self:IsFrameAnchoredSetting() then
            local point, _, relativePoint, x, y = frameSelf:GetPoint()

            ThingsDB.position = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y
            }
        end
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("Things")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        Things:ToggleFrameDisplay()
    end)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPRIGHT", close, "TOPLEFT", -4, -5)
    hint:SetText("")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 12)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(360, 1)

    scrollFrame:SetScrollChild(content)

    frame.title = title
    frame.close = close
    frame.hint = hint
    frame.scrollFrame = scrollFrame

    self.frame = frame
    self.content = content

    self:ApplyFramePosition()
    self:UpdateHeaderHint()
end

function Things:UpdateUI()
    if not self:ShouldShowFrame() then
        self:HideUI()
        return
    end

    self:ShowUI()
    self:UpdateHeaderHint()
    if self:IsFrameAnchoredSetting() then
        self:ApplyFramePosition()
    end

    -- Screen mode + EJ closed:
    if not self:IsEncounterJournalOpen() then
        if not self.hasRenderedOnce then
            self:RenderMessage("Things", "Open the Adventure Guide to scan missing things.")
            self.hasRenderedOnce = true
        end

        return
    end

    -- EJ open: now decide based on current EJ state.
    if self:ShouldRenderMounts() then
        self:RenderMounts()
    else
        self:RenderThings()
    end

    self.hasRenderedOnce = true
end
