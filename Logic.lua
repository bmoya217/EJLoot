local addonName, Things = ...

ThingsDB = ThingsDB or {}
Things.saved = ThingsDB

Things.difficulties = {"N", "H", "N10", "N25", "H10", "H25", "LFR", "M+", "N40", "", "HS", "NS", "", "N", "H", "M", "",
                       "", "", "", "", "", "M"}

Things.saved.mounts = Things.saved.mounts or {}
Things.missingThings = Things.missingThings or {}
Things.bosses = Things.bosses or {}

function Things.trackThing(bossName, thing)
    Things.missingThings[bossName] = Things.missingThings[bossName] or {}
    table.insert(Things.missingThings[bossName], thing)
end

function Things.trackMount(instance, mount)
    Things.saved.mounts[instance] = Things.saved.mounts[instance] or {}

    mount.encounters = (Things.saved.mounts[instance][mount.link] or {}).encounters or {}
    mount.encounters[mount.difficulty] = mount.encounter

    Things.saved.mounts[instance][mount.link] = mount
end

function Things.getMountStatus(mount, instanceName)
    local status = {}

    for difficultyID, shorthand in pairs(Things.difficulties) do
        local encounter = mount.encounters[difficultyID]

        if encounter then
            local color = "|cff00FF00"

            for instanceIndex = 1, GetNumSavedInstances() do
                local instance, _, _, savedDifficultyID, locked = GetSavedInstanceInfo(instanceIndex)

                if instance == instanceName and savedDifficultyID == difficultyID and locked then
                    color = "|cffA8A8A8"
                end
            end

            table.insert(status, color .. shorthand .. "|r")
        end
    end

    return table.concat(status, " | ")
end

function Things.getMounts()
    local text = "Missing mounts:\n"

    for instance, mounts in pairs(Things.saved.mounts or {}) do
        local header = "\n" .. instance
        local body = ""

        for link, mount in pairs(mounts) do
            local status = Things.getMountStatus(mount, instance)

            if not mount.hasMount then
                body = body .. "\n  " .. link .. " " .. status
            end
        end

        if body ~= "" then
            text = text .. header .. body
        end
    end

    if text == "Missing mounts:\n" then
        return "Has all the mounts!"
    end

    return text
end

function Things.getThings()
    local text = "Missing things:\n"

    for _, bossName in pairs(Things.bosses) do
        if Things.missingThings[bossName] then
            text = text .. "\n" .. bossName

            for _, thing in pairs(Things.missingThings[bossName]) do
                text = text .. "\n  " .. thing.link
            end
        end
    end

    if text == "Missing things:\n" then
        return "Has all the things!"
    end

    return text
end

function Things.getFingerprint()
    local instance = EncounterJournal.instanceID
    local encounterSelected = not EncounterJournalInstanceSelect or not EncounterJournalInstanceSelect:IsShown()
    local encounter = encounterSelected and EncounterJournal.encounterID or "x"
    local difficulty = EJ_GetDifficulty()
    local class, spec = EJ_GetLootFilter()
    local slot = C_EncounterJournal.GetSlotFilter()
    local num = EJ_GetNumLoot()

    return "i" .. tostring(instance) .. "e" .. tostring(encounter) .. "d" .. tostring(difficulty) .. "c" ..
               tostring(class) .. "s" .. tostring(spec) .. "s" .. tostring(slot) .. "#" .. tostring(num)
end

function Things.updateEncounter(encounterID, bossName)
    EJ_SelectEncounter(encounterID)
    table.insert(Things.bosses, bossName)

    local numLoot = EJ_GetNumLoot()

    for i = 1, numLoot do
        local itemInfo = C_EncounterJournal.GetLootInfoByIndex(i)

        if itemInfo and itemInfo.link then
            local appearanceID = C_TransmogCollection.GetItemInfo(itemInfo.link)

            if appearanceID then
                local hasMog = false
                local sources = C_TransmogCollection.GetAllAppearanceSources(appearanceID)

                if sources then
                    for _, sourceID in pairs(sources) do
                        if C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceID) then
                            hasMog = true
                            break
                        end
                    end
                end

                if not hasMog then
                    Things.trackThing(bossName, itemInfo)
                end
            end
        end

        if itemInfo and itemInfo.armorType == "Mount" then
            local mountID = C_MountJournal.GetMountFromItem(itemInfo.itemID)

            if mountID then
                local _, spellID, _, _, _, _, _, _, _, _, hasMount = C_MountJournal.GetMountInfoByID(mountID)

                itemInfo.link = C_MountJournal.GetMountLink(spellID)
                itemInfo.hasMount = hasMount
                itemInfo.difficulty = EJ_GetDifficulty()
                itemInfo.encounter = bossName

                Things.trackMount(EJ_GetInstanceInfo(), itemInfo)

                if not hasMount then
                    Things.trackThing(bossName, itemInfo)
                end
            end
        end
    end
end

function Things.update()
    Things.missingThings = {}
    Things.bosses = {}

    if not EncounterJournal then
        return
    end

    local selectedEncounterID = EncounterJournal.encounterID
    local instanceID = EncounterJournal.instanceID

    if not instanceID then
        return
    end

    if selectedEncounterID then
        local bossName = EJ_GetEncounterInfo(selectedEncounterID)

        if bossName then
            Things.updateEncounter(selectedEncounterID, bossName)
        end

        return
    end

    local i = 1

    while true do
        local bossName, _, encounterID = EJ_GetEncounterInfoByIndex(i)

        if not encounterID then
            break
        end

        Things.updateEncounter(encounterID, bossName)
        i = i + 1
    end

    EJ_SelectInstance(instanceID)
end

function Things:ShouldUpdate()
    if not self:IsFrameShownSetting() then
        self:HideUI()
        return
    end

    if not self:IsEncounterJournalOpen() then
        self:UpdateUI()
        return
    end

    if not EncounterJournal.instanceID then
        self:UpdateUI()
        return
    end

    local fingerprint = Things.getFingerprint()

    if fingerprint ~= Things.fingerprint then
        Things.update()
        Things.stacks = (Things.stacks or 0) + 1
        Things.fingerprint = fingerprint
    else
        Things.stacks = 0
    end

    self:UpdateUI()
end
