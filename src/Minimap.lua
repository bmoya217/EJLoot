local addonName, EJLoot = ...

local function addTooltipLines(tooltip)
    local settings = EJLoot:GetSettings()
    tooltip:SetText("EJ Loot")
    tooltip:AddLine("Left-click: show/hide frame", 1, 1, 1)
    tooltip:AddLine("Right-click: toggle screen / Adventure Guide position", 1, 1, 1)
    tooltip:AddLine("Drag: move minimap button", 1, 1, 1)
    tooltip:AddLine(" ")
    tooltip:AddLine("Display: " .. settings.display, 0.8, 0.8, 0.8)
    tooltip:AddLine("Position: " .. settings.positionMode, 0.8, 0.8, 0.8)
end

function EJLoot:UpdateMinimapTooltip()
    if not self.minimapButton or not self.minimapButton:IsMouseOver() then
        return
    end

    GameTooltip:SetOwner(self.minimapButton, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    addTooltipLines(GameTooltip)
    GameTooltip:Show()
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
        OnClick = function(_, mouseButton)
            if mouseButton == "RightButton" then
                EJLoot:TogglePositionMode()
            else
                EJLoot:ToggleFrameDisplay()
            end

            EJLoot:UpdateMinimapTooltip()
        end,
        OnTooltipShow = function(tooltip)
            addTooltipLines(tooltip)
        end
    })

    self.minimapDataObject = dataObject
    self.minimapIconLib = minimapIconLib

    minimapIconLib:Register(addonName, dataObject, minimapSettings)
    self.minimapButton = minimapIconLib:GetMinimapButton(addonName)
    self:SetMinimapButtonShown(not minimapSettings.hide)
end
