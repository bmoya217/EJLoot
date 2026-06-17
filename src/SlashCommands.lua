local addonName, EJLoot = ...

local COMMANDS = {
    display = "Toggle the EJ Loot frame, or use show/hide",
    minimap = "Toggle the minimap button, or use show/hide",
    position = "Toggle screen / Adventure Guide position"
}

local ORDERED_COMMANDS = {"display", "position", "minimap"}

local function normalize(message)
    return string.lower((message or ""):match("^%s*(.-)%s*$"))
end

local function statusLabel(isEnabled)
    if isEnabled then
        return "shown"
    end

    return "hidden"
end

function EJLoot:PrintMessage(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99EJ Loot|r: " .. message)
end

function EJLoot:PrintSlashHelp()
    self:PrintMessage("Commands:")

    for _, command in ipairs(ORDERED_COMMANDS) do
        self:PrintMessage("/ejloot " .. command .. " - " .. COMMANDS[command])
    end
end

function EJLoot:HandleSlashCommand(message)
    local command, option = normalize(message):match("^(%S*)%s*(.-)$")

    if command == "" or command == "help" then
        self:PrintSlashHelp()
        return
    end

    if command == "display" or command == "frame" then
        if option == "show" then
            self:SetFrameDisplay("SHOW")
        elseif option == "hide" then
            self:SetFrameDisplay("HIDE")
        elseif option == "" then
            self:ToggleFrameDisplay()
        else
            self:PrintMessage("Unknown display option: " .. option)
            self:PrintSlashHelp()
            return
        end

        self:PrintMessage("Frame " .. statusLabel(self:IsFrameShownSetting()) .. ".")
        return
    end

    if command == "position" or command == "anchor" then
        self:TogglePositionMode()

        if self:IsFrameAnchoredSetting() then
            self:PrintMessage("Frame anchored to the Adventure Guide.")
        else
            self:PrintMessage("Frame moved to the screen.")
        end

        return
    end

    if command == "minimap" then
        if option == "show" then
            self:SetMinimapButtonShown(true)
        elseif option == "hide" then
            self:SetMinimapButtonShown(false)
        elseif option == "" then
            self:ToggleMinimapButton()
        else
            self:PrintMessage("Unknown minimap option: " .. option)
            self:PrintSlashHelp()
            return
        end

        self:PrintMessage("Minimap button " .. statusLabel(self:IsMinimapButtonShownSetting()) .. ".")
        return
    end

    self:PrintMessage("Unknown command: " .. command)
    self:PrintSlashHelp()
end

SLASH_EJLOOT1 = "/ejloot"
SLASH_EJLOOT2 = "/ejl"
SlashCmdList.EJLOOT = function(message)
    EJLoot:HandleSlashCommand(message)
end
