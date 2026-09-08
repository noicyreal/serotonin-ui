-- SEROTONIN UI v2 | editable developer starter
-- Full documentation: README.md. The library itself adds no tabs or targets.

-- BEGIN LIBRARY LOADER
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/noicyreal/serotonin-ui/main/Serotonin.luau"))()
local UI = Library
-- END LIBRARY LOADER

-- EDIT THIS TABLE: only the features and pages selected here are created.
local FEATURES = {
    Preview = true,
    ESP = true,
    ESPPreview = true, -- auto-mirror the registered ESP target and settings in the preview panel
    Notifications = true,
    ControlsPage = true,
    SettingsPage = true,
    ConfigsPage = true,
}

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("SerotoninExample")
if previous then previous:Destroy() end

local window = UI.new({
    Name = "SerotoninExample", Title = "serotonin - developer example",
    Features = {Preview = FEATURES.Preview, ESP = FEATURES.ESP, Notifications = FEATURES.Notifications},
    Notifications = {Position = "BottomRight", Duration = 5, MaxVisible = 3, Width = 310},
    ToggleKey = Enum.KeyCode.RightShift,
})

-- Live ESP is optional and only draws the targets you explicitly add.
local esp = FEATURES.ESP and window:CreateESP({
    Enabled = false,
    ThroughWalls = false,
    Preview = FEATURES.Preview == true and FEATURES.ESPPreview == true,
}) or nil

-- This example picks only models inside your optional Workspace.ESPTargets folder.
-- Create that folder in your game and put NPC/object models inside it.
local targetsFolder = workspace:FindFirstChild("ESPTargets")
if esp and targetsFolder then
    local function addTarget(model)
        if model:IsA("Model") then esp:Add(model, {Name = model.Name}) end
    end
    for _, model in ipairs(targetsFolder:GetChildren()) do addTarget(model) end
    local added = targetsFolder.ChildAdded:Connect(addTarget)
    local removed = targetsFolder.ChildRemoved:Connect(function(model) esp:Remove(model) end)
    window:OnDestroy(function() added:Disconnect(); removed:Disconnect() end)
end

-- Alternative explicit target examples (uncomment the ones your game needs):
-- local target = esp:Add(workspace:WaitForChild("TrainingDummy"), {Name = "Training dummy"})
-- local tracker = esp:TrackPlayer(somePlayer) -- follows that one player's respawns
-- target:Remove()                          -- stop drawing one model
-- tracker:Disconnect()                     -- stop tracking that player
-- Do not call Add and TrackPlayer for the same character at the same time.

local function notify(title, text, kind)
    return window:Notify({Title = title, Text = text, Type = kind or "Info"})
end

local function updateVisuals()
    local f = window.Flags
    local tint = f.ESPColor and f.ESPColor.Color or Color3.fromRGB(125, 238, 245)
    local transparency = f.ESPColor and f.ESPColor.Transparency or 0.85
    if esp then
        esp:SetOptions({Enabled = f.ESPEnabled == true, Box = f.DrawBox == true, BoxFilled = f.DrawFill == true,
            Name = f.DrawName == true, Health = f.DrawHealth == true, Distance = f.DrawDistance == true,
            Tracer = f.DrawTracer == true, Highlight = f.DrawHighlight == true,
            Color = tint, FillTransparency = transparency, MaxDistance = f.MaxDistance or 1000,
            Preview = f.UseESPPreview == true})
    end
    if FEATURES.Preview and not (esp and f.UseESPPreview == true) then
        window:UpdatePreview({Box = f.DrawBox == true, BoxFilled = f.DrawFill == true, Name = f.DrawName == true,
            Health = f.DrawHealth == true, Details = f.DrawDistance == true, BoxColor = tint,
            FillColor = tint, FillTransparency = transparency, DetailsText = "DISTANCE", FlagsText = ""})
    end
end

