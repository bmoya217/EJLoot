local addonName, Things = ...

local DISPLAY = {
    SHOW = "SHOW",
    HIDE = "HIDE"
}

local POSITION = {
    SCREEN = "SCREEN",
    ENCOUNTER_JOURNAL = "ENCOUNTER_JOURNAL"
}

local DIFFICULTIES = {"N", "H", "N10", "N25", "H10", "H25", "LFR", "M+", "N40", "", "HS", "NS", "", "N", "H", "M", "",
                      "", "", "", "", "", "M"}

function Things:GetSettings()
    ThingsDB = ThingsDB or {}
    ThingsDB.settings = ThingsDB.settings or {}
    ThingsDB.mounts = ThingsDB.mounts or {}

    ThingsDB.settings.display = ThingsDB.settings.display or DISPLAY.SHOW
    ThingsDB.settings.positionMode = ThingsDB.settings.positionMode or POSITION.ENCOUNTER_JOURNAL

    return ThingsDB.settings
end

function Things:IsFrameShownSetting()
    return self:GetSettings().display == DISPLAY.SHOW
end

function Things:ShouldActuallyShowFrame()
    local settings = self:GetSettings()

    if settings.display ~= DISPLAY.SHOW then
        return false
    end

    if settings.positionMode == POSITION.ENCOUNTER_JOURNAL then
        return self:IsEncounterJournalOpen()
    end

    return true
end

function Things:SetFrameDisplay(display)
    self:GetSettings().display = display

    if display == DISPLAY.HIDE then
        self:HideUI()
    else
        self:UpdateUI()
    end
end

function Things:ToggleFrameDisplay()
    if self:IsFrameShownSetting() then
        self:SetFrameDisplay(DISPLAY.HIDE)
    else
        self:SetFrameDisplay(DISPLAY.SHOW)
    end
end

function Things:TogglePositionMode()
    local settings = self:GetSettings()

    if settings.positionMode == POSITION.ENCOUNTER_JOURNAL then
        settings.positionMode = POSITION.SCREEN
    else
        settings.positionMode = POSITION.ENCOUNTER_JOURNAL
    end

    self:ApplyFramePosition()
    self:UpdateHeaderHint()
    self:UpdateUI()

    print("Things: position set to " .. settings.positionMode)
end

function Things:ApplyFramePosition()
    if not self.frame then
        return
    end

    local settings = self:GetSettings()

    self.frame:ClearAllPoints()

    if settings.positionMode == POSITION.ENCOUNTER_JOURNAL and EncounterJournal then
        local offset = EncounterJournal.instanceID and 40 or 8

        self.frame:SetParent(EncounterJournal)
        self.frame:SetPoint("TOPLEFT", EncounterJournal, "TOPRIGHT", offset, -8)
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

    local settings = self:GetSettings()

    if settings.positionMode == POSITION.SCREEN then
        self.frame.hint:SetText("drag to move")
    else
        self.frame.hint:SetText("")
    end
end

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
        if Things:GetSettings().positionMode == POSITION.SCREEN then
            frameSelf:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(frameSelf)
        frameSelf:StopMovingOrSizing()

        if Things:GetSettings().positionMode == POSITION.SCREEN then
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
        Things:SetFrameDisplay(DISPLAY.HIDE)
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

function Things:ShowUI()
    if not self:ShouldActuallyShowFrame() then
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

function Things:UpdateUI()
    if not self:ShouldActuallyShowFrame() then
        self:HideUI()
        return
    end

    self:ShowUI()
    self:UpdateHeaderHint()
    self:ApplyFramePosition()

    -- Screen mode + EJ closed:
    if not self:IsEncounterJournalOpen() then
        if not self.hasRenderedOnce then
            self:RenderMessage("Things", "Open the Adventure Guide to scan missing things.")
            self.hasRenderedOnce = true
        end

        return
    end

    -- EJ open: now decide based on current EJ state.
    if not EncounterJournal.instanceID or self:IsInstanceSelectShown() then
        self:RenderMounts()
    else
        self:RenderThings()
    end

    self.hasRenderedOnce = true
end

function Things:UpdateMinimapTooltip()
    if not self.minimapButton or not self.minimapButton:IsMouseOver() then
        return
    end

    local settings = self:GetSettings()

    GameTooltip:SetOwner(self.minimapButton, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:SetText("Things")
    GameTooltip:AddLine("Left-click: show/hide frame", 1, 1, 1)
    GameTooltip:AddLine("Right-click: toggle screen / Adventure Guide position", 1, 1, 1)
    GameTooltip:AddLine("Drag: move minimap button", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Display: " .. settings.display, 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Position: " .. settings.positionMode, 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

function Things:CreateMinimapButton()
    if self.minimapButton then
        return
    end

    ThingsDB = ThingsDB or {}
    ThingsDB.minimap = ThingsDB.minimap or {
        angle = 225
    }

    local button = CreateFrame("Button", "ThingsMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("CENTER")

    local iconMask = button:CreateMaskTexture()
    iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE",
        "CLAMPTOBLACKADDITIVE")
    iconMask:SetSize(20, 20)
    iconMask:SetPoint("CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map02")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:AddMaskTexture(iconMask)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    local function updatePosition()
        local angle = math.rad(ThingsDB.minimap.angle or 225)
        local radius = 100
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius

        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    button:SetScript("OnEnter", function()
        Things:UpdateMinimapTooltip()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            Things:TogglePositionMode()
        else
            Things:ToggleFrameDisplay()
        end

        Things:UpdateMinimapTooltip()
    end)

    button:SetScript("OnDragStart", function(buttonSelf)
        buttonSelf:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()

            px = px / scale
            py = py / scale

            ThingsDB.minimap.angle = math.deg(math.atan2(py - my, px - mx))
            updatePosition()
        end)
    end)

    button:SetScript("OnDragStop", function(buttonSelf)
        buttonSelf:SetScript("OnUpdate", nil)
        Things:UpdateMinimapTooltip()
    end)

    self.minimapButton = button
    updatePosition()
end

C_Timer.After(1, function()
    Things:CreateMinimapButton()
end)
