local addonName, EJLoot = ...

local TYPE_LABELS = {
    mount = "Mounts",
    toy = "Toys",
    pet = "Pets"
}

local TYPE_OPTIONS = {
    {key = "mount", label = "Mounts"},
    {key = "pet", label = "Pets"},
    {key = "toy", label = "Toys"}
}

local function setCheckboxText(checkbox, text)
    if checkbox.Text then
        checkbox.Text:SetText(text)
        checkbox.Text:SetWidth(checkbox.textWidth or 520)
        checkbox.Text:SetJustifyH("LEFT")
    elseif checkbox.text then
        checkbox.text:SetText(text)
        checkbox.text:SetWidth(checkbox.textWidth or 520)
        checkbox.text:SetJustifyH("LEFT")
    end
end

local function createCheckbox(parent, text, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetScript("OnClick", function(self)
        onClick(self:GetChecked())
    end)
    setCheckboxText(checkbox, text)
    return checkbox
end

local function getLinkText(link)
    return link and link:match("%[(.-)%]") or nil
end

local function getSelectedCollectibleType(panel)
    panel.collectibleType = panel.collectibleType or "mount"
    return panel.collectibleType
end

local function getCollectibleRows(collectibleType)
    local rows = {}

    for _, collectible in ipairs(EJLootDB.collectibles or {}) do
        if collectible.type == collectibleType then
            local name = getLinkText(collectible.link) or
                             (TYPE_LABELS[collectibleType] .. " " ..
                                 tostring(collectible.collectibleID or collectible.itemID))
            table.insert(rows, {
                name = name,
                instance = collectible.instance,
                collectible = collectible
            })
        end
    end

    table.sort(rows, function(a, b)
        if a.name == b.name then
            return (a.instance or "") < (b.instance or "")
        end

        return a.name < b.name
    end)

    return rows
end

local function getTypeLabel(collectibleType)
    return TYPE_LABELS[collectibleType] or "Collectibles"
end

local function setDropdownText(dropdown, text)
    if UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(dropdown, text)
    elseif dropdown.Text then
        dropdown.Text:SetText(text)
    end
end

local function setPointBelow(frame, anchor, y)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, y)
end

