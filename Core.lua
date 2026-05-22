local addonName, Things = ...

Things.stacks = 0
Things.timer = 0
Things.fingerprint = ""

local EVENTS = {"UPDATE_INSTANCE_INFO", "EJ_DIFFICULTY_UPDATE", "EJ_LOOT_DATA_RECIEVED", "GLOBAL_MOUSE_UP",
                "TRANSMOG_COLLECTION_SOURCE_ADDED", "NEW_MOUNT_ADDED"}

function Things:IsEncounterJournalOpen()
    return EncounterJournal and EncounterJournal:IsShown()
end

function Things:IsInstanceSelectShown()
    return EncounterJournalInstanceSelect and EncounterJournalInstanceSelect:IsShown()
end

function Things:PlayFanfare()
    local sound = "Interface\\CustomSounds\\fanfare" .. math.random(6) .. ".ogg"
    PlaySoundFile(sound, "Master")
end

function Things:Debounce()
    self.fingerprint = ""

    if self.timer and self.timer ~= 0 then
        self.timer:Cancel()
    end

    self.timer = C_Timer.NewTimer(0.5, function()
        self.timer = 0
        self:ShouldUpdate()
    end)
end

function Things:HandleEvent(event, ...)
    if event == "TRANSMOG_COLLECTION_SOURCE_ADDED" or event == "NEW_MOUNT_ADDED" then
        self:PlayFanfare()
    end

    if not self:IsFrameShownSetting() then
        self:HideUI()
        return
    end

    if not self:IsEncounterJournalOpen() then
        self:UpdateUI()
        return
    end

    if self:IsInstanceSelectShown() or not EncounterJournal.instanceID then
        self.stacks = self.stacks + 1
        self:UpdateUI()
        return
    end

    self:Debounce()
end

local eventFrame = CreateFrame("Frame")

for _, event in ipairs(EVENTS) do
    eventFrame:RegisterEvent(event)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    Things:HandleEvent(event, ...)
end)
