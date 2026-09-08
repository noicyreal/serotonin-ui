-- Run with the installed ReplicatedStorage.Serotonin ModuleScript.
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("Serotonin"))
local passed, owned = {}, {}
local function check(name, value)
    assert(value, "FAILED: " .. name)
    table.insert(passed, name)
end
local function keep(object) table.insert(owned, object); return object end
local function waitUntil(predicate)
    local deadline = os.clock() + 2
    repeat if predicate() then return true end; task.wait() until os.clock() > deadline
    return false
end
local ok, problem = xpcall(function()
    local minimal = keep(UI.new({Name = "SerotoninMinimalTest", Features = {Notifications = false}}))
    minimal:SetVisible(false)
    check("default window has no tabs, preview, ESP or notification UI", #minimal._tabs == 0 and minimal.Preview == nil and #minimal._espControllers == 0 and minimal.NotificationGui == nil)
    check("disabled notifications allocate nothing", minimal:Notify({Text = "Hidden"}) == nil and minimal.NotificationGui == nil)
    check("ESP requires explicit opt-in", not pcall(function() minimal:CreateESP() end))
    minimal:Destroy()

    local w = keep(UI.new({Name = "SerotoninFeatureTest", Features = {Preview = true, ESP = true}, Notifications = {MaxVisible = 1, Position = "TopRight"}}))
    w:SetVisible(false)
    w:SetPreviewVisible(false)
    check("hiding preview reclaims its width", w.Width == w.MainWidth and not w.Preview.Panel.Visible)
    w:SetPreviewVisible(true)
    check("showing preview restores its width", w.Width == w.MainWidth + 360 and w.Preview.Panel.Visible)

    local reasons = {}
    local first = w:Notify({Title = "First", Duration = 0, OnClose = function(reason) table.insert(reasons, reason) end})
    local second = w:Notify({Title = "Second", Duration = 0})
    check("first notification displays while menu is hidden", waitUntil(function() return first.Phase == "Visible" end) and w.NotificationGui.Enabled and not w.Gui.Enabled)
    check("MaxVisible queues excess notices", second.Phase == "Queued" and second.Instance == nil)
    check("notification updates render", first:Update({Title = "Updated", Type = "Success"}) and first.Instance.Title.Text == "Updated")
    first:Dismiss("Test")
    first:Dismiss("Duplicate")
    check("dismiss callback fires exactly once", waitUntil(function() return first.Closed end) and #reasons == 1 and reasons[1] == "Test")
    check("queue advances", waitUntil(function() return second.Phase == "Visible" end))
    second.Hovered = true
    second:Update({Duration = 0.05})
    task.wait(0.12)
    check("hover pauses expiration", not second.Closed and second.Elapsed == 0)
    second.Hovered = false
    check("expiration drains queue and disconnects loop", waitUntil(function() return second.Closed and w._noticeConnection == nil end))
    check("closed notification cannot update", second:Update({Title = "Late"}) == false)
    for i = 1, 32 do w:Notify({Title = "Queued " .. i, Duration = 0}) end
    check("queue is bounded", w:Notify({Title = "Overflow"}) == nil and #w._notices == 32)
    for _, notice in ipairs(w._notices) do notice:Dismiss() end
    check("queued cancellation cleans up", waitUntil(function() return #w._notices == 0 end))

    local model = keep(Instance.new("Model"))
    model.Name = "SerotoninESPTestTarget"
    local part = Instance.new("Part")
    part.Size = Vector3.new(3, 5, 2)
    part.Anchored, part.CanCollide, part.CanTouch = true, false, false
    part.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(-4, 0, -18)
    part.Parent = model
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth, humanoid.Health = 100, 45
    humanoid.Parent = model
    model.Parent = workspace
    local esp = w:CreateESP({Enabled = false, ThroughWalls = true, BoxFilled = true, Tracer = true, Highlight = true, Preview = true})
    local target = esp:Add(model, {Name = "Test target"})
    check("ESP preview mirrors the selected target", w.Preview.Panel.Visible and w.Preview.Model.Name == model.Name and w.Preview.Name.Text == "Test target")
    check("disabled ESP has no render connection", esp._connection == nil and not target.Frame.Visible)
    esp:SetEnabled(true)
    esp:_render()
    check("selected target projects with configured visuals", target.Frame.Visible and target.Frame.Size.X.Offset > 0 and target.Box.Visible and target.Tracer.Visible and target.Highlight.Enabled)
    check("name and humanoid health render", target.Name.Text == "Test target" and math.abs(target.HealthFill.Size.Y.Scale - 0.45) < 0.001)
    check("re-adding model does not duplicate targets", esp:Add(model) == target)
    esp:SetOptions({MaxDistance = 1})
    esp:_render()
    check("distance culling hides target", not target.Frame.Visible and not target.Highlight.Enabled)
    check("invalid ESP update is atomic", not pcall(function() esp:SetOptions({Box = false, MaxDistance = -1}) end) and esp.Options.Box and esp.Options.MaxDistance == 1)
    esp:SetOptions({MaxDistance = 1000})
    part.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, 18)
    esp:_render()
    check("behind-camera targets hide", not target.Frame.Visible)
    part.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -18)
    local wall = keep(Instance.new("Part"))
    wall.Name = "SerotoninESPTestOccluder"
    wall.Size = Vector3.new(10, 10, 1)
    wall.Anchored, wall.CanCollide = true, false
    wall.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -9)
    wall.Parent = workspace
    esp:SetOptions({ThroughWalls = false})
    esp:_render()
    check("occlusion check hides obstructed target", not target.Frame.Visible)
    esp:SetOptions({ThroughWalls = true})
    esp:_render()
    check("ThroughWalls enables obstructed target", target.Frame.Visible)
    wall:Destroy()
    model:Destroy()
    check("destroyed targets remove themselves and stop rendering", waitUntil(function() return target.Removed and esp._connection == nil end))
    esp:SetEnabled(false)
    local tracker = esp:TrackPlayer(game:GetService("Players").LocalPlayer)
    check("explicit player tracker attaches current character", esp.Targets[game:GetService("Players").LocalPlayer.Character] ~= nil)
    tracker:Disconnect()
    check("tracker disconnect removes target and listeners", not tracker.Connected and next(esp.Targets) == nil and not tracker._connections[1].Connected)
    local closeCount = 0
    w:OnDestroy(function() closeCount += 1 end)
    local toast = w:Notify({Title = "Destroy test", Duration = 0})
    w:Destroy()
    w:Destroy()
    check("owner destruction cleans all optional features once", closeCount == 1 and esp._destroyed and toast.Closed and w._noticeConnection == nil and w.NotificationGui.Parent == nil)
end, debug.traceback)
for i = #owned, 1, -1 do owned[i]:Destroy() end
if not ok then error(problem) end
print("[Serotonin] " .. #passed .. " feature checks passed")
return {Passed = #passed, Checks = passed}
