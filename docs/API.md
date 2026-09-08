# Controls and configuration

[Guide](../README.md) · [ESP](ESP.md) · [Notifications](NOTIFICATIONS.md)

## Window options

Call `UI.new(options)` using the table returned by `loadstring(...)()` or `require(...)`.

| Option | Default | Meaning |
| --- | --- | --- |
| `Name` | `"SerotoninUI"` | ScreenGui name; use a distinct name per window. |
| `Title` | `"serotonin - roblox"` | Title text. |
| `Width` / `Height` | `616` / `538` | Main-panel design pixels; minimum 440 / 300. |
| `Scale` | `1` | Requested scale, 0.5–2; reduced automatically to fit the screen. |
| `ToggleKey` | `Enum.KeyCode.RightShift` | Menu shortcut. |
| `Features.Preview` | `false` | Creates a 350-pixel preview panel with a 10-pixel gap. |
| `Features.ESP` | `false` | Permits live ESP controllers. |
| `Features.Notifications` | `true` | Permits lazy notification creation. |
| `PreviewTitle` | `"ESP Preview"` | Preview title. |
| `Parent` | local PlayerGui | Parent for menu and auxiliary ScreenGuis. |
| `DisplayOrder` | `50` | Menu order; notifications +1, ESP −1 (minimum 0). |
| `Notifications` | [see guide](NOTIFICATIONS.md) | Position, width, duration, stack size. |
| `Theme` | built-in palette | Color3 overrides. |

Theme keys: `Background`, `Panel`, `Header`, `Field`, `Border`, `Text`, `Muted`, `Accent`, `Hover`. `Hover` is reserved; current hover states change borders/text. `SetAccent` updates live bindings; other colors are construction-time options.

Features are fixed at construction. `SetPreviewVisible` hides an existing preview; `esp:SetEnabled` switches a created controller. Create a new window to add a feature disabled at construction.

## Window methods

| Method | Result / behavior |
| --- | --- |
| `AddTab(name)` | New tab; unique nonempty name. First tab is selected automatically. |
| `SelectTab(name)` | Selects one page, closes popups. |
| `SetVisible(bool)` | Menu and preview visibility. |
| `SetToggleKey(Enum.KeyCode)` | Change menu shortcut. |
| `SetScale(number)` | Update scale and center window. |
| `SetAccent(Color3)` | Update live UI accents. ESP colors remain separate. |
| `SetPreviewVisible(bool)` | Adjust preview visibility and window width. |
| `Notify(options)` | Notification handle, or `nil, reason` if disabled/full. |
| `CreateESP(options)` | Live ESP controller; requires its feature enabled. |
| `ExportConfig()` | Versioned JSON string. |
| `ImportConfig(json)` | `true` or `false, errorMessage`. |
| `ResetConfig()` | Restore control defaults, invoke callbacks. |
| `OnDestroy(callback)` | Register external cleanup; return window. |
| `Destroy()` | Release resources; idempotent. |

Public fields: `Flags[flag]`, `Controls[flag]`, `Tabs[name]`, `ActiveTab`, `Gui`, `Theme`, `Features`, and `Preview` when enabled. Treat Flags as read-only: change a value through its control to update UI and callbacks.

## Sections

```lua
local tab = window:AddTab("General")
local left = tab:AddSection({Title = "General", Side = "Left"})
local top = tab:AddSection({Title = "Appearance", Side = "Right", Height = 210})
local bottom = tab:AddSection({Title = "Actions", Side = "Right", Height = 230})
```

Side defaults to Left. Without Height, a section fills its column. Give **every section sharing a column an explicit height**. Heights plus 10 pixels between sections must fit the page (450 pixels tall at default window height). Overflowing controls scroll inside the section.

## Common control options and methods

Value controls accept `Text`, optional unique nonempty `Flag`, `Default`, `Disabled`, and `Callback(value)`. A Flag registers a control in `window.Controls` / `window.Flags` and includes it in configuration. Initial defaults are silent. Callback errors warn with `[Serotonin]` and do not crash the UI.

```lua
control:GetValue()
control:SetValue(value)           -- validate, draw, update Flags, call callbacks
control:SetValue(value, true)     -- silent
control:SetDisabled(true)        -- blocks user edits; explicit SetValue still works
control:OnChanged(function(value) print(value) end) -- additional lifetime listener
```

SetValue invokes callbacks even when unchanged; avoid recursively setting the same control inside its callback. GetValue returns copies of color tables.

## Toggle