if FEATURES.ESP or FEATURES.Preview then
    local tab = window:AddTab("Visuals")
    local section = tab:AddSection({Title = "Choose your visuals", Side = "Left"})
    section:AddSpacer(8)
    if esp then
        section:AddToggle({Text = "Enable live ESP", Flag = "ESPEnabled", Default = false, Callback = updateVisuals})
    end
    -- Delete any Add* call to leave that control out of your interface.
    for _, item in ipairs({{"Box", "DrawBox", true}, {"Box filled", "DrawFill", true},
        {"Name", "DrawName", true}, {"Health", "DrawHealth", true}, {"Distance", "DrawDistance", true}}) do
        section:AddToggle({Text = item[1], Flag = item[2], Default = item[3], Callback = updateVisuals})
    end
    section:AddColorPicker({Text = "ESP color / fill opacity", Flag = "ESPColor",
        Default = {Color = Color3.fromRGB(125, 238, 245), Transparency = 0.85}, Callback = updateVisuals})
    local details = tab:AddSection({Title = "Options", Side = "Right"})
    details:AddSpacer(8)
    if esp then
        details:AddToggle({Text = "Tracers", Flag = "DrawTracer", Default = false, Callback = updateVisuals})
        details:AddToggle({Text = "Highlights", Flag = "DrawHighlight", Default = false, Callback = updateVisuals})
        if FEATURES.Preview then
            details:AddToggle({Text = "Use ESP preview", Flag = "UseESPPreview", Default = FEATURES.ESPPreview == true,
                Tooltip = "Mirror this ESP controller's selected target and visual settings in the preview panel.",
                Callback = updateVisuals})
        end
        details:AddSlider({Text = "Max distance", Flag = "MaxDistance", Min = 0, Max = 5000, Step = 10, Default = 1000, Callback = updateVisuals})
        details:AddLabel("Targets: models in Workspace.ESPTargets.", {Muted = true, Wrapped = true, Height = 42})
    end
    if FEATURES.Preview then
        details:AddButton({Text = "Show / hide preview", Callback = function()
            window:SetPreviewVisible(not window.Preview.Panel.Visible)
        end})
    end
    updateVisuals() -- Defaults are silent; explicitly apply your initial state.
end

if FEATURES.ControlsPage then
    local tab = window:AddTab("Controls")
    local section = tab:AddSection({Title = "Your own features", Side = "Left"})
    section:AddSpacer(8)
    section:AddToggle({Text = "My feature", Flag = "MyFeature", Default = false,
        Callback = function(value) notify("My feature", value and "Enabled" or "Disabled") end})
    section:AddDropdown({Text = "Mode", Flag = "Mode", Options = {"Normal", "Compact", "Detailed"}})
    section:AddSlider({Text = "Intensity", Flag = "Intensity", Min = 0, Max = 1, Step = 0.01, Default = 0.5})
    section:AddTextbox({Text = "Display name", Flag = "DisplayName", Default = "Developer"})
    local notices = tab:AddSection({Title = "Notifications", Side = "Right"})
    notices:AddSpacer(8)
    if FEATURES.Notifications then
        for _, kind in ipairs({"Info", "Success", "Warning", "Error"}) do
            notices:AddButton({Text = kind .. " notification", Callback = function()
                notify(kind, "A clean notification in your interface's style.", kind)
            end})
        end
        notices:AddButton({Text = "Update a notification", Callback = function()
            local toast = window:Notify({Title = "Working", Text = "Preparing your settings…", Duration = 0})
            if not toast then return end
            task.delay(1, function()
                if not toast.Closed then toast:Update({Title = "Ready", Text = "Your settings are ready.", Type = "Success", Duration = 4}) end
            end)
        end})
    else
        notices:AddLabel("Notifications are disabled in FEATURES.", {Muted = true, Wrapped = true, Height = 40})
    end
end

if FEATURES.SettingsPage then
    local section = window:AddTab("Settings"):AddSection({Title = "Interface"})
    section:AddSpacer(8)
    section:AddKeybind({Text = "Toggle menu", Flag = "MenuKey", Default = Enum.KeyCode.RightShift,
        Callback = function(key) window:SetToggleKey(key) end})
    section:AddSlider({Text = "Scale", Flag = "Scale", Min = 0.5, Max = 1.5, Step = 0.05, Default = 1,
        Callback = function(value) window:SetScale(value) end})
    section:AddColorPicker({Text = "Accent", Flag = "Accent", Default = window.Theme.Accent,
        Callback = function(value) window:SetAccent(value.Color) end})
    section:AddButton({Text = "Reset settings", Callback = function() window:ResetConfig(); notify("Reset", "Defaults restored.", "Success") end})
end

if FEATURES.ConfigsPage then
    local section = window:AddTab("Configs"):AddSection({Title = "Configuration"})
    section:AddSpacer(8)
    -- No Flag: the exported document must not contain a copy of itself.
    local json = section:AddTextbox({Text = "Configuration JSON", Multiline = true, Height = 225})
    section:AddButton({Text = "Export", Callback = function()
        json:SetValue(window:ExportConfig(), true)
        notify("Exported", "Select the JSON text to copy it.", "Success")
    end})
    section:AddButton({Text = "Import", Callback = function()
        local ok, problem = window:ImportConfig(json.TextBox.Text)
        notify(ok and "Imported" or "Import failed", ok and "Configuration applied." or problem, ok and "Success" or "Error")
    end})
end

if not window.ActiveTab then window:AddTab("Home"):AddSection({Title = "Your interface"}):AddLabel("Add the controls your project needs.") end
notify("Serotonin ready", "Right Shift toggles your menu.", "Success")
return window
