# ESP and preview

## Automatic native ESP preview

Create the window with `Features = {ESP = true, Preview = true}`, then call `window:CreateESP({Preview = true})`. The controller mirrors a registered target's model and visual options. `esp:SetPreviewEnabled(false)` stops mirroring; `true` resumes. Panel visibility remains controlled by `window:SetPreviewVisible(...)`. Only one controller should drive a window's preview. The model is a snapshot and the health bar is illustrative.

[Guide](../README.md) · [API](API.md) · [Notifications](NOTIFICATIONS.md)

| Feature | What it draws | Opt in |
| --- | --- | --- |
| Live ESP | Overlays for models/players explicitly registered by the developer. | `Features.ESP = true`, then `CreateESP`. |
| Isolated preview | A cloned model in the UI's private ViewportFrame. | `Features.Preview = true`. |

The reference demo demonstrates preview/control state. Labels such as Aimbot, Sonar and Skeletons do not install those gameplay systems. The live ESP API supports exactly the options listed below.

## Live ESP

After loading UI as shown in the main guide:

```lua
local window = UI.new({Title = "My game tools", Features = {ESP = true}})
local esp = window:CreateESP({
    Enabled = false, Box = true, Name = true, Health = true, Distance = true,
    Color = Color3.fromRGB(125, 238, 245), MaxDistance = 1000, ThroughWalls = false,
})
local dummy = workspace:WaitForChild("TrainingDummy") -- a Model in your game
local target = esp:Add(dummy, {Name = "Training dummy"})
esp:SetEnabled(true)
```

CreateESP adds **no targets** and defaults to disabled. It draws only registered models available to this client, using native GUI and Highlights. It needs no Drawing API, remotes, or server code.

### Add, change and remove models

```lua
local target = esp:Add(workspace.TrainingDummy, {
    Name = "Training dummy", Color = Color3.fromRGB(90, 220, 170),
})
target:SetOptions({Name = "Objective"}) -- merge target options
target:Remove()                        -- same as esp:Remove(model)
```

Targets must be Models. Models without a BasePart or outside Workspace are hidden until usable. Destroyed models are removed automatically. Re-adding the same model returns its existing handle and replaces its options. Target options support only Name and Color; other drawing settings belong to the controller.

### Track a selected player across respawns

```lua
local tracker = esp:TrackPlayer(somePlayer, {Name = somePlayer.DisplayName})
-- Handles CharacterAdded/CharacterRemoving for this one player.
tracker:Disconnect() -- remove current overlay; stop future tracking
```

The developer chooses somePlayer; there is no automatic global player scan. Leaving the game disconnects the tracker. A controller tracks each player once. Use either Add(character) or TrackPlayer(player) for a character, not both. Removing its current model alone does not stop future respawn tracking: disconnect the tracker.

### Wire only the controls you need

```lua
local section = window:AddTab("Visuals"):AddSection({Title = "ESP"})
section:AddToggle({Text = "Enabled", Flag = "ESPEnabled", Default = false,
    Callback = function(value) esp:SetEnabled(value) end})
section:AddToggle({Text = "Boxes", Flag = "Boxes", Default = true,
    Callback = function(value) esp:SetOptions({Box = value}) end})
section:AddSlider({Text = "Max distance", Flag = "MaxDistance", Min = 0, Max = 5000, Step = 10, Default = 1000,
    Callback = function(value) esp:SetOptions({MaxDistance = value}) end})
section:AddColorPicker({Text = "Color", Flag = "ESPColor", Default = Color3.fromRGB(125, 238, 245),
    Callback = function(value) esp:SetOptions({Color = value.Color}) end})
```

Delete controls you do not want. Omitting a control does not change the ESP default; also select the intended options in CreateESP/SetOptions. Defaults are silent, so keep controller/control initial values consistent or explicitly synchronize them after construction.

### Controller options

`esp:SetOptions(changes)` validates and merges changes, returning the controller. Invalid updates leave existing options intact.

