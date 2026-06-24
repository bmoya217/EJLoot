local addonName, EJLoot = ...

-- logic helpers 
function EJLoot:IsEncounterJournalOpen()
    return EncounterJournal and EncounterJournal:IsShown()
end

function EJLoot:ShouldShowUI()
    if not self:IsFrameShownSetting() then
        return false
    end

    return not self:IsFrameAnchoredSetting() or EncounterJournal ~= nil
end

function EJLoot:ShouldRenderCollectibles()
    return not EncounterJournal or not EncounterJournal.instanceID or
               (EncounterJournalInstanceSelect and EncounterJournalInstanceSelect:IsShown())
end

-- utility helpers
function EJLoot:ApplyFramePosition()
    if not self.frame then
        return
    end

    if self:IsFrameAnchoredSetting() and not EncounterJournal then
        return
    end

    self.frame:ClearAllPoints()

    if self:IsFrameAnchoredSetting() then
        local offset = EncounterJournal.instanceID and 40 or 8
        self.frame:SetParent(EncounterJournal)
        self.frame:SetPoint("TOPLEFT", EncounterJournal, "TOPRIGHT", offset, 0)
        return
    end

    self.frame:SetParent(UIParent)

    EJLootDB.position = EJLootDB.position or {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0
    }

    self.frame:SetPoint(EJLootDB.position.point, UIParent, EJLootDB.position.relativePoint, EJLootDB.position.x,
        EJLootDB.position.y)
end

function EJLoot:UpdateHeaderHint()
    if not self.frame or not self.frame.hint then
        return
    end

    if self:IsFrameAnchoredSetting() then
        self.frame.hint:SetText("")
    else
        self.frame.hint:SetText("drag to move")
    end
end

-- base ui logic
function EJLoot:CreateUI()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame", "EJLootFrame", UIParent, "BackdropTemplate")
    frame:SetSize(self.FRAME_WIDTH, self.FRAME_HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })

    frame:SetScript("OnDragStart", function(frameSelf)
        if not self:IsFrameAnchoredSetting() then
            frameSelf:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(frameSelf)
        frameSelf:StopMovingOrSizing()

        if not self:IsFrameAnchoredSetting() then
            local point, _, relativePoint, x, y = frameSelf:GetPoint()

            EJLootDB.position = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y
            }
        end
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("EJ Loot")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        EJLoot:ToggleFrameDisplay()
    end)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPRIGHT", close, "TOPLEFT", -4, -5)
    hint:SetText("")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 12)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(self.CONTENT_WIDTH, 1)

    scrollFrame:SetScrollChild(content)

    frame.title = title
    frame.close = close
    frame.hint = hint
    frame.scrollFrame = scrollFrame

    self.frame = frame
    self.content = content

    self:ApplyFramePosition()
    self:UpdateHeaderHint()
end

function EJLoot:ShowUI()
    self:CreateUI()
    self.frame:Show()
end

function EJLoot:HideUI()
    if self.frame then
        self.frame:Hide()
    end
end

function EJLoot:UpdateUI()
    if self:ShouldShowUI() then
        self:ShowUI()
    else
        self:HideUI()
    end

    if self:IsFrameAnchoredSetting() then
        self:ApplyFramePosition()
    end

    self:UpdateHeaderHint()
    if self:ShouldRenderCollectibles() then
        self:RenderCollectibles()
    else
        self:RenderLoot()
    end
end
