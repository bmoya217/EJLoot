local addonName, Things = ...

Things.timer = 0
Things.fingerprint = ""

local EVENTS = {"UPDATE_INSTANCE_INFO", "EJ_DIFFICULTY_UPDATE", "GLOBAL_MOUSE_UP", -- affects fingerprint (maybe)
"TRANSMOG_COLLECTION_SOURCE_ADDED", "NEW_MOUNT_ADDED", -- needs rescan
"EJ_LOOT_DATA_RECIEVED" -- needs debounce
}

-- todo: check sounds
function Things:PlayFanfare()
    local sound = "Interface\\AddOns\\Things\\Media\\fanfare" .. math.random(2) .. ".ogg"
    PlaySoundFile(sound, "Master")
end

function Things:Debounce()
    if self.timer and self.timer ~= 0 then
        self.timer:Cancel()
    end

    self.timer = C_Timer.NewTimer(0.5, function()
        self.timer = 0
        self:ShouldUpdate()
    end)
end

function Things:HandleEvent(event, ...)
    if event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then
        local sourceID = ...
        self:PruneMog(sourceID)
    elseif event == "NEW_MOUNT_ADDED" then
        local mountID = ...
        self:PruneMount(mountID)
    else
        self:Debounce()
    end
end

local eventFrame = CreateFrame("Frame")

for _, event in ipairs(EVENTS) do
    eventFrame:RegisterEvent(event)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    Things:HandleEvent(event, ...)
end)
