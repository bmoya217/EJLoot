local addonName, EJLoot = ...

local DISPLAY = {
    SHOW = "SHOW",
    HIDE = "HIDE"
}

local POSITION = {
    SCREEN = "SCREEN",
    ENCOUNTER_JOURNAL = "ENCOUNTER_JOURNAL"
}

function EJLoot:GetSettings()
    EJLootDB = EJLootDB or {}
    EJLootDB.settings = EJLootDB.settings or {}
    EJLootDB.collectibles = EJLootDB.collectibles or {}
    EJLootDB.minimap = EJLootDB.minimap or {}
    EJLootDB.settings.display = EJLootDB.settings.display or DISPLAY.SHOW
    EJLootDB.settings.positionMode = EJLootDB.settings.positionMode or POSITION.ENCOUNTER_JOURNAL
    EJLootDB.settings.noInstanceTypes = EJLootDB.settings.noInstanceTypes or {}

    for _, collectibleType in ipairs({"mount", "toy", "pet"}) do
        if EJLootDB.settings.noInstanceTypes[collectibleType] == nil then
            EJLootDB.settings.noInstanceTypes[collectibleType] = true
        end
    end

    EJLootDB.minimap.minimapPos = EJLootDB.minimap.minimapPos or 225

    if EJLootDB.minimap.hide == nil then
        EJLootDB.minimap.hide = false
    end

    return EJLootDB.settings
end

function EJLoot:IsNoInstanceTypeShown(collectibleType)
    return self:GetSettings().noInstanceTypes[collectibleType] ~= false
end

function EJLoot:SetNoInstanceTypeShown(collectibleType, shown)
    if collectibleType ~= "mount" and collectibleType ~= "toy" and collectibleType ~= "pet" then
        return
    end

    self:GetSettings().noInstanceTypes[collectibleType] = shown
    self:UpdateUI()
end

function EJLoot:GetMinimapSettings()
    self:GetSettings()
    return EJLootDB.minimap
end

function EJLoot:IsFrameAnchoredSetting()
    return self:GetSettings().positionMode == POSITION.ENCOUNTER_JOURNAL
end

function EJLoot:IsFrameShownSetting()
    return self:GetSettings().display == DISPLAY.SHOW
end

function EJLoot:IsMinimapButtonShownSetting()
    return not self:GetMinimapSettings().hide
end

function EJLoot:SetFrameDisplay(display)
    self:GetSettings().display = display

    if display == DISPLAY.HIDE then
        self:HideUI()
    else
        self:UpdateUI()
    end
end

function EJLoot:SetMinimapButtonShown(shown)
    self:GetMinimapSettings().hide = not shown

    if self.minimapIconLib then
        if shown then
            self.minimapIconLib:Show(addonName)
        else
            self.minimapIconLib:Hide(addonName)
            GameTooltip:Hide()
        end
    end
end

function EJLoot:ToggleFrameDisplay()
    if self:IsFrameShownSetting() then
        self:SetFrameDisplay(DISPLAY.HIDE)
    else
        self:SetFrameDisplay(DISPLAY.SHOW)
    end
end

function EJLoot:ToggleMinimapButton()
    self:SetMinimapButtonShown(not self:IsMinimapButtonShownSetting())
end

function EJLoot:TogglePositionMode()
    local settings = self:GetSettings()
    if self:IsFrameAnchoredSetting() then
        settings.positionMode = POSITION.SCREEN
    else
        settings.positionMode = POSITION.ENCOUNTER_JOURNAL
    end

    self:ApplyFramePosition()
    self:UpdateHeaderHint()
    self:UpdateUI()
end