function EJLoot:RefreshOptionsPanel()
    local panel = self.optionsPanel

    if not panel then
        return
    end

    if panel.showFrame then
        panel.showFrame:SetChecked(self:IsFrameShownSetting())
    end

    if panel.anchorFrame then
        panel.anchorFrame:SetChecked(self:IsFrameAnchoredSetting())
    end

    if panel.showMinimap then
        panel.showMinimap:SetChecked(self:IsMinimapButtonShownSetting())
    end

    for key, checkbox in pairs(panel.collectibleTypeChecks or {}) do
        checkbox:SetChecked(self:IsCollectibleTypeShown(key))
    end

    local selectedType = getSelectedCollectibleType(panel)

    if panel.collectibleTypeDropdown then
        setDropdownText(panel.collectibleTypeDropdown, getTypeLabel(selectedType))
    end

    if panel.trackAll then
        panel.trackAll:SetText("Track all")
    end

    for _, row in ipairs(panel.collectibleRows or {}) do
        row:Hide()
        row.collectible = nil
    end

    panel.collectibleRows = panel.collectibleRows or {}

    local rows = getCollectibleRows(selectedType)
    local y = -4

    if panel.noCollectibles then
        panel.noCollectibles:SetShown(#rows == 0)
        panel.noCollectibles:SetText("No " .. getTypeLabel(selectedType):lower() ..
                                        " discovered yet. Browse instance loot in the Adventure Guide first.")
    end

    for index, item in ipairs(rows) do
        local row = panel.collectibleRows[index]

        if not row then
            row = createCheckbox(panel.collectibleContent, "", function(checked)
                if row.collectible then
                    EJLoot:SetCollectibleHidden(row.collectible, not checked)
                end
            end)
            row.textWidth = 500
            panel.collectibleRows[index] = row
        end

        setPointBelow(row, panel.collectibleContent, y)
        row.collectible = item.collectible
        row:SetChecked(self:IsCollectibleShown(item.collectible))

        local label = item.collectible.link or item.name

        setCheckboxText(row, label)
        row:Show()
        y = y - 24
    end

    panel.collectibleContent:SetHeight(math.max(1, math.abs(y) + 8))
end

function EJLoot:CreateOptionsPanel()
    if self.optionsPanel then
        return
    end

    local panel = CreateFrame("Frame")
    panel.name = "EJ Loot"
    panel.collectibleRows = {}
    panel.collectibleType = "mount"
    panel.collectibleTypeChecks = {}

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("EJ Loot")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure display behavior and hide individual tracked collectibles.")

    panel.showFrame = createCheckbox(panel, "Show EJ Loot frame", function(checked)
        EJLoot:SetFrameDisplay(checked and "SHOW" or "HIDE")
    end)
    panel.showFrame:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)

    panel.anchorFrame = createCheckbox(panel, "Anchor frame to the Adventure Guide", function(checked)
        if checked ~= EJLoot:IsFrameAnchoredSetting() then
            EJLoot:TogglePositionMode()
        end
    end)
    panel.anchorFrame:SetPoint("TOPLEFT", panel.showFrame, "BOTTOMLEFT", 0, -6)

    panel.showMinimap = createCheckbox(panel, "Show minimap button", function(checked)
        EJLoot:SetMinimapButtonShown(checked)
    end)
    panel.showMinimap:SetPoint("TOPLEFT", panel.anchorFrame, "BOTTOMLEFT", 0, -6)

    local noInstanceHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    noInstanceHeader:SetPoint("TOPLEFT", panel.showMinimap, "BOTTOMLEFT", 0, -18)
    noInstanceHeader:SetText("No instance view")

    local previous = noInstanceHeader
    for _, key in ipairs({"mount", "toy", "pet"}) do
        local checkbox = createCheckbox(panel, TYPE_LABELS[key], function(checked)
            EJLoot:SetCollectibleTypeShown(key, checked)
        end)
        checkbox:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6)
        panel.collectibleTypeChecks[key] = checkbox
        previous = checkbox
    end

    local collectibleHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    collectibleHeader:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -20)
    collectibleHeader:SetText("Tracked collectibles")

    local collectibleHelp = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    collectibleHelp:SetPoint("TOPLEFT", collectibleHeader, "BOTTOMLEFT", 0, -6)
    collectibleHelp:SetWidth(560)
    collectibleHelp:SetJustifyH("LEFT")
    collectibleHelp:SetText("Choose a collectible type, then uncheck anything you want EJ Loot to hide. Collected items are removed from this list automatically.")

    local dropdown = CreateFrame("Frame", "EJLootCollectibleTypeDropdown", panel, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", collectibleHelp, "BOTTOMLEFT", -16, -8)
    if UIDropDownMenu_SetWidth then
        UIDropDownMenu_SetWidth(dropdown, 140)
    end
    if UIDropDownMenu_Initialize then
        UIDropDownMenu_Initialize(dropdown, function(_, level)
            for _, option in ipairs(TYPE_OPTIONS) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = option.label
                info.checked = getSelectedCollectibleType(panel) == option.key
                info.func = function()
                    panel.collectibleType = option.key
                    setDropdownText(dropdown, option.label)
                    EJLoot:RefreshOptionsPanel()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
    end
    setDropdownText(dropdown, TYPE_LABELS[panel.collectibleType])

    local trackAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    trackAll:SetSize(100, 22)
    trackAll:SetPoint("LEFT", dropdown, "RIGHT", 8, 2)
    trackAll:SetText("Track all")
    trackAll:SetScript("OnClick", function()
        local selectedType = getSelectedCollectibleType(panel)

        for _, collectible in ipairs(EJLootDB.collectibles or {}) do
            if collectible.type == selectedType then
                collectible.hidden = nil
            end
        end

        EJLoot:UpdateUI()
        EJLoot:RefreshOptionsPanel()
    end)

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 16, -10)
    scroll:SetSize(560, 220)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(520, 1)
    scroll:SetScrollChild(content)

    local noCollectibles = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    noCollectibles:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -4)

    panel.collectibleTypeDropdown = dropdown
    panel.trackAll = trackAll
    panel.collectibleScroll = scroll
    panel.collectibleContent = content
    panel.noCollectibles = noCollectibles

    panel:SetScript("OnShow", function()
        EJLoot:RefreshOptionsPanel()
    end)

    self.optionsPanel = panel

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "EJ Loot")
        Settings.RegisterAddOnCategory(category)
        self.optionsCategory = category
        self.optionsCategoryID = category.ID or (category.GetID and category:GetID())
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    self:RefreshOptionsPanel()
end

function EJLoot:OpenOptions()
    self:CreateOptionsPanel()

    if Settings and Settings.OpenToCategory and self.optionsCategoryID then
        Settings.OpenToCategory(self.optionsCategoryID)
    elseif InterfaceOptionsFrame_OpenToCategory and self.optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    end
end
