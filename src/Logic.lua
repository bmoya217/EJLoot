local addonName, Things = ...

ThingsDB = ThingsDB or {}
ThingsDB.mounts = ThingsDB.mounts or {}
Things.missingThings = Things.missingThings or {}
Things.bosses = Things.bosses or {}

function Things.trackThing(bossName, thing)
    Things.missingThings[bossName] = Things.missingThings[bossName] or {}
    table.insert(Things.missingThings[bossName], thing)
end

function Things.trackMount(instance, mount)
    ThingsDB.mounts[instance] = ThingsDB.mounts[instance] or {}
    mount.encounters = (ThingsDB.mounts[instance][mount.link] or {}).encounters or {}
    mount.encounters[mount.difficulty] = mount.encounter

    ThingsDB.mounts[instance][mount.link] = mount
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
               tostring(class) .. "sp" .. tostring(spec) .. "sl" .. tostring(slot) .. "#" .. tostring(num)
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
                itemInfo.appearanceID = appearanceID
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
                itemInfo.mountID = mountID

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

    local selectedEncounterID = EncounterJournal.encounterID
    local instanceID = EncounterJournal.instanceID
    if not instanceID then
        return
    end

    -- scan current boss
    if selectedEncounterID then
        local bossName = EJ_GetEncounterInfo(selectedEncounterID)
        if bossName then
            Things.updateEncounter(selectedEncounterID, bossName)
        end

        return
    end

    -- scan all bosses
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

-- CORE
function Things:ShouldUpdate()
    if not EncounterJournal or not EncounterJournal.instanceID then
        return
    end

    local fingerprint = Things.getFingerprint()
    if fingerprint ~= Things.fingerprint then
        Things.fingerprint = fingerprint
        Things.update()
    end

    self:UpdateUI()
end

function Things:PruneMog(sourceID)
    local itemInfo = C_TransmogCollection.GetAppearanceSourceInfo(sourceID)

    if not itemInfo.itemAppearanceID then
        return
    end

    local pruned = false
    for bossName, things in pairs(self.missingThings or {}) do
        for i = #things, 1, -1 do
            local thing = things[i]

            if thing.appearanceID == itemInfo.itemAppearanceID then
                table.remove(things, i)
                pruned = true
            end
        end

        if #things == 0 then
            self.missingThings[bossName] = nil
        end
    end

    if pruned then
        self:UpdateUI()
    end
end

function Things:PruneMount(mountID)
    local pruned = false
    for bossName, things in pairs(self.missingThings or {}) do
        for i = #things, 1, -1 do
            local thing = things[i]

            if thing.mountID == mountID then
                table.remove(things, i)
                pruned = true
            end
        end

        if #things == 0 then
            self.missingThings[bossName] = nil
        end
    end

    for instance, mounts in pairs(ThingsDB.mounts or {}) do
        for link, mount in pairs(mounts) do
            if mount.mountID == mountID then
                mount.hasMount = true
                pruned = true
            end
        end
    end

    if pruned then
        self:UpdateUI()
    end
end