```lua
local toggle = section:AddToggle({Text = "Box", Flag = "Box", Default = true,
    Color = Color3.fromRGB(125, 238, 245), Transparency = 0, ColorFlag = "BoxTint",
    Callback = function(value) print(value) end,
    ColorCallback = function(value) print(value.Color, value.Transparency) end,
})
toggle.Color:SetValue(Color3.fromRGB(255, 120, 150))
```

Default is false. Color adds a separate optional chip at `toggle.Color`. Its flag defaults to the toggle Flag plus `"Color"`. Disabling the toggle affects its boolean input; use `toggle.Color:SetDisabled(true)` to disable its color chip too.

## Slider

```lua
section:AddSlider({Text = "Opacity", Flag = "Opacity", Min = 0, Max = 1,
    Step = 0.01, Decimals = 2, Default = 0.85})
```

Defaults: Min 0, Max 100, Step 1, value Min. Requires finite Min < Max and positive Step. Values clamp and round to the nearest step from Min. Decimals is optional, 0–6; specify it for steps such as 0.25. Suffix appends display text. Drag the bar or edit its number.

## Dropdown

```lua
section:AddDropdown({Text = "Mode", Flag = "Mode", Options = {"Normal", "Compact"}, Default = "Normal"})
```

Single selection from a nonempty list of unique strings. Default is the first option. Long lists scroll. Unknown values are rejected.

## Color picker

```lua
section:AddColorPicker({Text = "Tint", Flag = "Tint",
    Default = {Color = Color3.fromRGB(125, 238, 245), Transparency = 0.85},
    Callback = function(value) print(value.Color, value.Transparency) end,
})
```

Value: `{Color = Color3, Transparency = 0..1}`. Zero is opaque; one is transparent. A bare Color3 is accepted as an opaque value. Popup supports saturation/value, hue, hex and transparency. Hex accepts six digits with optional # and commits on focus loss. Disabled pickers cannot open.

## Keybind

```lua
section:AddKeybind({Text = "Action key", Flag = "ActionKey", Default = Enum.KeyCode.F,
    Callback = function(key) print("Rebound:", key.Name) end,
    OnPressed = function() print("Action") end,
})
```

Keyboard KeyCodes only. Click, then press a key; Escape cancels. Typing in textboxes suppresses shortcuts. Menu toggle takes precedence over action bindings. Action bindings continue while the menu is hidden. Mouse/controller binding is not implemented by this control.

## Textbox

```lua
local input = section:AddTextbox({Text = "Name", Flag = "Name", Default = "",
    Placeholder = "Enter a name", MaxLength = 200})
local json = section:AddTextbox({Text = "Configuration", Multiline = true, Height = 225})
```

Commits on focus loss. Defaults: empty, one line, height 23, maximum 65,536 bytes. Multiline enables wrapped text. `control.TextBox` is the native input; read `.Text` for an edit not yet committed. Keep export textboxes unflagged to avoid serializing the export into itself.

## Buttons, labels and spacing

```lua
local action = section:AddButton({Text = "Save", Callback = function() print("Save") end})
action:SetDisabled(true)
local text = section:AddLabel("Ready", {Muted = true, Height = 30, Wrapped = true})
text.Text = "Updated"
section:AddSpacer(8)
```

Buttons accept Text, Callback, Disabled; no value or Flag. Labels return a native TextLabel and support Muted, Height, Wrapped, TextSize. Spacer defaults to 8 pixels.

## Configuration

```lua
local saved = window:ExportConfig()
local ok, problem = window:ImportConfig(saved)
if not ok then window:Notify({Title = "Import failed", Text = problem, Type = "Error"}) end
```

Schema: `{Version = 1, Values = {...}}`. Colors become RGB arrays plus transparency; KeyCodes become names. Only flagged controls are exported. Layout, tabs, feature switches, unflagged values, ESP targets and notifications are not configuration data. Bind theme, scale and ESP options to flagged controls to persist them, as the example does.

Import validates all known values before applying anything. Invalid JSON/version/colors/keys/dropdowns reject the entire import. Unknown flags are ignored. Slider values undergo normal clamping/rounding. All values apply silently first, then callbacks run with the entire new flag state. Callback order is unspecified; read all needed flags in a synchronization function. Callback exceptions do not roll back valid values. Save exported JSON using your own persistence.

## Cleanup

```lua
local connection = someSignal:Connect(function() end)
window:OnDestroy(function() connection:Disconnect() end)
window:Destroy()
```

Cleanup runs once. Do not create/change resources after destruction. Keep delayed work conditional on its handles' lifetime. Re-running the starter destroys its previous named window.