| Option | Default | Meaning |
| --- | --- | --- |
| `Enabled` | `false` | Master switch; no render loop while disabled or without targets. |
| `Preview` | `false` | Mirror target and drawing options into the window preview; requires Features.Preview. |
| `Box` | `true` | Thin 2D bounding rectangle. |
| `BoxFilled` | `false` | Translucent rectangle fill. |
| `Name` | `true` | Label above model. |
| `Health` | `true` | Vertical bar; requires a Humanoid. |
| `Distance` | `true` | Camera-to-model distance in **studs**. |
| `Tracer` | `false` | Thin line from screen origin to box bottom. |
| `Highlight` | `false` | Native 3D Highlight. |
| `ThroughWalls` | `false` | False checks a camera-to-center ray. True skips this check. Also sets Highlight depth mode. |
| `MaxDistance` | `1000` | 0–100,000 studs from camera. |
| `Color` | RGB 125, 238, 245 | Box/fill/text/tracer/Highlight color, unless target overrides it. |
| `FillTransparency` | `0.85` | Rectangle/Highlight fill transparency, 0–1. |
| `TextSize` | `12` | Label size, 8–24. |
| `TracerOrigin` | `"Bottom"` | Top, Center, or Bottom, horizontally centered. |

Boxes project the eight corners of Model:GetBoundingBox through the current camera. Keep target models free of distant helper parts or oversized accessories for tight bounds. Boxes clip to the viewport. Targets intersecting/behind the camera near plane hide to avoid unstable projections. ThroughWalls false uses one center ray, not per-part visibility. Streamed-out parts cannot be drawn until present. Work scales with registered target count; register the subset your game needs.

Projection and highlighting use Roblox's [WorldToViewportPoint](https://create.roblox.com/docs/reference/engine/classes/Camera#WorldToViewportPoint) and [Highlight depth modes](https://create.roblox.com/docs/reference/engine/classes/Highlight#DepthMode).

### Cleanup

```lua
esp:SetEnabled(false) -- temporarily hide
esp:Remove(model)     -- remove one model
esp:Destroy()         -- remove controller, targets, trackers and render connection
window:Destroy()      -- also destroys all owned ESP controllers
```

Hiding the menu does not disable ESP. Keep controller/target/tracker handles in your script. The starter registers only child models in optional **Workspace.ESPTargets** and starts disabled. Create that folder, add desired models, then enable the UI toggle.

## Isolated preview

```lua
local window = UI.new({Features = {Preview = true}, PreviewTitle = "My preview"})
window:SetPreviewModel(workspace:WaitForChild("TrainingDummy"))
window:UpdatePreview({
    Box = true, BoxFilled = true, Name = true, Health = true,
    BoxColor = Color3.fromRGB(125, 238, 245),
    FillColor = Color3.fromRGB(17, 181, 171), FillTransparency = 0.85,
    NameText = "Training dummy", FlagsText = "ALLY", DetailsText = "PREVIEW",
})
```

The model is cloned into a private WorldModel. Scripts, sounds and particle effects are removed; the original is untouched. Nil/non-archivable models use the built-in mannequin. Supply a model with geometry for sensible framing. `SetPreviewModel(nil)` restores the mannequin. The clone is a snapshot, not a live animated character link.

| UpdatePreview option | Value |
| --- | --- |
| Box, BoxFilled, Name, Health, HeadDot, Flags, Details | Boolean visibility. |
| BoxColor, FillColor, NameColor, HeadColor | Color3. |
| FillTransparency, ImageTransparency | 0–1 transparency. |
| NameText, FlagsText, DetailsText | Strings; newline separates lines. |

Only supplied fields change. Calls do nothing when preview is disabled. Preview health is a static visual example. Lighting can be edited through `window.Preview.Viewport.Ambient`, `.LightColor` and `.ImageColor3`.

`SetPreviewVisible(false)` hides the panel and reduces window width; true restores it. Preview must have been enabled at construction. Live ESP and preview settings are independent unless the controller's `Preview` option is enabled.
