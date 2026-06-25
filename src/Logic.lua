local addonName, EJLoot = ...

EJLootDB = EJLootDB or {}
EJLootDB.collectibles = EJLootDB.collectibles or {}
EJLoot.missingItems = EJLoot.missingItems or {}
EJLoot.bosses = EJLoot.bosses or {}

function EJLoot:TrackItem(bossName, item)
    self.missingItems[bossName] = self.missingItems[bossName] or {}
    table.insert(self.missingItems[bossName], item)
end

function EJLoot:TrackCollectible(instance, collectible)
    local key = self:GetCollectibleKey(collectible)

    if not key then
        return
    end

    local index, previous = self:FindCollectibleIndex(collectible)
    previous = previous or {}

    collectible.encounters = previous.encounters or {}
    collectible.encounters[collectible.difficulty] = collectible.encounter
    collectible.hidden = previous.hidden or nil
    collectible.instance = instance

    if index then
        EJLootDB.collectibles[index] = collectible
    else
        table.insert(EJLootDB.collectibles, collectible)
    end
end

function EJLoot:RemoveCollectible(collectible)
    local index = self:FindCollectibleIndex(collectible)

    if not index then
        return false
    end

    table.remove(EJLootDB.collectibles, index)
    return true
end

function EJLoot:GetPetSpeciesIDByItemID(itemID)
    if not C_PetJournal or not C_PetJournal.GetPetInfoByItemID then
        return
    end

    local _, _, _, _, _, _, _, _, _, _, _, _, speciesID = C_PetJournal.GetPetInfoByItemID(itemID)
    return speciesID
end

function EJLoot:GetCollectibleInfo(itemInfo)
    if not itemInfo or not itemInfo.itemID then
        return
    end

    local collectibleID = C_MountJournal.GetMountFromItem(itemInfo.itemID)
    if collectibleID then
        local _, spellID = C_MountJournal.GetMountInfoByID(collectibleID)
        return "mount", collectibleID, C_MountJournal.GetMountLink(spellID)
    end

    if C_ToyBox and C_ToyBox.GetToyInfo and C_ToyBox.GetToyInfo(itemInfo.itemID) then
        return "toy", itemInfo.itemID, itemInfo.link
    end

    collectibleID = self:GetPetSpeciesIDByItemID(itemInfo.itemID)
    if collectibleID then
        return "pet", collectibleID, itemInfo.link
    end
end

function EJLoot:IsCollectibleCollected(collectible)
    if not collectible or not collectible.collectibleID then
        return false
    end

    if collectible.type == "mount" then
        local _, _, _, _, _, _, _, _, _, _, collected = C_MountJournal.GetMountInfoByID(collectible.collectibleID)
        return collected
    elseif collectible.type == "toy" then
        return PlayerHasToy(collectible.collectibleID)
    elseif collectible.type == "pet" then
        local collected = C_PetJournal.GetNumCollectedInfo(collectible.collectibleID)
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

function EJLoot:PruneCollectedCollectibles()
    local pruned = false

    for index = #(EJLootDB.collectibles or {}), 1, -1 do
        if self:IsCollectibleCollected(EJLootDB.collectibles[index]) then
            table.remove(EJLootDB.collectibles, index)
            pruned = true
        end
    end

    return pruned
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
                itemInfo.type = "appearance"
                itemInfo.collectibleID = appearanceID
                if not self:IsAppearanceCollected(appearanceID) then
                    self:TrackItem(bossName, itemInfo)
                end
            end
        end

        local collectibleType, collectibleID, collectibleLink = self:GetCollectibleInfo(itemInfo)

        if collectibleType then
            itemInfo.link = collectibleLink or itemInfo.link
            itemInfo.type = collectibleType
            itemInfo.collectibleID = collectibleID
            itemInfo.difficulty = EJ_GetDifficulty()
            itemInfo.encounter = bossName

            if self:IsCollectibleCollected(itemInfo) then
                self:RemoveCollectible(itemInfo)
            else
                self:TrackCollectible(EJ_GetInstanceInfo(), itemInfo)
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
    local collectedType

    if event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then
        local sourceInfo = C_TransmogCollection.GetAppearanceSourceInfo(collectedID)
        collectedType = "appearance"
        collectedID = sourceInfo and sourceInfo.itemAppearanceID
    elseif event == "NEW_MOUNT_ADDED" then
        collectedType = "mount"
    elseif event == "NEW_TOY_ADDED" then
        collectedType = "toy"
    elseif event == "NEW_PET_ADDED" then
        collectedType = "pet"
    end

    if not collectedType or not collectedID then
        return
    end

    local pruned = false

    for bossName, items in pairs(self.missingItems or {}) do
        for i = #items, 1, -1 do
            if items[i].type == collectedType and items[i].collectibleID == collectedID then
                table.remove(items, i)
                pruned = true
            end
        end

        if #items == 0 then
            self.missingItems[bossName] = nil
        end
    end

    for index = #(EJLootDB.collectibles or {}), 1, -1 do
        if EJLootDB.collectibles[index].type == collectedType and EJLootDB.collectibles[index].collectibleID == collectedID then
            table.remove(EJLootDB.collectibles, index)
            pruned = true
        end
    end

    if pruned or self:ShouldRenderCollectibles() then
        self:UpdateUI()
    end

    if pruned and self.RefreshOptionsPanel then
        self:RefreshOptionsPanel()
    end
end
