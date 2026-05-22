local addonName, Things = ...

local DISPLAY = {
    SHOW = "SHOW",
    HIDE = "HIDE"
}

local POSITION = {
    SCREEN = "SCREEN",
    ENCOUNTER_JOURNAL = "ENCOUNTER_JOURNAL"
}

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

function Things:GetSettings()
    ThingsDB = ThingsDB or {}
    ThingsDB.settings = ThingsDB.settings or {}

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

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local settings = Things:GetSettings()

        if settings.positionMode == POSITION.SCREEN then
            local point, _, relativePoint, x, y = self:GetPoint()

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
    hint:SetText("drag to move")

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    text:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetText("Ready")

    frame.title = title
    frame.close = close
    frame.hint = hint
    frame.text = text

    self.frame = frame
    self:ApplyFramePosition()
end

function Things:ShowUI()
    if not self:ShouldActuallyShowFrame() then
        self:HideUI()
        return
    end

    self:CreateUI()
    self:ApplyFramePosition()
    self.frame:Show()
end

function Things:HideUI()
    if self.frame then
        self.frame:Hide()
    end
end

function Things:UpdateUI()
    if not self:ShouldActuallyShowFrame() then
        self:HideUI()
        return
    end

    self:ShowUI()
    self:UpdateHeaderHint()

    local text

    if self:IsEncounterJournalOpen() and not EncounterJournal.instanceID then
        text = self.getMounts and self.getMounts() or "Missing mounts unavailable."
    elseif self:IsEncounterJournalOpen() and self:IsInstanceSelectShown() then
        text = self.getMounts and self.getMounts() or "Missing mounts unavailable."
    elseif self:IsEncounterJournalOpen() then
        text = self.getThings and self.getThings() or "Missing things unavailable."
    else
        text = "Open the Adventure Guide to scan missing things."
    end

    self.frame.text:SetText(text)
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

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("CENTER", button, "CENTER", 0, 0)

    local iconMask = button:CreateMaskTexture()
    iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE",
        "CLAMPTOBLACKADDITIVE")
    iconMask:SetSize(20, 20)
    iconMask:SetPoint("CENTER", button, "CENTER", 0, 0)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map02")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:AddMaskTexture(iconMask)

    local function updatePosition()
        local angle = math.rad(ThingsDB.minimap.angle or 225)
        local radius = 92
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

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()

            px = px / scale
            py = py / scale

            ThingsDB.minimap.angle = math.deg(math.atan2(py - my, px - mx))
            updatePosition()
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        Things:UpdateMinimapTooltip()
    end)

    self.minimapButton = button
    updatePosition()
end

C_Timer.After(1, function()
    Things:CreateMinimapButton()
end)
