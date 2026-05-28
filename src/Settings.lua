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
    EJLootDB.mounts = EJLootDB.mounts or {}

    EJLootDB.settings.display = EJLootDB.settings.display or DISPLAY.SHOW
    EJLootDB.settings.positionMode = EJLootDB.settings.positionMode or POSITION.ENCOUNTER_JOURNAL

    return EJLootDB.settings
end

function EJLoot:IsFrameAnchoredSetting()
    return self:GetSettings().positionMode == POSITION.ENCOUNTER_JOURNAL
end

function EJLoot:IsFrameShownSetting()
    return self:GetSettings().display == DISPLAY.SHOW
end

function EJLoot:SetFrameDisplay(display)
    self:GetSettings().display = display

    if display == DISPLAY.HIDE then
        self:HideUI()
    else
        self:UpdateUI()
    end
end

function EJLoot:ToggleFrameDisplay()
    if self:IsFrameShownSetting() then
        self:SetFrameDisplay(DISPLAY.HIDE)
    else
        self:SetFrameDisplay(DISPLAY.SHOW)
    end
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
