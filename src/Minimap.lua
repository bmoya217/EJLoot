local addonName, EJLoot = ...

local function addTooltipLines(tooltip)
    local settings = EJLoot:GetSettings()
    tooltip:SetText("EJ Loot")
    tooltip:AddLine("Left-click: show/hide frame", 1, 1, 1)
    tooltip:AddLine("Right-click: options", 1, 1, 1)
    tooltip:AddLine("Drag: move minimap button", 1, 1, 1)
    tooltip:AddLine(" ")
    tooltip:AddLine("Display: " .. settings.display, 0.8, 0.8, 0.8)
    tooltip:AddLine("Position: " .. settings.positionMode, 0.8, 0.8, 0.8)
end

function EJLoot:RefreshMinimapTooltip()
    local tooltip = self.minimapTooltip

    if not tooltip or not tooltip:IsShown() then
        return
    end

    tooltip:ClearLines()
    addTooltipLines(tooltip)
    tooltip:Show()
end

function EJLoot:ToggleMinimapMenu(anchor)
    local dropdown = self.minimapDropdown
    local dropdownMenu = L_EasyMenu
    local dropdownTemplate = "L_UIDropDownMenuTemplate"

    if not dropdownMenu then
        self:PrintMessage("Dropdown menu library is missing.")
        return
    end

    if not dropdown then
        dropdown = CreateFrame("Frame", "EJLootMinimapDropdown", UIParent, dropdownTemplate)
        self.minimapDropdown = dropdown
    end

    local frameDisplay = self:IsFrameShownSetting() and "Hide frame" or "Show frame"
    local positionDisplay = self:IsFrameAnchoredSetting() and "Move to screen" or "Anchor to Adventure Guide"
    local menu = {
        {
            text = "EJ Loot",
            isTitle = true,
            notCheckable = true
        },
        {
            text = frameDisplay,
            notCheckable = true,
            func = function()
                EJLoot:ToggleFrameDisplay()
            end
        },
        {
            text = positionDisplay,
            notCheckable = true,
            func = function()
                EJLoot:TogglePositionMode()
            end
        },
        {
            text = "",
            disabled = true,
            notCheckable = true
        },
        {
            text = "Hide minimap button",
            notCheckable = true,
            func = function()
                EJLoot:SetMinimapButtonShown(false)
            end
        }
    }

    GameTooltip:Hide()
    dropdownMenu(menu, dropdown, anchor or self.minimapButton or "cursor", 0, 0, "MENU")
end

function EJLoot:CreateMinimapButton()
    if self.minimapIconLib then
        return
    end

    local dataBroker = LibStub and LibStub("LibDataBroker-1.1", true)
    local minimapIconLib = LibStub and LibStub("LibDBIcon-1.0", true)

    if not dataBroker or not minimapIconLib then
        self:PrintMessage("Minimap libraries are missing.")
        return
    end

    local minimapSettings = self:GetMinimapSettings()
    local dataObject = dataBroker:NewDataObject(addonName, {
        type = "launcher",
        text = "EJ Loot",
        icon = "Interface\\Icons\\INV_Misc_Map02",
        OnClick = function(button, mouseButton)
            if mouseButton == "RightButton" then
                EJLoot:ToggleMinimapMenu(button)
            else
                EJLoot:ToggleFrameDisplay()
                EJLoot:RefreshMinimapTooltip()
            end
        end,
        OnTooltipShow = function(tooltip)
            EJLoot.minimapTooltip = tooltip
            addTooltipLines(tooltip)
        end
    })

    self.minimapDataObject = dataObject
    self.minimapIconLib = minimapIconLib

    minimapIconLib:Register(addonName, dataObject, minimapSettings)
    self.minimapButton = minimapIconLib:GetMinimapButton(addonName)
    self:SetMinimapButtonShown(not minimapSettings.hide)
end
