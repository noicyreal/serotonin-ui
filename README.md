# Serotonin UI

Custom client-side executor UI library inspired by the supplied dark and teal reference. The developer chooses every tab, control, ESP target, and optional feature.

## Load the library

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/noicyreal/serotonin-ui/main/Serotonin.luau"))()
```

Loading returns the library; no window is created until you call Library.new. Requires an executor with loadstring and game:HttpGet.

## Run the example

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/noicyreal/serotonin-ui/main/example.luau"))()
```

Edit [example.luau](example.luau) to select Preview, ESP, ESPPreview, Notifications, ControlsPage, SettingsPage, and ConfigsPage. Remove individual Add* calls to remove controls.

## FRONTLINES conversion

[frontlines-serotonin.luau](frontlines-serotonin.luau) converts the supplied FRONTLINES script from Pepsi UI to Serotonin while preserving its actor payload and command callbacks. It includes Combat, Visuals, Settings, and Configs tabs; Hitbox and accent-mode dropdowns; toggles; sliders; a color picker; keybind; multiline config textbox; buttons; live status labels; notifications; and an optional ESP settings preview.

Run it from an executor in the supported FRONTLINES place:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/noicyreal/serotonin-ui/main/frontlines-serotonin.luau"))()
```

See [the FRONTLINES guide](docs/FRONTLINES.md) for the complete control map.

## Create your own UI

```lua
local window = Library.new({
    Title = "my interface",
    Features = {Preview = true, ESP = true, Notifications = true},
})
local section = window:AddTab("Visuals"):AddSection({Title = "Options"})
local esp = window:CreateESP({Enabled = false, Preview = true})
section:AddToggle({Text = "Enable ESP", Flag = "ESPEnabled", Default = false,
    Callback = function(value) esp:SetEnabled(value) end})
section:AddToggle({Text = "Use ESP preview", Flag = "ESPPreview", Default = true,
    Callback = function(value) esp:SetPreviewEnabled(value) end})
window:Notify({Title = "Ready", Text = "Your UI is loaded.", Type = "Success", Duration = 4})
```

Add selected models with esp:Add(model), or track selected players with esp:TrackPlayer(player). No targets are registered automatically by the library. The example optionally registers models inside Workspace.ESPTargets.

Preview=true on the ESP controller mirrors its target and visual settings into the side panel. SetPreviewEnabled(false) stops mirroring; window:SetPreviewVisible(false) hides the panel. Preview health is illustrative and the model is a snapshot.

## Documentation

- [Executor loading](docs/EXECUTOR.md)
- [Controls and configuration API](docs/API.md)
- [ESP and optional preview](docs/ESP.md)
- [Notifications](docs/NOTIFICATIONS.md)
- [FRONTLINES conversion](docs/FRONTLINES.md)
- [Validation](docs/VALIDATION.md)

Call window:Destroy() when unloading. This cleans up owned GUI, ESP, notifications, and connections.

## Files and build

Serotonin.luau is the library; example.luau is the editable executor starter. SerotoninDemo.client.luau is the self-contained reference demo. Generated compatibility bundles and the importable demo are also included.

Run node build.mjs from the repository directory to regenerate bundles. SmokeTest.client.luau and FeatureTest.client.luau cover controls, configuration, optional features, ESP, and cleanup.
