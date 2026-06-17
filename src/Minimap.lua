local addonName, EJLoot = ...

function EJLoot:UpdateMinimapTooltip()
    if not self.minimapButton or not self.minimapButton:IsMouseOver() then
        return
    end

    local settings = self:GetSettings()
    GameTooltip:SetOwner(self.minimapButton, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:SetText("EJ Loot")
    GameTooltip:AddLine("Left-click: show/hide frame", 1, 1, 1)
    GameTooltip:AddLine("Right-click: toggle screen / Adventure Guide position", 1, 1, 1)
    GameTooltip:AddLine("Drag: move minimap button", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Display: " .. settings.display, 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Position: " .. settings.positionMode, 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

function EJLoot:CreateMinimapButton()
    if self.minimapButton then
        return
    end

    local minimapSettings = self:GetMinimapSettings()

    local button = CreateFrame("Button", "EJLootMinimapButton", Minimap)
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
        local angle = math.rad(minimapSettings.angle or 225)
        local radius = 100
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius

        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    button:SetScript("OnEnter", function()
        EJLoot:UpdateMinimapTooltip()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            EJLoot:TogglePositionMode()
        else
            EJLoot:ToggleFrameDisplay()
        end

        EJLoot:UpdateMinimapTooltip()
    end)

    button:SetScript("OnDragStart", function(buttonSelf)
        buttonSelf:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()

            px = px / scale
            py = py / scale

            minimapSettings.angle = math.deg(math.atan2(py - my, px - mx))
            updatePosition()
        end)
    end)

    button:SetScript("OnDragStop", function(buttonSelf)
        buttonSelf:SetScript("OnUpdate", nil)
        EJLoot:UpdateMinimapTooltip()
    end)

    self.minimapButton = button
    updatePosition()
    self:SetMinimapButtonShown(not minimapSettings.hide)
end
