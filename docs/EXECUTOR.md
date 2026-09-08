# Executor setup

[Guide](../README.md) · [API](API.md) · [ESP](ESP.md)

Load your custom Serotonin UI library:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/noicyreal/serotonin-ui/main/Serotonin.luau"))()
local window = Library.new({Title = "My interface", Features = {Preview = true, ESP = true}})
```

The executor must provide game:HttpGet and loadstring. The final parentheses execute the downloaded library and return its API table.

For local development, copy Serotonin.luau into your executor workspace and use:

```lua
local Library = assert(loadstring(readfile("Serotonin.luau")))()
```

[example.luau](../example.luau) uses the published HTTP loader. Edit its FEATURES table to choose pages, notifications, ESP, and the optional preview. Bind controls to your own behavior with Callback functions.

For your own ESP implementation, enable Features.Preview and call window:SetPreviewModel(model) and window:UpdatePreview(options). For the bundled ESP controller, CreateESP({Preview = true}) automatically mirrors its target and settings. Full options are in [ESP.md](ESP.md).
