local addonName, EJLoot = ...

EJLootDB = EJLootDB or {}
EJLootDB.mounts = EJLootDB.mounts or {}
EJLootDB.collectibles = EJLootDB.collectibles or {}
EJLoot.missingItems = EJLoot.missingItems or {}
EJLoot.bosses = EJLoot.bosses or {}

local COLLECTED_ID_FIELDS = {
    NEW_MOUNT_ADDED = "mountID",
    NEW_TOY_ADDED = "itemID",
    NEW_PET_ADDED = "speciesID"
}

function EJLoot:TrackItem(bossName, item)
    self.missingItems[bossName] = self.missingItems[bossName] or {}
    table.insert(self.missingItems[bossName], item)
end

function EJLoot:TrackCollectible(instance, collectible)
    EJLootDB.collectibles[instance] = EJLootDB.collectibles[instance] or {}
    local key = collectible.type .. ":" .. tostring(collectible.itemID)
    local previous = EJLootDB.collectibles[instance][key] or {}
    collectible.encounters = previous.encounters or {}
    collectible.encounters[collectible.difficulty] = collectible.encounter

    EJLootDB.collectibles[instance][key] = collectible
end

function EJLoot:GetCollectibleInfo(itemInfo)
    if not itemInfo or not itemInfo.itemID then
        return
    end

    local mountID = C_MountJournal.GetMountFromItem(itemInfo.itemID)
    if mountID then
        local _, spellID = C_MountJournal.GetMountInfoByID(mountID)
        return "mount", mountID, C_MountJournal.GetMountLink(spellID)
    end

    if C_ToyBox and C_ToyBox.GetToyInfo and C_ToyBox.GetToyInfo(itemInfo.itemID) then
        return "toy", itemInfo.itemID, itemInfo.link
    end

    local speciesID = C_PetJournal and C_PetJournal.GetPetInfoByItemID and
                          C_PetJournal.GetPetInfoByItemID(itemInfo.itemID)
    if speciesID then
        return "pet", speciesID, itemInfo.link
    end
end

function EJLoot:IsCollectibleCollected(collectible)
    if collectible.type == "mount" then
        local _, _, _, _, _, _, _, _, _, _, collected = C_MountJournal.GetMountInfoByID(collectible.mountID)
        return collected
    elseif collectible.type == "toy" then
        return PlayerHasToy(collectible.itemID)
    elseif collectible.type == "pet" then
        local collected = C_PetJournal.GetNumCollectedInfo(collectible.speciesID)
        return collected and collected > 0
    end

    return false
end

function EJLoot:IsAppearanceCollected(appearanceID)
    local sources = C_TransmogCollection.GetAllAppearanceSources(appearanceID)

    for _, sourceID in pairs(sources or {}) do
        if C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceID) then
            return true
        end
    end

    return false
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
                if not self:IsAppearanceCollected(appearanceID) then
                    self:TrackItem(bossName, itemInfo)
                end
            end
        end

        local collectibleType, collectibleID, collectibleLink = self:GetCollectibleInfo(itemInfo)

        if collectibleType then
            itemInfo.link = collectibleLink or itemInfo.link
            itemInfo.type = collectibleType
            itemInfo.difficulty = EJ_GetDifficulty()
            itemInfo.encounter = bossName
            if collectibleType == "mount" then
                itemInfo.mountID = collectibleID
            elseif collectibleType == "pet" then
                itemInfo.speciesID = collectibleID
            end

            self:TrackCollectible(EJ_GetInstanceInfo(), itemInfo)

            if not self:IsCollectibleCollected(itemInfo) then
                self:TrackItem(bossName, itemInfo)
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

function EJLoot:PruneCollectedItem(event, collectedID)
    local field = COLLECTED_ID_FIELDS[event]

    if event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then
        local sourceInfo = C_TransmogCollection.GetAppearanceSourceInfo(collectedID)
        field = "appearanceID"
        collectedID = sourceInfo and sourceInfo.itemAppearanceID
    end

    if not field or not collectedID then
        return
    end

    local pruned = false

    for bossName, items in pairs(self.missingItems or {}) do
        for i = #items, 1, -1 do
            if items[i][field] == collectedID then
                table.remove(items, i)
                pruned = true
            end
        end

        if #items == 0 then
            self.missingItems[bossName] = nil
        end
    end

    if pruned or self:ShouldRenderCollectibles() then
        self:UpdateUI()
    end
end
