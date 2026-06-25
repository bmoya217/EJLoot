local addonName, EJLoot = ...

EJLoot.timer = 0
EJLoot.fingerprint = ""

local EVENTS = {"ADDON_LOADED", -- init
"UPDATE_INSTANCE_INFO", "EJ_DIFFICULTY_UPDATE", "GLOBAL_MOUSE_UP", -- affects fingerprint (maybe)
"TRANSMOG_COLLECTION_SOURCE_ADDED", "NEW_MOUNT_ADDED", -- collection updates
"NEW_TOY_ADDED", "NEW_PET_ADDED"}

function EJLoot:Debounce()
    if self.timer and self.timer ~= 0 then
        self.timer:Cancel()
    end

    self.timer = C_Timer.NewTimer(0.5, function()
        self.timer = 0
        self:ShouldScan()
    end)
end

function EJLoot:HandleEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == addonName then
            self:GetSettings()
            self:PruneCollectedCollectibles()
            self:CreateOptionsPanel()
            self:CreateMinimapButton()
            if not self:IsFrameAnchoredSetting() then
                self:UpdateUI()
            end
        elseif addon == "Blizzard_EncounterJournal" then
            self:UpdateUI()
        end
    elseif event == "TRANSMOG_COLLECTION_SOURCE_ADDED" or event == "NEW_MOUNT_ADDED" or event == "NEW_TOY_ADDED" or
        event == "NEW_PET_ADDED" then
        self:PruneCollectedItem(event, ...)
    else
        self:Debounce()
    end
end

local eventFrame = CreateFrame("Frame")
for _, event in ipairs(EVENTS) do
    eventFrame:RegisterEvent(event)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    EJLoot:HandleEvent(event, ...)
end)
