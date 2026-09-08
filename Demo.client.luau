-- Put Serotonin.luau in ReplicatedStorage as a ModuleScript named Serotonin.
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts.
local Serotonin = require(game:GetService("ReplicatedStorage"):WaitForChild("Serotonin"))

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("SerotoninDemo")
if previous then previous:Destroy() end

local window = Serotonin.new({Name = "SerotoninDemo", Title = "serotonin - roblox", PreviewTitle = "ESP Preview", Features = {Preview = true, Notifications = true}})
local white = Color3.fromRGB(245, 245, 248)
local cyan = Color3.fromRGB(125, 238, 245)
local teal = Color3.fromRGB(92, 195, 162)
local red = Color3.fromRGB(255, 0, 18)

local aim = window:AddTab("Aimbot")
local visuals = window:AddTab("Visuals")
local lighting = window:AddTab("Lighting")
local movement = window:AddTab("Movement")
local settings = window:AddTab("Settings")
local configs = window:AddTab("Configs")

-- The reference's labels are reproduced as UI examples. Callbacks only update
-- the isolated preview or library state; no gameplay systems are installed.
local function updatePreview()
    local f = window.Flags
    window:UpdatePreview({
        Box = f.Box, BoxFilled = f.BoxFilled, Health = f.Health, Name = f.Name, HeadDot = f.HeadDot,
        BoxColor = f.BoxColor and f.BoxColor.Color,
        FillColor = f.BoxFilledColor and f.BoxFilledColor.Color,
        FillTransparency = f.BoxFilledColor and (0.7 + f.BoxFilledColor.Transparency * 0.26),
        NameColor = f.NameColor and f.NameColor.Color,
        HeadColor = f.HeadDotColor and f.HeadDotColor.Color,
        NameText = f.NameType == "Display name" and player.DisplayName or "Name",
        FlagsText = (f.Flags and "FLAGS" or "") .. (f.TeamFlag and "\nTEAM FLAG" or ""),
        DetailsText = (f.Distance and "DISTANCE" or "") .. (f.Weapon and "\nWEAPON" or ""),
    })
end

local left = visuals:AddSection({Title = "Visuals", Side = "Left"})
local right = visuals:AddSection({Title = "Visuals Continued", Side = "Right"})
local function visualToggle(section, text, flag, default, color, transparency)
    return section:AddToggle({
        Text = text, Flag = flag, Default = default, Color = color, Transparency = transparency,
        Callback = updatePreview, ColorCallback = updatePreview,
    })
end

visualToggle(left, "Show Hidden", "ShowHidden", false, Color3.fromRGB(206, 235, 236), 0.45)
visualToggle(left, "Visualize Target", "VisualizeTarget", false, red)
visualToggle(left, "Box", "Box", true, cyan)
visualToggle(left, "Box Filled", "BoxFilled", true, Color3.fromRGB(75, 159, 151), 0.5)
left:AddDropdown({Text = "Box Type", Flag = "BoxType", Options = {"Normal", "Corner"}, Default = "Normal"})
visualToggle(left, "Skeletons", "Skeletons", false, white)
visualToggle(left, "Health", "Health", true)
visualToggle(left, "Name", "Name", true, white)
left:AddDropdown({Text = "Name Type", Flag = "NameType", Options = {"Username", "Display name"}, Default = "Username", Callback = updatePreview})
visualToggle(left, "Tracers", "Tracers", false, cyan)
left:AddDropdown({Text = "Tracer Origin", Flag = "TracerOrigin", Options = {"Top", "Center", "Bottom"}, Default = "Top"})
visualToggle(left, "Weapon", "Weapon", true, white)
visualToggle(left, "Distance", "Distance", true, white)
visualToggle(left, "Flags", "Flags", true, white)
left:AddSlider({Text = "Max Distance", Flag = "MaxDistance", Min = 0, Max = 6000, Default = 1000, Step = 10})

