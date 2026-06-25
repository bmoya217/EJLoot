local addonName, EJLoot = ...

local DISPLAY = {
    SHOW = "SHOW",
    HIDE = "HIDE"
}

local POSITION = {
    SCREEN = "SCREEN",
    ENCOUNTER_JOURNAL = "ENCOUNTER_JOURNAL"
}

-- Bump this when saved data shape changes. Beta data is cheap to rebuild from the Encounter Journal.
local CURRENT_SCHEMA = "beta-3"

function EJLoot:GetSettings()
    EJLootDB = EJLootDB or {}

    if EJLootDB.schema ~= CURRENT_SCHEMA then
        EJLootDB = {}
    end

    EJLootDB.schema = CURRENT_SCHEMA
    EJLootDB.settings = EJLootDB.settings or {}
    EJLootDB.collectibles = EJLootDB.collectibles or {}
    EJLootDB.minimap = EJLootDB.minimap or {}
    EJLootDB.settings.display = EJLootDB.settings.display or DISPLAY.SHOW
    EJLootDB.settings.positionMode = EJLootDB.settings.positionMode or POSITION.ENCOUNTER_JOURNAL
    EJLootDB.settings.collectibles = EJLootDB.settings.collectibles or {}

    for _, collectibleType in ipairs({"mount", "toy", "pet"}) do
        EJLootDB.settings.collectibles[collectibleType] = EJLootDB.settings.collectibles[collectibleType] ~= false
    end

    EJLootDB.minimap.minimapPos = EJLootDB.minimap.minimapPos or 225

    if EJLootDB.minimap.hide == nil then
        EJLootDB.minimap.hide = false
    end

    return EJLootDB.settings
end

function EJLoot:GetCollectibleKey(collectible)
    if not collectible or not collectible.type or not collectible.itemID then
        return
    end

    return collectible.type .. ":" .. tostring(collectible.itemID)
end

function EJLoot:FindCollectibleIndex(collectible)
    local key = self:GetCollectibleKey(collectible)

    if not key then
        return
    end

    for index, savedCollectible in ipairs(EJLootDB.collectibles or {}) do
        if self:GetCollectibleKey(savedCollectible) == key then
            return index, savedCollectible
        end
    end
end

function EJLoot:IsCollectibleShown(collectible)
    return not collectible or collectible.hidden ~= true
end

function EJLoot:SetCollectibleHidden(collectible, hidden)
    if not collectible then
        return
    end

    collectible.hidden = hidden or nil
    self:UpdateUI()

    if self.RefreshOptionsPanel then
        self:RefreshOptionsPanel()
    end
end

function EJLoot:IsCollectibleTypeShown(collectibleType)
    return self:GetSettings().collectibles[collectibleType] ~= false
end

function EJLoot:SetCollectibleTypeShown(collectibleType, shown)
    if collectibleType ~= "mount" and collectibleType ~= "toy" and collectibleType ~= "pet" then
        return
    end

    self:GetSettings().collectibles[collectibleType] = shown
    self:UpdateUI()

    if self.RefreshOptionsPanel then
        self:RefreshOptionsPanel()
    end
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

    if self.RefreshOptionsPanel then
        self:RefreshOptionsPanel()
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

    if self.RefreshOptionsPanel then
        self:RefreshOptionsPanel()
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

    if self.RefreshOptionsPanel then
        self:RefreshOptionsPanel()
    end
end
