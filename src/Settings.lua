local addonName, Things = ...

local DISPLAY = {
    SHOW = "SHOW",
    HIDE = "HIDE"
}

local POSITION = {
    SCREEN = "SCREEN",
    ENCOUNTER_JOURNAL = "ENCOUNTER_JOURNAL"
}

function Things:GetSettings()
    ThingsDB = ThingsDB or {}
    ThingsDB.settings = ThingsDB.settings or {}
    ThingsDB.mounts = ThingsDB.mounts or {}

    ThingsDB.settings.display = ThingsDB.settings.display or DISPLAY.SHOW
    ThingsDB.settings.positionMode = ThingsDB.settings.positionMode or POSITION.ENCOUNTER_JOURNAL

    return ThingsDB.settings
end

function Things:IsFrameAnchoredSetting()
    return self:GetSettings().positionMode == POSITION.ENCOUNTER_JOURNAL
end

function Things:IsFrameShownSetting()
    return self:GetSettings().display == DISPLAY.SHOW
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
    if self:IsFrameAnchoredSetting() then
        settings.positionMode = POSITION.SCREEN
    else
        settings.positionMode = POSITION.ENCOUNTER_JOURNAL
    end

    self:ApplyFramePosition()
    self:UpdateHeaderHint()
    self:UpdateUI()
end