right:AddSpacer(7)
visualToggle(right, "Sonar", "Sonar", false, teal, 0.3)
right:AddDropdown({Text = "Ping Mode", Flag = "PingMode", Options = {"Circle", "Pulse", "Outline"}, Default = "Circle"})
visualToggle(right, "Auto Ping", "AutoPing", false)
right:AddSpacer(1)
right:AddSlider({Text = "Auto Ping Interval", Flag = "PingInterval", Min = 0, Max = 13.5, Default = 3, Step = 0.05, Decimals = 2})
right:AddSlider({Text = "Ping Radius", Flag = "PingRadius", Min = 0, Max = 675, Default = 150, Step = 1, Decimals = 2})
right:AddSlider({Text = "Ping Speed", Flag = "PingSpeed", Min = 0, Max = 600, Default = 200, Step = 1, Decimals = 2})
visualToggle(right, "Team Flag", "TeamFlag", true, white)
visualToggle(right, "Look Tracer", "LookTracer", false, cyan)
right:AddSlider({Text = "Look Tracer Length", Flag = "LookTracerLength", Min = 0, Max = 24, Default = 5, Step = 0.1, Decimals = 2})
visualToggle(right, "Head Dot", "HeadDot", false, red)
visualToggle(right, "OOF Arrows", "OOFArrows", false, cyan)
right:AddSlider({Text = "Arrow Radius", Flag = "ArrowRadius", Min = 0, Max = 350, Default = 70, Step = 1, Decimals = 2})
right:AddSlider({Text = "Arrow Size", Flag = "ArrowSize", Min = 0, Max = 40, Default = 8, Step = 1, Decimals = 2})

local aimLeft = aim:AddSection({Title = "Controls", Side = "Left"})
aimLeft:AddSpacer(8)
aimLeft:AddLabel("Interface demonstration", {Height = 25})
aimLeft:AddLabel("Connect these controls to your own game.", {Muted = true, Height = 28})
aimLeft:AddToggle({Text = "Enabled", Flag = "AimDemoEnabled", Default = false, Color = cyan})
aimLeft:AddDropdown({Text = "Mode", Flag = "AimDemoMode", Options = {"Hold", "Toggle"}})
aimLeft:AddKeybind({Text = "Activation key", Flag = "AimDemoKey", Default = Enum.KeyCode.E})
aimLeft:AddSlider({Text = "Sensitivity", Flag = "AimDemoSensitivity", Min = 0, Max = 1, Default = 0.35, Step = 0.01, Decimals = 2})
aimLeft:AddSlider({Text = "Radius", Flag = "AimDemoRadius", Min = 0, Max = 500, Default = 120, Step = 1})
local aimRight = aim:AddSection({Title = "Display", Side = "Right"})
aimRight:AddSpacer(8)
aimRight:AddToggle({Text = "Show radius", Flag = "AimDemoShowRadius", Default = true, Color = cyan})
aimRight:AddToggle({Text = "Show center", Flag = "AimDemoShowCenter", Default = false, Color = white})
aimRight:AddDropdown({Text = "Indicator style", Flag = "AimDemoStyle", Options = {"Minimal", "Detailed"}})
aimRight:AddLabel("This page stores UI state only.", {Muted = true, Height = 38})

local lightLeft = lighting:AddSection({Title = "Preview Lighting", Side = "Left"})
lightLeft:AddSpacer(8)
lightLeft:AddSlider({Text = "Brightness", Flag = "PreviewBrightness", Min = 0, Max = 1, Default = 0.7, Step = 0.01,
    Callback = function(value)
        window.Preview.Viewport.Ambient = Color3.new(value, value, value)
    end,
})
lightLeft:AddColorPicker({Text = "Light color", Flag = "PreviewLightColor", Default = Color3.fromRGB(182, 199, 206),
    Callback = function(value) window.Preview.Viewport.LightColor = value.Color end,
})
lightLeft:AddColorPicker({Text = "Avatar tint", Flag = "PreviewAvatarTint", Default = Color3.fromRGB(155, 190, 187),
    Callback = function(value) window.Preview.Viewport.ImageColor3 = value.Color end,
})
local lightRight = lighting:AddSection({Title = "Appearance", Side = "Right"})
lightRight:AddSpacer(8)
lightRight:AddSlider({Text = "Avatar opacity", Flag = "PreviewOpacity", Min = 0, Max = 1, Default = 1, Step = 0.01,
    Callback = function(value) window:UpdatePreview({ImageTransparency = 1 - value}) end,
})
lightRight:AddLabel("Lighting affects the preview avatar.", {Muted = true, Height = 32})

