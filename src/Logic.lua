local addonName, EJLoot = ...

EJLootDB = EJLootDB or {}
EJLootDB.mounts = EJLootDB.mounts or {}
EJLoot.missingItems = EJLoot.missingItems or {}
EJLoot.bosses = EJLoot.bosses or {}

function EJLoot:trackItem(bossName, item)
    self.missingItems[bossName] = self.missingItems[bossName] or {}
    table.insert(self.missingItems[bossName], item)
end

function EJLoot:trackMount(instance, mount)
    EJLootDB.mounts[instance] = EJLootDB.mounts[instance] or {}
    mount.encounters = (EJLootDB.mounts[instance][mount.link] or {}).encounters or {}
    mount.encounters[mount.difficulty] = mount.encounter

    EJLootDB.mounts[instance][mount.link] = mount
end

function EJLoot.getFingerprint()
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

function EJLoot:ScanEncounter(encounterID, bossName)
    EJ_SelectEncounter(encounterID)
    table.insert(self.bosses, bossName)

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
                    self:trackItem(bossName, itemInfo)
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

                self:trackMount(EJ_GetInstanceInfo(), itemInfo)

                if not hasMount then
                    self:trackItem(bossName, itemInfo)
                end
            end
        end
    end
end

function EJLoot:Scan()
    self.missingItems = {}
    self.bosses = {}

    local instanceID = EncounterJournal.instanceID
    if not instanceID then
        return
    end

    -- scan current boss
    if EncounterJournal.encounterID then
        local bossName = EJ_GetEncounterInfo(EncounterJournal.encounterID)
        if bossName then
            self:ScanEncounter(EncounterJournal.encounterID, bossName)
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

        self:ScanEncounter(encounterID, bossName)
        i = i + 1
    end

    EJ_SelectInstance(instanceID)
end

-- CORE
function EJLoot:ShouldScan()
    if not EncounterJournal or not EncounterJournal.instanceID then
        return
    end

    local fingerprint = self.getFingerprint()
    if fingerprint ~= self.fingerprint then
        self.fingerprint = fingerprint
        self:Scan()
    end

    self:UpdateUI()
end

function EJLoot:PruneMog(sourceID)
    local itemInfo = C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
    if not itemInfo or not itemInfo.itemAppearanceID then
        return
    end

    local pruned = false
    for bossName, items in pairs(self.missingItems or {}) do
        for i = #items, 1, -1 do
            local item = items[i]

            if item.appearanceID == itemInfo.itemAppearanceID then
                table.remove(items, i)
                pruned = true
            end
        end

        if #items == 0 then
            self.missingItems[bossName] = nil
        end
    end

    if pruned then
        self:UpdateUI()
    end
end

function EJLoot:PruneMount(mountID)
    local pruned = false
    for bossName, items in pairs(self.missingItems or {}) do
        for i = #items, 1, -1 do
            local item = items[i]

            if item.mountID == mountID then
                table.remove(items, i)
                pruned = true
            end
        end

        if #items == 0 then
            self.missingItems[bossName] = nil
        end
    end

    for instance, mounts in pairs(EJLootDB.mounts or {}) do
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