local moveLeft = movement:AddSection({Title = "Input", Side = "Left"})
moveLeft:AddSpacer(8)
moveLeft:AddDropdown({Text = "Input profile", Flag = "MovementProfile", Options = {"Keyboard", "Controller", "Touch"}})
moveLeft:AddToggle({Text = "Show input indicator", Flag = "MovementIndicator", Default = false})
moveLeft:AddSlider({Text = "Dead zone", Flag = "MovementDeadzone", Min = 0, Max = 1, Default = 0.15, Step = 0.01})
local moveRight = movement:AddSection({Title = "Window", Side = "Right"})
moveRight:AddSpacer(8)
moveRight:AddLabel("Drag either title bar to move the UI.", {Muted = true, Height = 32})
moveRight:AddLabel("The window stays inside your screen.", {Muted = true, Height = 32})
moveRight:AddButton({Text = "Center window", Callback = function() window:SetScale(window.RequestedScale) end})

local settingsLeft = settings:AddSection({Title = "Interface", Side = "Left"})
settingsLeft:AddSpacer(8)
settingsLeft:AddKeybind({Text = "Toggle menu", Flag = "MenuKey", Default = Enum.KeyCode.RightShift,
    Callback = function(value) window.ToggleKey = value end,
})
settingsLeft:AddSlider({Text = "Interface scale", Flag = "InterfaceScale", Min = 0.5, Max = 1.5, Step = 0.05, Default = 1, Decimals = 2,
    Callback = function(value) window:SetScale(value) end,
})
settingsLeft:AddColorPicker({Text = "Accent color", Flag = "AccentColor", Default = window.Theme.Accent,
    Callback = function(value) window:SetAccent(value.Color) end,
})
settingsLeft:AddButton({Text = "Reset all settings", Callback = function() window:ResetConfig() end})
local settingsRight = settings:AddSection({Title = "Serotonin", Side = "Right"})
settingsRight:AddSpacer(8)
settingsRight:AddLabel("Client-side interface library", {Height = 26})
settingsRight:AddLabel("Native Roblox UI. No external assets required.", {Muted = true, Wrapped = true, Height = 38})
settingsRight:AddLabel("Right Shift toggles the menu.", {Muted = true, Height = 26})
settingsRight:AddLabel("Click a color chip to edit its color and opacity.", {Muted = true, Wrapped = true, Height = 38})
settingsRight:AddButton({Text = "Hide menu", Callback = function() window:SetVisible(false) end})
settingsRight:AddButton({Text = "Test notification", Callback = function()
    window:Notify({Title = "Serotonin", Text = "Your interface is ready.", Type = "Success", Duration = 5})
end})

local configLeft = configs:AddSection({Title = "Configuration", Side = "Left"})
configLeft:AddSpacer(8)
local configText = configLeft:AddTextbox({Text = "Configuration JSON", Multiline = true, Height = 235,
    Placeholder = "Export your settings, or paste a configuration here.",
})
local status
configLeft:AddButton({Text = "Export current settings", Callback = function()
    configText:SetValue(window:ExportConfig(), true)
    status.Text = "Exported. Select the text to copy it."
    status.TextColor3 = window.Theme.Accent
    window:Notify({Title = "Configuration exported", Text = "Select the JSON to copy your settings.", Type = "Success"})
end})
configLeft:AddButton({Text = "Import configuration", Callback = function()
    local ok, message = window:ImportConfig(configText.TextBox.Text)
    status.Text = ok and "Configuration applied." or message
    status.TextColor3 = ok and window.Theme.Accent or Color3.fromRGB(228, 121, 121)
    window:Notify({Title = ok and "Configuration applied" or "Import failed", Text = ok and "Your settings have been restored." or message, Type = ok and "Success" or "Error"})
end})
local configRight = configs:AddSection({Title = "Saved State", Side = "Right"})
configRight:AddSpacer(8)
status = configRight:AddLabel("Ready.", {Muted = true, Wrapped = true, Height = 42})
configRight:AddLabel("Configurations include control values, colors,\nkeybinds, and interface preferences.", {Muted = true, Wrapped = true, Height = 54})
configRight:AddLabel("Copy exported JSON to save it between sessions.", {Muted = true, Wrapped = true, Height = 44})
configRight:AddButton({Text = "Restore defaults", Callback = function()
    window:ResetConfig()
    configText:SetValue("", true)
    status.Text = "Defaults restored."
    status.TextColor3 = window.Theme.Accent
end})

window:SelectTab("Visuals")
updatePreview()

-- Build a local avatar from its appearance; fall back to the native mannequin.
-- The task may yield, so always dispose of late results after window destruction.
task.spawn(function()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(humanoid:GetAppliedDescription(), Enum.HumanoidRigType.R6)
    end)
    if ok and model then
        if not window._destroyed then window:SetPreviewModel(model) end
        model:Destroy()
    end
end)

return window
