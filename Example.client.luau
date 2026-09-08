-- Generated Studio-compatible version of example.luau.
local Serotonin = (function()
--!nocheck
-- Serotonin UI | client-side, dependency-free Roblox UI library.
-- Returns the same API from loadstring(source)() or require(ModuleScript).
-- Loading this file creates nothing. See example.luau and README.md.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Serotonin = {Version = "2.0.0"}
local Window = {}
local Tab = {}
local Section = {}
local ESP = {}
ESP.__index = ESP
Window.__index = Window
Tab.__index = Tab
Section.__index = Section

local PALETTE = {
    Background = Color3.fromRGB(17, 21, 26),
    Panel = Color3.fromRGB(19, 25, 29),
    Header = Color3.fromRGB(16, 21, 25),
    Field = Color3.fromRGB(32, 39, 48),
    Border = Color3.fromRGB(44, 53, 65),
    Text = Color3.fromRGB(224, 227, 229),
    Muted = Color3.fromRGB(106, 111, 117),
    Accent = Color3.fromRGB(17, 181, 171),
    Hover = Color3.fromRGB(29, 36, 42),
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function frame(parent, name, position, size, color, border)
    return create("Frame", {
        Name = name,
        Position = position,
        Size = size,
        BackgroundColor3 = color,
        BorderSizePixel = border and 1 or 0,
        BorderColor3 = border or color,
        BorderMode = Enum.BorderMode.Inset,
    }, parent)
end

local function label(parent, name, text, position, size, color, textSize)
    return create("TextLabel", {
        Name = name,
        Text = text,
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.Arial,
        TextSize = textSize or 13,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function button(parent, name, position, size)
    return create("TextButton", {
        Name = name,
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, parent)
end

local function gradient(parent, top, bottom, rotation)
    return create("UIGradient", {
        Color = ColorSequence.new(top, bottom),
        Rotation = rotation or 90,
    }, parent)
end

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function copyValue(value)
    return type(value) == "table" and table.clone(value) or value
end

local function slug(text)
    return tostring(text):gsub("[^%w_]", "")
end

function Window:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function Window:_accent(object, property)
    object[property] = self.Theme.Accent
    table.insert(self._accentBindings, {object, property})
end

function Window:_callback(callback, ...)
    if callback then
        local ok, message = pcall(callback, ...)
        if not ok then
            warn("[Serotonin] Callback failed: " .. tostring(message))
        end
    end
end

function Window:_register(control, options, kind, validate, draw)
    local flag = options.Flag
    assert(not flag or (type(flag) == "string" and flag ~= ""), "Flag must be a nonempty string")
    assert(not flag or not self.Controls[flag], "Duplicate flag: " .. tostring(flag))
    control.Kind = kind
    control.Flag = flag
    control.Disabled = options.Disabled == true
    control._window = self
    control._validate = validate
    control._listeners = {}
    control._draw = draw
    function control:GetValue()
        return copyValue(self.Value)
    end
    function control:SetValue(value, silent)
        assert(not self._window._destroyed, "Window has been destroyed")
        local valid, normalized = self._validate(value)
        assert(valid, "Invalid " .. self.Kind .. " value for " .. tostring(self.Flag or options.Text))
        self.Value = copyValue(normalized)
        if self.Flag then
            self._window.Flags[self.Flag] = copyValue(normalized)
        end
        self._draw(self)
        if not silent then
            self._window:_callback(options.Callback, self:GetValue())
            for _, listener in ipairs(self._listeners) do
                self._window:_callback(listener, self:GetValue())
            end
        end
        return self
    end
    function control:SetDisabled(disabled)
        self.Disabled = disabled == true
        if self.Disabled and self._window._capturing == self then self._window:_cancelCapture() end
        self._draw(self)
        return self
    end
    function control:OnChanged(callback)
        assert(type(callback) == "function", "OnChanged expects a function")
        table.insert(self._listeners, callback)
        return self
    end
    control:SetValue(options.Default, true)
    control.Default = control:GetValue()
    table.insert(self._controls, control)
    if flag then
        self.Controls[flag] = control
    end
    return control
end

function Window:_closePopup()
    if self._popup then self._pointer = nil end
    if self._popupCleanup then
        self._popupCleanup()
        self._popupCleanup = nil
    end
    if self._popup then
        self._popup:Destroy()
        self._popup = nil
    end
    self.PopupLayer.Visible = false
end

function Window:_cancelCapture()
    if self._capturing then self._capturing._draw(self._capturing) end
    self._capturing = nil
end

function Window:_openPopup(anchor, width, height)
    self:_closePopup()
    self:_cancelCapture()
    local scale = self.Scale.Scale
    local origin = self.Root.AbsolutePosition
    local position = (anchor.AbsolutePosition - origin) / scale
    local anchorSize = anchor.AbsoluteSize / scale
    local x = math.clamp(position.X, 4, self.Width - width - 4)
    local y = position.Y + anchorSize.Y + 4
    if y + height > self.Height - 4 then
        y = math.max(4, position.Y - height - 4)
    end
    self.PopupLayer.Visible = true
    local popup = frame(self.PopupLayer, "Popup", UDim2.fromOffset(x, y), UDim2.fromOffset(width, height), self.Theme.Panel, self.Theme.Border)
    popup.ZIndex = 31
    self._popup = popup
    local edge = frame(popup, "Accent", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 1), self.Theme.Accent)
    edge.ZIndex = 32
    self:_accent(edge, "BackgroundColor3")
    return popup
end

function Window:_beginPointer(input, update)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    self._pointer = {Input = input, Update = update, Touch = input.UserInputType == Enum.UserInputType.Touch}
    update(Vector2.new(input.Position.X, input.Position.Y))
end

-- All UI coordinates use the full viewport. ScreenGui.IgnoreGuiInset is true.
function Window:_layout(center)
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    if viewport.X < 1 or viewport.Y < 1 then return end
    local insetTop, insetBottom = GuiService:GetGuiInset()
    local margin = 12
    local availableHeight = viewport.Y - insetTop.Y - insetBottom.Y - margin * 2
    local scale = math.max(0.1, math.min(self.RequestedScale, (viewport.X - margin * 2) / self.Width, availableHeight / self.Height))
    self.Scale.Scale = scale
    local size = Vector2.new(self.Width * scale, self.Height * scale)
    local x = self.Root.Position.X.Offset
    local y = self.Root.Position.Y.Offset
    if center then
        x = (viewport.X - size.X) / 2
        y = insetTop.Y + (viewport.Y - insetTop.Y - insetBottom.Y - size.Y) / 2
    end
    x = math.clamp(x, margin, math.max(margin, viewport.X - size.X - margin))
    y = math.clamp(y, insetTop.Y + margin, math.max(insetTop.Y + margin, viewport.Y - insetBottom.Y - size.Y - margin))
    self.Root.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
    self:_closePopup()
end

function Window:SetScale(value)
    assert(finite(value) and value >= 0.5 and value <= 2, "Scale must be between 0.5 and 2")
    self.RequestedScale = value
    self:_layout(true)
end

function Window:SetAccent(color)
    assert(typeof(color) == "Color3", "Accent must be a Color3")
    self.Theme.Accent = color
    for i = #self._accentBindings, 1, -1 do
        local binding = self._accentBindings[i]
        if binding[1].Parent then
            binding[1][binding[2]] = color
        else
            table.remove(self._accentBindings, i)
        end
    end
end

function Window:SetVisible(visible)
    self.Gui.Enabled = visible == true
    self:_closePopup()
    self._pointer = nil
    self:_cancelCapture()
end

function Window:SetToggleKey(key)
    assert(typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode and key ~= Enum.KeyCode.Unknown, "Toggle key must be a KeyCode")
    self.ToggleKey = key
end

function Window:OnDestroy(callback)
    assert(not self._destroyed and type(callback) == "function", "OnDestroy expects a function on a living window")
    table.insert(self._destroyCallbacks, callback)
    return self
end

function Window:SetPreviewVisible(visible)
    assert(self.Preview, "Enable Features.Preview when creating the window")
    self.Preview.Panel.Visible = visible == true
    self.Width = self.MainWidth + (visible and 360 or 0)
    self.Root.Size = UDim2.fromOffset(self.Width, self.Height)
    self:_layout(true)
end

function Window:SelectTab(name)
    local selected = type(name) == "table" and name or self.Tabs[name]
    assert(selected and self.Tabs[selected.Name] == selected, "Unknown tab: " .. tostring(name))
    self:_closePopup()
    self._pointer = nil
    self:_cancelCapture()
    self.ActiveTab = selected.Name
    self.Gui:SetAttribute("ActiveTab", selected.Name)
    for _, tab in ipairs(self._tabs) do
        local active = tab == selected
        tab.Page.Visible = active
        tab.Line.Visible = active
        tab.Glow.Visible = active
        tab.Seam.Visible = active
        tab.Caption.TextColor3 = active and self.Theme.Text or self.Theme.Muted
        tab.Button.BackgroundColor3 = active and self.Theme.Panel or self.Theme.Background
    end
end

function Window:ExportConfig()
    local values = {}
    for flag, control in pairs(self.Controls) do
        if control.Kind == "Color" then
            local v = control.Value
            values[flag] = {Color = {v.Color.R, v.Color.G, v.Color.B}, Transparency = v.Transparency}
        elseif control.Kind == "Keybind" then
            values[flag] = control.Value.Name
        else
            values[flag] = control:GetValue()
        end
    end
    return HttpService:JSONEncode({Version = 1, Values = values})
end

function Window:ImportConfig(json)
    local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
    if not ok or type(data) ~= "table" or data.Version ~= 1 or type(data.Values) ~= "table" then
        return false, "Expected a Serotonin configuration (version 1)."
    end
    -- Validate the complete document before changing any controls.
    local pending = {}
    for flag, value in pairs(data.Values) do
        local control = self.Controls[flag]
        if control then
            local decoded = value
            if control.Kind == "Color" then
                if type(value) ~= "table" or type(value.Color) ~= "table" then
                    return false, "Invalid color: " .. flag
                end
                local rgb = value.Color
                for i = 1, 3 do
                    if not finite(rgb[i]) or rgb[i] < 0 or rgb[i] > 1 then return false, "Invalid color: " .. flag end
                end
                decoded = {Color = Color3.new(rgb[1], rgb[2], rgb[3]), Transparency = value.Transparency}
            elseif control.Kind == "Keybind" then
                local found, key = pcall(function() return Enum.KeyCode[value] end)
                if not found then return false, "Invalid keybind: " .. flag end
                decoded = key
            end
            local valid, normalized = control._validate(decoded)
            if not valid then return false, "Invalid value: " .. flag end
            table.insert(pending, {control, normalized})
        end
    end
    for _, entry in ipairs(pending) do entry[1]:SetValue(entry[2], true) end
    -- Callbacks observe a fully applied configuration.
    for _, entry in ipairs(pending) do entry[1]:SetValue(entry[2]) end
    return true
end

function Window:ResetConfig()
    for _, control in ipairs(self._controls) do control:SetValue(control.Default, true) end
    for _, control in ipairs(self._controls) do control:SetValue(control.Default) end
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self:_closePopup()
    self._pointer = nil
    self:_cancelCapture()
    for _, controller in ipairs(table.clone(self._espControllers)) do controller:Destroy() end
    if self._noticeConnection then self._noticeConnection:Disconnect(); self._noticeConnection = nil end
    for _, notice in ipairs(self._notices) do
        notice.Closed = true
        if notice.Instance then notice.Instance:Destroy() end
    end
    table.clear(self._notices)
    if self.NotificationGui then self.NotificationGui:Destroy() end
    for _, callback in ipairs(self._destroyCallbacks) do self:_callback(callback) end
    table.clear(self._destroyCallbacks)
    for _, connection in ipairs(self._connections) do connection:Disconnect() end
    table.clear(self._connections)
    if self._cameraConnection then self._cameraConnection:Disconnect() end
    if self.Gui.Parent and not self._destroyingGui then self.Gui:Destroy() end
    table.clear(self._accentBindings)
end

local function drawMark(parent, color)
    local mark = frame(parent, "Mark", UDim2.fromOffset(6, 2), UDim2.fromOffset(16, 16), color)
    mark.BackgroundTransparency = 1
    -- Small symmetric circuit/brain emblem built only from native UI primitives.
    local segments = {
        {7, 0, 1, 14}, {4, 2, 1, 11}, {10, 2, 1, 11},
        {2, 4, 1, 7}, {12, 4, 1, 7}, {0, 6, 1, 3}, {14, 6, 1, 3},
        {5, 1, 2, 1}, {8, 1, 2, 1}, {2, 4, 3, 1}, {10, 4, 3, 1},
        {1, 7, 3, 1}, {11, 7, 3, 1}, {4, 6, 3, 1}, {8, 6, 3, 1},
        {2, 10, 3, 1}, {10, 10, 3, 1}, {4, 12, 3, 1}, {8, 12, 3, 1},
        {5, 14, 2, 1}, {8, 14, 2, 1},
    }
    for _, rect in ipairs(segments) do
        frame(mark, "Pixel", UDim2.fromOffset(rect[1], rect[2]), UDim2.fromOffset(rect[3], rect[4]), color)
    end
    return mark
end

function Serotonin.new(options)
    options = options or {}
    local player = Players.LocalPlayer
    assert(player, "Serotonin must be created in a Roblox client")
    local self = setmetatable({}, Window)
    local features = options.Features or {}
    assert(type(features) == "table", "Features must be a table")
    for name, enabled in pairs(features) do
        assert((name == "Preview" or name == "ESP" or name == "Notifications") and type(enabled) == "boolean", "Unknown feature or non-boolean feature: " .. tostring(name))
    end
    self.Features = table.freeze({
        Preview = features.Preview == true or (features.Preview == nil and options.Preview == true),
        ESP = features.ESP == true,
        Notifications = features.Notifications ~= false,
    })
    self.NotificationOptions = table.clone(options.Notifications or {})
    local n = self.NotificationOptions
    n.Duration = n.Duration or 5
    n.MaxVisible = n.MaxVisible or 3
    n.Width = n.Width or 310
    n.Position = n.Position or "BottomRight"
    assert(finite(n.Duration) and n.Duration >= 0, "Notification Duration must be nonnegative")
    assert(finite(n.MaxVisible) and n.MaxVisible % 1 == 0 and n.MaxVisible >= 1 and n.MaxVisible <= 5, "MaxVisible must be an integer from 1 to 5")
    assert(finite(n.Width) and n.Width >= 220 and n.Width <= 480, "Notification Width must be 220..480")
    assert(n.Position == "BottomRight" or n.Position == "TopRight", "Notification Position must be BottomRight or TopRight")
    self.Theme = table.clone(PALETTE)
    for key, value in pairs(options.Theme or {}) do
        assert(self.Theme[key] and typeof(value) == "Color3", "Invalid theme color: " .. tostring(key))
        self.Theme[key] = value
    end
    self.Height = options.Height or 538
    self.MainWidth = options.Width or 616
    assert(finite(self.Height) and self.Height >= 300, "Height must be at least 300")
    assert(finite(self.MainWidth) and self.MainWidth >= 440, "Width must be at least 440")
    self.HasPreview = self.Features.Preview
    self.Width = self.MainWidth + (self.HasPreview and 360 or 0)
    self.RequestedScale = options.Scale or 1
    assert(finite(self.RequestedScale) and self.RequestedScale >= 0.5 and self.RequestedScale <= 2, "Scale must be between 0.5 and 2")
    self.ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift
    self._connections = {}
    self._accentBindings = {}
    self._tabs = {}
    self._controls = {}
    self._espControllers = {}
    self._destroyCallbacks = {}
    self._notices = {}
    self.Flags = {}
    self.Controls = {}
    self.Tabs = {}
    self.Gui = create("ScreenGui", {
        Name = options.Name or "SerotoninUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = options.DisplayOrder or 50,
    }, options.Parent or player:WaitForChild("PlayerGui"))
    self.Root = frame(self.Gui, "Root", UDim2.fromOffset(0, 0), UDim2.fromOffset(self.Width, self.Height), self.Theme.Background)
    self.Root.BackgroundTransparency = 1
    self.Scale = create("UIScale", {Scale = 1}, self.Root)
    self.Main = frame(self.Root, "Main", UDim2.fromOffset(0, 0), UDim2.fromOffset(self.MainWidth, self.Height), self.Theme.Background, self.Theme.Border)
    self.Main.BorderMode = Enum.BorderMode.Outline
    self.Main.Active = true
    local edge = frame(self.Main, "AccentEdge", UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0), self.Theme.Accent)
    self:_accent(edge, "BackgroundColor3")
    local titlebar = button(self.Main, "DragHandle", UDim2.fromOffset(0, 0), UDim2.new(1, -1, 0, 24))
    titlebar.Active = true
    label(titlebar, "Title", options.Title or "serotonin - roblox", UDim2.fromOffset(29, 0), UDim2.new(1, -40, 1, -3), self.Theme.Text)
    for _, pixel in ipairs(drawMark(titlebar, self.Theme.Accent):GetChildren()) do self:_accent(pixel, "BackgroundColor3") end
    self.TabBar = frame(self.Main, "Tabs", UDim2.fromOffset(6, 24), UDim2.new(1, -16, 0, 32), self.Theme.Background)
    create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder}, self.TabBar)
    self.Body = frame(self.Main, "Body", UDim2.fromOffset(6, 55), UDim2.new(1, -16, 1, -66), self.Theme.Panel, self.Theme.Border)

    self.PopupLayer = frame(self.Root, "Popups", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), self.Theme.Background)
    self.PopupLayer.BackgroundTransparency = 1
    self.PopupLayer.Visible = false
    self.PopupLayer.ZIndex = 30
    local dismiss = button(self.PopupLayer, "Dismiss", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1))
    dismiss.ZIndex = 30
    self:_connect(dismiss.Activated, function() self:_closePopup() end)

    local function attachDrag(handle)
        self:_connect(handle.InputBegan, function(input)
            local start = Vector2.new(input.Position.X, input.Position.Y)
            local origin = Vector2.new(self.Root.Position.X.Offset, self.Root.Position.Y.Offset)
            self:_closePopup()
            self:_beginPointer(input, function(position)
                local delta = position - start
                self.Root.Position = UDim2.fromOffset(origin.X + delta.X, origin.Y + delta.Y)
                -- Clamp without cancelling the drag.
                local camera = workspace.CurrentCamera
                if camera then
                    local view = camera.ViewportSize
                    local top, bottom = GuiService:GetGuiInset()
                    local x = math.clamp(self.Root.Position.X.Offset, 0, math.max(0, view.X - self.Width * self.Scale.Scale))
                    local y = math.clamp(self.Root.Position.Y.Offset, top.Y, math.max(top.Y, view.Y - bottom.Y - self.Height * self.Scale.Scale))
                    self.Root.Position = UDim2.fromOffset(math.round(x), math.round(y))
                end
            end)
        end)
    end
    attachDrag(titlebar)
    if self.HasPreview then self:_createPreview(options.PreviewTitle or "ESP Preview", attachDrag) end

    self:_connect(UserInputService.InputChanged, function(input)
        local pointer = self._pointer
        if not pointer then return end
        if (pointer.Touch and input == pointer.Input) or (not pointer.Touch and input.UserInputType == Enum.UserInputType.MouseMovement) then
            pointer.Update(Vector2.new(input.Position.X, input.Position.Y))
        end
    end)
    self:_connect(UserInputService.InputEnded, function(input)
        local pointer = self._pointer
        if pointer and (input == pointer.Input or (not pointer.Touch and input.UserInputType == Enum.UserInputType.MouseButton1)) then
            self._pointer = nil
        end
    end)
    self:_connect(UserInputService.WindowFocusReleased, function() self._pointer = nil end)
    self:_connect(UserInputService.InputBegan, function(input, processed)
        if self._popup and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            local p, s = self._popup.AbsolutePosition, self._popup.AbsoluteSize
            local point = input.Position
            if point.X < p.X or point.X > p.X + s.X or point.Y < p.Y or point.Y > p.Y + s.Y then self:_closePopup() end
        end
        if UserInputService:GetFocusedTextBox() then return end
        if self._capturing then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local control = self._capturing
                self._capturing = nil
                if input.KeyCode ~= Enum.KeyCode.Escape then control:SetValue(input.KeyCode) else control._draw(control) end
            end
            return
        end
        if processed then return end
        if input.KeyCode == self.ToggleKey then
            self:SetVisible(not self.Gui.Enabled)
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape and self._popup then self:_closePopup() end
        for _, control in ipairs(self._controls) do
            if control.Kind == "Keybind" and not control.Disabled and input.KeyCode == control.Value then
                self:_callback(control._pressed)
            end
        end
    end)
    local function bindCamera()
        if self._cameraConnection then self._cameraConnection:Disconnect() end
        local camera = workspace.CurrentCamera
        if camera then
            self._cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:_layout(false) end)
        end
        self:_layout(true)
    end
    self:_connect(workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera)
    self:_connect(self.Gui.Destroying, function()
        self._destroyingGui = true
        self:Destroy()
    end)
    bindCamera()
    return self
end

function Window:AddTab(name)
    assert(type(name) == "string" and name ~= "" and not self.Tabs[name], "Tab names must be unique nonempty strings")
    local tab = setmetatable({Name = name, Window = self, Sections = {}}, Tab)
    tab.Button = button(self.TabBar, slug(name), UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1))
    tab.Button.BackgroundTransparency = 0
    tab.Button.BackgroundColor3 = self.Theme.Background
    tab.Button.BorderSizePixel = 1
    tab.Button.BorderColor3 = self.Theme.Border
    tab.Button.BorderMode = Enum.BorderMode.Inset
    tab.Button.LayoutOrder = #self._tabs + 1
    tab.Caption = label(tab.Button, "Caption", name, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), self.Theme.Muted)
    tab.Caption.TextXAlignment = Enum.TextXAlignment.Center
    tab.Line = frame(tab.Button, "ActiveLine", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 1), self.Theme.Accent)
    self:_accent(tab.Line, "BackgroundColor3")
    tab.Glow = frame(tab.Button, "Glow", UDim2.fromOffset(0, 1), UDim2.new(1, 0, 0, 10), self.Theme.Accent)
    self:_accent(tab.Glow, "BackgroundColor3")
    local glow = gradient(tab.Glow, Color3.new(1, 1, 1), Color3.new(1, 1, 1))
    glow.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.88), NumberSequenceKeypoint.new(1, 1)})
    tab.Seam = frame(tab.Button, "Seam", UDim2.new(0, 1, 1, -1), UDim2.new(1, -2, 0, 1), self.Theme.Panel)
    tab.Button.ZIndex = 3
    tab.Page = frame(self.Body, slug(name), UDim2.fromOffset(9, 10), UDim2.new(1, -16, 1, -20), self.Theme.Panel)
    tab.Page.BackgroundTransparency = 1
    tab.Columns = {}
    for i, side in ipairs({"Left", "Right"}) do
        local column = frame(tab.Page, side, UDim2.new((i - 1) * 0.5, (i - 1) * 4, 0, 0), UDim2.new(0.5, -5, 1, 0), self.Theme.Panel)
        column.BackgroundTransparency = 1
        create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, column)
        tab.Columns[side] = column
    end
    self.Tabs[name] = tab
    table.insert(self._tabs, tab)
    for _, existing in ipairs(self._tabs) do existing.Button.Size = UDim2.new(1 / #self._tabs, 0, 1, 0) end
    self:_connect(tab.Button.Activated, function() self:SelectTab(name) end)
    self:_connect(tab.Button.MouseEnter, function()
        if self.ActiveTab ~= name then tab.Caption.TextColor3 = self.Theme.Text end
    end)
    self:_connect(tab.Button.MouseLeave, function()
        if self.ActiveTab ~= name then tab.Caption.TextColor3 = self.Theme.Muted end
    end)
    self:SelectTab(self.ActiveTab or name)
    return tab
end

function Tab:AddSection(options)
    if type(options) == "string" then options = {Title = options} end
    options = options or {}
    local w = self.Window
    local side = options.Side or "Left"
    assert(self.Columns[side], "Section Side must be Left or Right")
    local section = setmetatable({Window = w, Tab = self, _order = 0}, Section)
    section.Frame = frame(self.Columns[side], slug(options.Title or "Section"), UDim2.fromOffset(0, 0), options.Height and UDim2.new(1, 0, 0, options.Height) or UDim2.fromScale(1, 1), w.Theme.Panel, w.Theme.Border)
    section.Frame.LayoutOrder = #self.Sections + 1
    local header = frame(section.Frame, "Header", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 24), w.Theme.Header)
    gradient(header, Color3.fromRGB(20, 26, 31), w.Theme.Header)
    frame(header, "Divider", UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1), w.Theme.Border)
    local accent = frame(header, "Accent", UDim2.fromOffset(0, 0), UDim2.new(0, 1, 1, 0), w.Theme.Accent)
    w:_accent(accent, "BackgroundColor3")
    label(header, "Title", options.Title or "Section", UDim2.fromOffset(10, 0), UDim2.new(1, -20, 1, 0), w.Theme.Text)
    section.Content = create("ScrollingFrame", {
        Name = "Controls",
        Position = UDim2.fromOffset(10, 24),
        Size = UDim2.new(1, -21, 1, -24),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        ScrollBarImageColor3 = w.Theme.Border,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        VerticalScrollBarInset = Enum.ScrollBarInset.None,
        ClipsDescendants = true,
        ElasticBehavior = Enum.ElasticBehavior.Never,
    }, section.Frame)
    create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, section.Content)
    -- A scrollbar in the outer padding avoids Roblox reserving (and clipping)
    -- the final pixels of right-aligned values inside the ScrollingFrame.
    local thumb = frame(section.Frame, "ScrollThumb", UDim2.new(1, -4, 0, 25), UDim2.fromOffset(2, 30), w.Theme.Border)
    thumb.Visible = false
    local hovering = false
    local function updateThumb()
        local visible = section.Content.AbsoluteWindowSize.Y
        local canvas = section.Content.AbsoluteCanvasSize.Y
        local scale = w.Scale.Scale
        thumb.Visible = hovering and canvas > visible + 1
        if canvas > visible and visible > 0 then
            local height = math.max(16, visible * visible / canvas / scale)
            local track = visible / scale - height
            thumb.Size = UDim2.fromOffset(2, height)
            thumb.Position = UDim2.new(1, -4, 0, 24 + track * section.Content.CanvasPosition.Y / (canvas - visible))
        end
    end
    w:_connect(section.Frame.MouseEnter, function() hovering = true; updateThumb() end)
    w:_connect(section.Frame.MouseLeave, function() hovering = false; updateThumb() end)
    w:_connect(section.Content:GetPropertyChangedSignal("AbsoluteCanvasSize"), updateThumb)
    w:_connect(section.Content:GetPropertyChangedSignal("AbsoluteWindowSize"), updateThumb)
    w:_connect(section.Content:GetPropertyChangedSignal("CanvasPosition"), function() w:_closePopup(); updateThumb() end)
    table.insert(self.Sections, section)
    return section
end

function Section:_row(text, height)
    self._order += 1
    local row = frame(self.Content, slug(text or "Row") .. "Row", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, height), self.Window.Theme.Panel)
    row.BackgroundTransparency = 1
    row.LayoutOrder = self._order
    return row
end

function Section:AddLabel(text, options)
    options = options or {}
    local row = self:_row(text, options.Height or 23)
    local caption = label(row, "Caption", text, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), options.Muted and self.Window.Theme.Muted or self.Window.Theme.Text, options.TextSize)
    caption.TextWrapped = options.Wrapped == true
    caption.TextTruncate = Enum.TextTruncate.None
    return caption
end

function Section:AddSpacer(height)
    return self:_row("Spacer", height or 8)
end

function Section:AddToggle(options)
    options = table.clone(options)
    if options.Default == nil then options.Default = false end
    local w = self.Window
    local row = self:_row(options.Text, 23)
    local hit = button(row, "Toggle", UDim2.fromOffset(0, 0), UDim2.new(1, options.Color and -24 or 0, 0, 19))
    local box = frame(hit, "Box", UDim2.fromOffset(0, 1), UDim2.fromOffset(13, 13), w.Theme.Field, w.Theme.Border)
    local fill = frame(box, "Fill", UDim2.fromOffset(1, 1), UDim2.new(1, -2, 1, -2), w.Theme.Accent)
    w:_accent(fill, "BackgroundColor3")
    local caption = label(hit, "Caption", options.Text, UDim2.fromOffset(17, -1), UDim2.new(1, -17, 0, 17), w.Theme.Text)
    local control = w:_register({Instance = row, Button = hit}, options, "Toggle", function(value)
        return type(value) == "boolean", value
    end, function(c)
        fill.Visible = c.Value
        fill.BackgroundTransparency = c.Disabled and 0.6 or 0
        caption.TextColor3 = c.Value and not c.Disabled and w.Theme.Text or w.Theme.Muted
        row:SetAttribute("Value", c.Value)
        row:SetAttribute("Disabled", c.Disabled)
    end)
    w:_connect(hit.Activated, function() if not control.Disabled then control:SetValue(not control.Value) end end)
    w:_connect(hit.MouseEnter, function() if not control.Disabled then box.BorderColor3 = w.Theme.Accent end end)
    w:_connect(hit.MouseLeave, function() box.BorderColor3 = w.Theme.Border end)
    if options.Color then
        control.Color = self:_color(row, {
            Text = options.Text .. " color", Flag = options.ColorFlag or (options.Flag and options.Flag .. "Color"),
            Default = {Color = options.Color, Transparency = options.Transparency or 0}, Callback = options.ColorCallback,
        })
    end
    return control
end

function Section:AddSlider(options)
    options = table.clone(options)
    local w = self.Window
    local min, max, step = options.Min or 0, options.Max or 100, options.Step or 1
    assert(finite(min) and finite(max) and finite(step) and max > min and step > 0, "Slider needs finite Min < Max and Step > 0")
    options.Default = options.Default or min
    local decimals = options.Decimals
    if decimals == nil then decimals = math.clamp(math.ceil(-math.log10(step)), 0, 6) end
    assert(finite(decimals) and decimals % 1 == 0 and decimals >= 0 and decimals <= 6, "Decimals must be an integer from 0 to 6")
    local numberFormat = "%." .. string.format("%d", decimals) .. "f"
    local row = self:_row(options.Text, 41)
    local caption = label(row, "Caption", options.Text, UDim2.fromOffset(0, 0), UDim2.new(1, -60, 0, 17), w.Theme.Muted)
    local valueText = create("TextBox", {
        Name = "Value", Position = UDim2.new(1, -64, 0, 0), Size = UDim2.fromOffset(64, 17),
        BackgroundTransparency = 1, BorderSizePixel = 0, ClearTextOnFocus = false,
        Font = Enum.Font.Arial, TextSize = 13, TextColor3 = w.Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right, Text = "",
    }, row)
    local track = frame(row, "Track", UDim2.fromOffset(0, 19), UDim2.new(1, 0, 0, 14), w.Theme.Field, w.Theme.Border)
    local fill = frame(track, "Fill", UDim2.fromOffset(1, 1), UDim2.new(0, 0, 1, -2), w.Theme.Accent)
    w:_accent(fill, "BackgroundColor3")
    local hit = button(row, "Slider", UDim2.fromOffset(0, 16), UDim2.new(1, 0, 0, 21))
    local control = w:_register({Instance = row}, options, "Slider", function(value)
        if not finite(value) then return false end
        local rounded = min + math.round((math.clamp(value, min, max) - min) / step) * step
        return true, math.clamp(rounded, min, max)
    end, function(c)
        local fraction = (c.Value - min) / (max - min)
        fill.Size = UDim2.new(fraction, -2 * fraction, 1, -2)
        valueText.Text = string.format(numberFormat, c.Value) .. (options.Suffix or "")
        valueText.TextEditable = not c.Disabled
        fill.BackgroundTransparency = c.Disabled and 0.65 or 0
        caption.TextTransparency = c.Disabled and 0.4 or 0
        row:SetAttribute("Value", c.Value)
    end)
    w:_connect(hit.InputBegan, function(input)
        if control.Disabled then return end
        local startX, width = track.AbsolutePosition.X, math.max(1, track.AbsoluteSize.X)
        w:_beginPointer(input, function(position)
            if control.Disabled then return end
            local fraction = math.clamp((position.X - startX) / width, 0, 1)
            control:SetValue(min + fraction * (max - min))
        end)
    end)
    w:_connect(valueText.Focused, function()
        valueText.Text = string.format(numberFormat, control.Value)
    end)
    w:_connect(valueText.FocusLost, function()
        local value = tonumber(valueText.Text)
        if finite(value) and not control.Disabled then control:SetValue(value) else control._draw(control) end
    end)
    return control
end

function Section:AddDropdown(options)
    options = table.clone(options)
    local items = table.clone(options.Options or {})
    assert(#items > 0, "Dropdown needs at least one option")
    local seen = {}
    for _, item in ipairs(items) do
        assert(type(item) == "string" and not seen[item], "Dropdown options must be unique strings")
        seen[item] = true
    end
    options.Default = options.Default or items[1]
    local w = self.Window
    local row = self:_row(options.Text, 45)
    local caption = label(row, "Caption", options.Text, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 17), w.Theme.Muted)
    local field = frame(row, "Field", UDim2.fromOffset(0, 19), UDim2.new(1, 0, 0, 18), w.Theme.Field, w.Theme.Border)
    local valueLabel = label(field, "Value", "", UDim2.fromOffset(3, -1), UDim2.new(1, -6, 1, 2), w.Theme.Text)
    local hit = button(field, "Open", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1))
    local control = w:_register({Instance = row}, options, "Dropdown", function(value)
        return type(value) == "string" and table.find(items, value) ~= nil, value
    end, function(c)
        valueLabel.Text = c.Value
        valueLabel.TextColor3 = c.Disabled and w.Theme.Muted or w.Theme.Text
        caption.TextTransparency = c.Disabled and 0.4 or 0
        row:SetAttribute("Value", c.Value)
    end)
    w:_connect(hit.Activated, function()
        if control.Disabled then return end
        local width = field.AbsoluteSize.X / w.Scale.Scale
        local popup = w:_openPopup(field, width, math.min(#items, 7) * 23 + 8)
        local list = create("ScrollingFrame", {
            Name = "Options", Position = UDim2.fromOffset(3, 4), Size = UDim2.new(1, -6, 1, -8),
            BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, #items * 23),
            ScrollBarThickness = 2, ScrollBarImageColor3 = w.Theme.Accent, ZIndex = 32,
        }, popup)
        for i, item in ipairs(items) do
            local choice = button(list, slug(item), UDim2.fromOffset(0, (i - 1) * 23), UDim2.new(1, 0, 0, 23))
            choice.ZIndex = 33
            choice.BackgroundColor3 = w.Theme.Field
            choice.BackgroundTransparency = item == control.Value and 0 or 1
            local text = label(choice, "Caption", item, UDim2.fromOffset(6, 0), UDim2.new(1, -12, 1, 0), item == control.Value and w.Theme.Accent or w.Theme.Text)
            text.ZIndex = 34
            -- Popup-local connections die with their instances.
            choice.MouseEnter:Connect(function() choice.BackgroundTransparency = 0 end)
            choice.MouseLeave:Connect(function() choice.BackgroundTransparency = item == control.Value and 0 or 1 end)
            choice.Activated:Connect(function()
                if not control.Disabled then control:SetValue(item) end
                w:_closePopup()
            end)
        end
    end)
    return control
end

local function checker(parent)
    for y = 0, 3 do
        for x = 0, 3 do
            local cell = frame(parent, "Check", UDim2.fromScale(x / 4, y / 4), UDim2.fromScale(0.25, 0.25), (x + y) % 2 == 0 and Color3.fromRGB(207, 216, 216) or Color3.fromRGB(92, 112, 113))
            cell.ZIndex = parent.ZIndex
        end
    end
end

function Section:_color(row, options)
    local w = self.Window
    local swatch = frame(row, "Swatch", UDim2.new(1, -13, 0, 1), UDim2.fromOffset(13, 13), w.Theme.Field, w.Theme.Border)
    checker(swatch)
    local tint = frame(swatch, "Tint", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), Color3.new(1, 1, 1))
    tint.ZIndex = 2
    gradient(tint, Color3.new(1, 1, 1), Color3.fromRGB(187, 224, 224))
    local hit = button(swatch, "Open", UDim2.fromOffset(-4, -4), UDim2.new(1, 8, 1, 8))
    hit.ZIndex = 3
    local control = w:_register({Instance = swatch}, options, "Color", function(value)
        if typeof(value) == "Color3" then value = {Color = value, Transparency = 0} end
        if type(value) ~= "table" or typeof(value.Color) ~= "Color3" or not finite(value.Transparency) or value.Transparency < 0 or value.Transparency > 1 then return false end
        local color = value.Color
        if not finite(color.R) or not finite(color.G) or not finite(color.B) or color.R < 0 or color.R > 1 or color.G < 0 or color.G > 1 or color.B < 0 or color.B > 1 then return false end
        return true, {Color = color, Transparency = value.Transparency}
    end, function(c)
        tint.BackgroundColor3 = c.Value.Color
        tint.BackgroundTransparency = c.Value.Transparency
        swatch:SetAttribute("Color", c.Value.Color)
        swatch:SetAttribute("Transparency", c.Value.Transparency)
    end)
    w:_connect(hit.Activated, function()
        if control.Disabled then return end
        local popup = w:_openPopup(swatch, 224, 247)
        local caption = label(popup, "Title", options.Text, UDim2.fromOffset(10, 5), UDim2.new(1, -20, 0, 20), w.Theme.Text)
        caption.ZIndex = 33
        local h, s, v = control.Value.Color:ToHSV()
        local a = control.Value.Transparency
        local sv = frame(popup, "SaturationValue", UDim2.fromOffset(10, 31), UDim2.fromOffset(180, 145), Color3.fromHSV(h, 1, 1))
        sv.ZIndex = 33
        local white = frame(sv, "White", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), Color3.new(1, 1, 1))
        white.ZIndex = 34
        local whiteGradient = gradient(white, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 0)
        whiteGradient.Transparency = NumberSequence.new(0, 1)
        local black = frame(sv, "Black", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), Color3.new(0, 0, 0))
        black.ZIndex = 35
        local blackGradient = gradient(black, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 90)
        blackGradient.Transparency = NumberSequence.new(1, 0)
        local cursor = frame(sv, "Cursor", UDim2.fromScale(s, 1 - v), UDim2.fromOffset(5, 5), Color3.new(1, 1, 1), Color3.new(0, 0, 0))
        cursor.AnchorPoint = Vector2.new(0.5, 0.5)
        cursor.ZIndex = 37
        local svHit = button(sv, "Drag", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1))
        svHit.ZIndex = 36
        local hue = frame(popup, "Hue", UDim2.fromOffset(199, 31), UDim2.fromOffset(14, 145), Color3.new(1, 1, 1))
        hue.ZIndex = 33
        local keys = {}
        for i = 0, 6 do table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))) end
        create("UIGradient", {Color = ColorSequence.new(keys), Rotation = 90}, hue)
        local hueCursor = frame(hue, "Cursor", UDim2.fromScale(0, h), UDim2.new(1, 0, 0, 2), Color3.new(1, 1, 1))
        hueCursor.ZIndex = 35
        local hueHit = button(hue, "Drag", UDim2.fromOffset(-3, 0), UDim2.new(1, 6, 1, 0))
        hueHit.ZIndex = 34
        local alpha = frame(popup, "Opacity", UDim2.fromOffset(10, 186), UDim2.fromOffset(203, 12), Color3.fromRGB(130, 140, 145))
        alpha.ZIndex = 33
        checker(alpha)
        local alphaColor = frame(alpha, "Color", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), control.Value.Color)
        alphaColor.ZIndex = 34
        local ag = gradient(alphaColor, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 0)
        ag.Transparency = NumberSequence.new(0, 1)
        local alphaCursor = frame(alpha, "Cursor", UDim2.fromScale(a, 0), UDim2.new(0, 2, 1, 0), Color3.new(1, 1, 1))
        alphaCursor.ZIndex = 36
        local alphaHit = button(alpha, "Drag", UDim2.fromOffset(0, -3), UDim2.new(1, 0, 1, 6))
        alphaHit.ZIndex = 35
        local hex = create("TextBox", {
            Name = "Hex", Position = UDim2.fromOffset(10, 211), Size = UDim2.fromOffset(113, 24),
            BackgroundColor3 = w.Theme.Field, BorderColor3 = w.Theme.Border, BorderSizePixel = 1,
            Font = Enum.Font.Code, TextSize = 12, TextColor3 = w.Theme.Text, ClearTextOnFocus = false, ZIndex = 33,
        }, popup)
        local opacity = label(popup, "OpacityValue", "", UDim2.fromOffset(131, 211), UDim2.fromOffset(82, 24), w.Theme.Muted)
        opacity.TextXAlignment = Enum.TextXAlignment.Right
        opacity.ZIndex = 33
        local function refresh(commit)
            local color = Color3.fromHSV(h, s, v)
            sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            cursor.Position = UDim2.fromScale(s, 1 - v)
            hueCursor.Position = UDim2.new(0, 0, h, -h * 2)
            alphaCursor.Position = UDim2.new(a, -a * 2, 0, 0)
            alphaColor.BackgroundColor3 = color
            hex.Text = "#" .. color:ToHex():upper()
            opacity.Text = math.round((1 - a) * 100) .. "% opacity"
            if commit then control:SetValue({Color = color, Transparency = a}) end
        end
        local function relative(position, target)
            return (position - target.AbsolutePosition) / target.AbsoluteSize
        end
        svHit.InputBegan:Connect(function(input)
            w:_beginPointer(input, function(position)
                local point = relative(position, sv)
                s, v = math.clamp(point.X, 0, 1), 1 - math.clamp(point.Y, 0, 1)
                refresh(true)
            end)
        end)
        hueHit.InputBegan:Connect(function(input)
            w:_beginPointer(input, function(position) h = math.clamp(relative(position, hue).Y, 0, 1); refresh(true) end)
        end)
        alphaHit.InputBegan:Connect(function(input)
            w:_beginPointer(input, function(position) a = math.clamp(relative(position, alpha).X, 0, 1); refresh(true) end)
        end)
        hex.FocusLost:Connect(function()
            local value = hex.Text:gsub("#", "")
            if #value == 6 and value:match("^%x+$") then h, s, v = Color3.fromHex(value):ToHSV(); refresh(true) else refresh(false) end
        end)
        refresh(false)
    end)
    return control
end

function Section:AddColorPicker(options)
    options = table.clone(options)
    if typeof(options.Default) == "Color3" then options.Default = {Color = options.Default, Transparency = 0} end
    options.Default = options.Default or {Color = Color3.new(1, 1, 1), Transparency = 0}
    local row = self:_row(options.Text, 23)
    label(row, "Caption", options.Text, UDim2.fromOffset(0, -1), UDim2.new(1, -24, 0, 17), self.Window.Theme.Text)
    return self:_color(row, options)
end

function Section:AddButton(options)
    local w = self.Window
    local row = self:_row(options.Text, 31)
    local hit = button(row, "Button", UDim2.fromOffset(0, 3), UDim2.new(1, 0, 0, 23))
    hit.BackgroundTransparency = 0
    hit.BackgroundColor3 = w.Theme.Field
    hit.BorderSizePixel = 1
    hit.BorderColor3 = w.Theme.Border
    local caption = label(hit, "Caption", options.Text, UDim2.fromOffset(6, 0), UDim2.new(1, -12, 1, 0), w.Theme.Text)
    caption.TextXAlignment = Enum.TextXAlignment.Center
    local control = {Instance = row, Disabled = options.Disabled == true}
    function control:SetDisabled(value)
        self.Disabled = value == true
        caption.TextColor3 = self.Disabled and w.Theme.Muted or w.Theme.Text
    end
    control:SetDisabled(control.Disabled)
    w:_connect(hit.Activated, function() if not control.Disabled then w:_callback(options.Callback) end end)
    w:_connect(hit.MouseEnter, function() if not control.Disabled then hit.BorderColor3 = w.Theme.Accent end end)
    w:_connect(hit.MouseLeave, function() hit.BorderColor3 = w.Theme.Border end)
    return control
end

function Section:AddTextbox(options)
    options = table.clone(options)
    options.Default = options.Default or ""
    local w = self.Window
    local height = options.Height or 23
    local row = self:_row(options.Text, height + 27)
    label(row, "Caption", options.Text, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 17), w.Theme.Muted)
    local field = create("TextBox", {
        Name = "Input", Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = w.Theme.Field, BorderColor3 = w.Theme.Border, BorderSizePixel = 1,
        Font = options.Multiline and Enum.Font.Code or Enum.Font.Arial, TextSize = 12,
        TextColor3 = w.Theme.Text, PlaceholderColor3 = w.Theme.Muted, PlaceholderText = options.Placeholder or "",
        ClearTextOnFocus = false, MultiLine = options.Multiline == true, TextWrapped = options.Multiline == true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = options.Multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
    }, row)
    create("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingTop = UDim.new(0, options.Multiline and 5 or 0)}, field)
    local control = w:_register({Instance = row, TextBox = field}, options, "Textbox", function(value)
        return type(value) == "string" and #value <= (options.MaxLength or 65536), value
    end, function(c)
        field.Text = c.Value
        field.TextEditable = not c.Disabled
        field.TextColor3 = c.Disabled and w.Theme.Muted or w.Theme.Text
    end)
    w:_connect(field.FocusLost, function()
        local valid = control._validate(field.Text)
        if valid and not control.Disabled then control:SetValue(field.Text) else control._draw(control) end
    end)
    return control
end

function Section:AddKeybind(options)
    options = table.clone(options)
    options.Default = options.Default or Enum.KeyCode.RightShift
    local w = self.Window
    local row = self:_row(options.Text, 28)
    label(row, "Caption", options.Text, UDim2.fromOffset(0, 0), UDim2.new(1, -100, 0, 20), w.Theme.Text)
    local hit = button(row, "Bind", UDim2.new(1, -91, 0, 1), UDim2.fromOffset(91, 20))
    hit.BackgroundTransparency = 0
    hit.BackgroundColor3 = w.Theme.Field
    hit.BorderSizePixel = 1
    hit.BorderColor3 = w.Theme.Border
    local text = label(hit, "Key", "", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), w.Theme.Text)
    text.TextXAlignment = Enum.TextXAlignment.Center
    local control = w:_register({Instance = row, _pressed = options.OnPressed}, options, "Keybind", function(value)
        return typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode and value ~= Enum.KeyCode.Unknown, value
    end, function(c)
        text.Text = c.Value.Name
        text.TextColor3 = c.Disabled and w.Theme.Muted or w.Theme.Text
    end)
    w:_connect(hit.Activated, function()
        if control.Disabled then return end
        if w._capturing then w._capturing._draw(w._capturing) end
        w._capturing = control
        text.Text = "Press a key..."
        text.TextColor3 = w.Theme.Accent
    end)
    return control
end

function Window:_createPreview(title, attachDrag)
    local panel = frame(self.Root, "Preview", UDim2.fromOffset(self.MainWidth + 10, 0), UDim2.fromOffset(350, self.Height), self.Theme.Background, self.Theme.Accent)
    panel.Active = true
    self:_accent(panel, "BorderColor3")
    local titlebar = button(panel, "DragHandle", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 24))
    label(titlebar, "Title", title, UDim2.fromOffset(32, 0), UDim2.new(1, -40, 1, -3), self.Theme.Text)
    for _, pixel in ipairs(drawMark(titlebar, self.Theme.Accent):GetChildren()) do self:_accent(pixel, "BackgroundColor3") end
    attachDrag(titlebar)
    local canvas = frame(panel, "Canvas", UDim2.fromOffset(9, 23), UDim2.new(1, -18, 1, -32), self.Theme.Background, self.Theme.Border)
    -- A private, isolated WorldModel. The preview never touches gameplay characters.
    local target = frame(canvas, "Target", UDim2.new(0.5, -61, 0.5, -51), UDim2.fromOffset(122, 170), self.Theme.Accent)
    target.BackgroundTransparency = 1
    local viewport = create("ViewportFrame", {
        Name = "Avatar", Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 1, -4),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Ambient = Color3.fromRGB(175, 184, 189), LightColor = Color3.fromRGB(182, 199, 206),
        LightDirection = Vector3.new(-1, -1, -2), ImageColor3 = Color3.fromRGB(155, 190, 187),
    }, target)
    local world = create("WorldModel", {Name = "PreviewWorld"}, viewport)
    local camera = create("Camera", {Name = "Camera", FieldOfView = 32}, viewport)
    viewport.CurrentCamera = camera
    local tint = frame(target, "BoxFill", UDim2.fromOffset(1, 1), UDim2.new(1, -2, 1, -2), Color3.fromRGB(11, 164, 157))
    tint.BackgroundTransparency = 0.83
    tint.ZIndex = 3
    local outline = frame(target, "Box", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), Color3.new(0, 0, 0), Color3.fromRGB(116, 236, 241))
    outline.BackgroundTransparency = 1
    outline.BorderSizePixel = 0
    create("UIStroke", {Name = "Outline", Color = Color3.fromRGB(116, 236, 241), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter}, outline)
    outline.ZIndex = 4
    local inner = frame(outline, "Inner", UDim2.fromOffset(1, 1), UDim2.new(1, -2, 1, -2), Color3.new(0, 0, 0), Color3.fromRGB(10, 54, 57))
    inner.BackgroundTransparency = 1
    inner.BorderSizePixel = 0
    create("UIStroke", {Name = "Outline", Color = Color3.fromRGB(10, 54, 57), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter}, inner)
    inner.ZIndex = 4
    local name = label(target, "NameLabel", "Name", UDim2.fromOffset(-20, -21), UDim2.new(1, 40, 0, 18), Color3.new(1, 1, 1), 11)
    name.TextXAlignment = Enum.TextXAlignment.Center
    local flags = label(target, "FlagsLabel", "FLAGS\nTEAM FLAG", UDim2.new(1, 3, 0, -29), UDim2.fromOffset(80, 29), Color3.new(1, 1, 1), 8)
    flags.Font = Enum.Font.Code
    flags.TextYAlignment = Enum.TextYAlignment.Top
    local details = label(target, "DetailsLabel", "DISTANCE\nWEAPON", UDim2.new(0, -20, 1, 5), UDim2.new(1, 40, 0, 25), Color3.new(1, 1, 1), 8)
    details.Font = Enum.Font.Code
    details.TextXAlignment = Enum.TextXAlignment.Center
    details.TextYAlignment = Enum.TextYAlignment.Top
    local health = frame(target, "Health", UDim2.fromOffset(-5, 94), UDim2.fromOffset(2, 76), Color3.fromRGB(218, 216, 59))
    local healthValue = label(health, "Value", "45", UDim2.fromOffset(-8, -8), UDim2.fromOffset(13, 10), Color3.new(1, 1, 1), 8)
    healthValue.Font = Enum.Font.Code
    local head = frame(target, "HeadDot", UDim2.fromScale(0.5, 0.16), UDim2.fromOffset(4, 4), Color3.fromRGB(255, 35, 53))
    head.ZIndex = 5
    head.Visible = false
    self.Preview = {Panel = panel, Target = target, Viewport = viewport, World = world, Camera = camera, Fill = tint, Box = outline, Name = name, Flags = flags, Details = details, Health = health, Head = head}
    self:SetPreviewModel(nil)
end

function Window:SetPreviewModel(model)
    if not self.Preview then return end
    local preview = self.Preview
    local clone
    if model then
        assert(typeof(model) == "Instance" and model:IsA("Model"), "Preview model must be a Model")
        -- Do not change the caller's Archivable flag or any original descendants.
        if model.Archivable then
            local ok, result = pcall(function() return model:Clone() end)
            if ok then clone = result end
        end
    end
    if not clone then
        clone = Instance.new("Model")
        clone.Name = "Mannequin"
        local parts = {
            {"Head", Vector3.new(1.25, 1.25, 1.25), Vector3.new(0, 2, 0), Color3.fromRGB(161, 169, 169)},
            {"Torso", Vector3.new(2, 2, 1), Vector3.new(0, 0.375, 0), Color3.fromRGB(22, 34, 36)},
            {"Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0.375, 0), Color3.fromRGB(22, 34, 36)},
            {"Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0.375, 0), Color3.fromRGB(22, 34, 36)},
            {"Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -1.625, 0), Color3.fromRGB(95, 112, 113)},
            {"Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -1.625, 0), Color3.fromRGB(95, 112, 113)},
        }
        for _, part in ipairs(parts) do
            create("Part", {Name = part[1], Size = part[2], Position = part[3], Color = part[4], Material = Enum.Material.SmoothPlastic, Anchored = true, CanCollide = false}, clone)
        end
    end
    for _, item in ipairs(clone:GetDescendants()) do
        if item:IsA("BaseScript") or item:IsA("ModuleScript") or item:IsA("Sound") or item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
        elseif item:IsA("Humanoid") then
            item.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
    end
    preview.World:ClearAllChildren()
    -- Newly generated avatars can have unstepped accessory welds. Resolve these
    -- before measuring the model so a distant handle cannot shrink the avatar.
    for _, item in ipairs(clone:GetDescendants()) do
        if item:IsA("Weld") and item.Name == "AccessoryWeld" and item.Part0 and item.Part1 then
            item.Part0.CFrame = item.Part1.CFrame * item.C1 * item.C0:Inverse()
        end
    end
    clone.Parent = preview.World
    clone:PivotTo(CFrame.new())
    local bounds, size = clone:GetBoundingBox()
    local aspect = 118 / 166
    local distance = math.max(size.Y, size.X / aspect) / (2 * math.tan(math.rad(preview.Camera.FieldOfView / 2))) + size.Z / 2
    local center = bounds.Position
    preview.Camera.CFrame = CFrame.lookAt(center + Vector3.new(0, 0, -distance * 1.02), center)
    preview.Model = clone
end

function Window:UpdatePreview(options)
    if not self.Preview then return end
    local p = self.Preview
    for key, object in pairs({Box = p.Box, BoxFilled = p.Fill, Name = p.Name, Health = p.Health, HeadDot = p.Head, Flags = p.Flags, Details = p.Details}) do
        if options[key] ~= nil then object.Visible = options[key] == true end
    end
    if options.BoxColor then p.Box.Outline.Color = options.BoxColor end
    if options.FillColor then p.Fill.BackgroundColor3 = options.FillColor end
    if options.FillTransparency then p.Fill.BackgroundTransparency = options.FillTransparency end
    if options.NameColor then p.Name.TextColor3 = options.NameColor end
    if options.NameText then p.Name.Text = options.NameText end
    if options.FlagsText then p.Flags.Text = options.FlagsText end
    if options.DetailsText then p.Details.Text = options.DetailsText end
    if options.HeadColor then p.Head.BackgroundColor3 = options.HeadColor end
    if options.ImageTransparency then p.Viewport.ImageTransparency = options.ImageTransparency end
end

-- Notifications are allocated lazily and use one render connection while active.
local NOTICE_TYPES = {
    Info = {"i", Color3.fromRGB(87, 192, 225)},
    Success = {"+", Color3.fromRGB(66, 199, 157)},
    Warning = {"!", Color3.fromRGB(231, 185, 86)},
    Error = {"!", Color3.fromRGB(236, 105, 118)},
}

function Window:_noticeGui()
    if self.NotificationGui then return end
    self.NotificationGui = create("ScreenGui", {
        Name = self.Gui.Name .. "Notifications", ResetOnSpawn = false,
        IgnoreGuiInset = false, DisplayOrder = self.Gui.DisplayOrder + 1,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, self.Gui.Parent)
    self._noticeRoot = frame(self.NotificationGui, "Stack", UDim2.fromScale(1, self.NotificationOptions.Position == "BottomRight" and 1 or 0), UDim2.fromOffset(self.NotificationOptions.Width + 40, 600), self.Theme.Panel)
    self._noticeRoot.AnchorPoint = Vector2.new(1, self.NotificationOptions.Position == "BottomRight" and 1 or 0)
    self._noticeRoot.BackgroundTransparency = 1
    self._noticeScale = create("UIScale", {Scale = 1}, self._noticeRoot)
end

function Window:_showNotice(notice)
    self:_noticeGui()
    local width = self.NotificationOptions.Width
    local card = create("CanvasGroup", {
        Name = "Notification", Size = UDim2.fromOffset(width, 86),
        BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0,
        GroupTransparency = 1, ClipsDescendants = true,
    }, self._noticeRoot)
    notice.Instance = card
    notice.Phase = "Entering"
    notice.PhaseAge = 0
    notice.Elapsed = 0
    local outline = create("UIStroke", {Color = self.Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, card)
    local edge = frame(card, "Accent", UDim2.fromOffset(0, 0), UDim2.new(0, 2, 1, 0), self.Theme.Accent)
    local icon = label(card, "Icon", "", UDim2.fromOffset(12, 13), UDim2.fromOffset(18, 18), self.Theme.Accent, 16)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    local title = label(card, "Title", "", UDim2.fromOffset(40, 11), UDim2.new(1, -71, 0, 18), self.Theme.Text, 13)
    local body = label(card, "Message", "", UDim2.fromOffset(40, 32), UDim2.new(1, -54, 0, 38), self.Theme.Muted, 12)
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top
    local close = button(card, "Dismiss", UDim2.new(1, -30, 0, 7), UDim2.fromOffset(24, 24))
    local closeText = label(close, "Icon", "×", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), self.Theme.Muted, 17)
    closeText.TextXAlignment = Enum.TextXAlignment.Center
    local progress = frame(card, "Lifetime", UDim2.new(0, 2, 1, -2), UDim2.new(1, -2, 0, 2), self.Theme.Accent)
    notice._draw = function()
        local style = NOTICE_TYPES[notice.Options.Type]
        edge.BackgroundColor3 = style[2]
        icon.Text, icon.TextColor3 = style[1], style[2]
        progress.BackgroundColor3 = style[2]
        title.Text, body.Text = notice.Options.Title, notice.Options.Text
        progress.Visible = notice.Options.Duration > 0
    end
    close.Activated:Connect(function() notice:Dismiss() end)
    card.MouseEnter:Connect(function() notice.Hovered = true; outline.Color = self.Theme.Muted end)
    card.MouseLeave:Connect(function() notice.Hovered = false; outline.Color = self.Theme.Border end)
    notice:_draw()
end

function Window:_stepNotices(dt)
    if self._destroyed then return end
    local active = 0
    for _, notice in ipairs(self._notices) do if notice.Instance and not notice.Closed then active += 1 end end
    for _, notice in ipairs(self._notices) do
        if not notice.Instance and not notice.Closed and active < self.NotificationOptions.MaxVisible then
            self:_showNotice(notice)
            active += 1
        end
    end
    if self._noticeScale then
        local view = self.NotificationGui.AbsoluteSize
        self._noticeScale.Scale = math.max(0.1, math.min(1, view.X / (self.NotificationOptions.Width + 40), view.Y / (self.NotificationOptions.MaxVisible * 96 + 20)))
    end
    local offset = 20
    local finished = {}
    for _, notice in ipairs(self._notices) do
        if notice.Instance and not notice.Closed then
            local bottom = self.NotificationOptions.Position == "BottomRight"
            local y = bottom and 600 - offset - 86 or offset
            notice._y = notice._y and notice._y + (y - notice._y) * (1 - math.exp(-dt * 20)) or y
            notice.PhaseAge += dt
            local alpha = 1
            if notice.Phase == "Entering" then
                alpha = math.clamp(notice.PhaseAge / 0.18, 0, 1)
                if alpha == 1 then notice.Phase = "Visible"; notice.PhaseAge = 0 end
            elseif notice.Phase == "Closing" then
                alpha = 1 - math.clamp(notice.PhaseAge / 0.16, 0, 1)
                if alpha == 0 then table.insert(finished, notice) end
            elseif not notice.Hovered and notice.Options.Duration > 0 then
                notice.Elapsed += dt
                if notice.Elapsed >= notice.Options.Duration then notice:Dismiss("Timeout") end
            end
            notice.Instance.Position = UDim2.fromOffset(20 + (1 - alpha) * 16, notice._y)
            notice.Instance.GroupTransparency = 1 - alpha
            local fraction = notice.Options.Duration > 0 and 1 - math.clamp(notice.Elapsed / notice.Options.Duration, 0, 1) or 1
            notice.Instance.Lifetime.Size = UDim2.new(fraction, -2 * fraction, 0, 2)
            offset += 96
        elseif notice.Closed then
            table.insert(finished, notice)
        end
    end
    for _, notice in ipairs(finished) do
        local index = table.find(self._notices, notice)
        if index then table.remove(self._notices, index) end
        notice.Closed = true
        if notice.Instance then notice.Instance:Destroy() end
        self:_callback(notice.Options.OnClose, notice.Reason or "Dismissed")
    end
    if #self._notices == 0 and self._noticeConnection then
        self._noticeConnection:Disconnect()
        self._noticeConnection = nil
    end
end

function Window:Notify(options)
    assert(not self._destroyed, "Window has been destroyed")
    if not self.Features.Notifications then return nil, "Notifications are disabled" end
    options = table.clone(options or {})
    options.Title = options.Title or "Notification"
    options.Text = options.Text or ""
    options.Type = options.Type or "Info"
    options.Duration = options.Duration == nil and self.NotificationOptions.Duration or options.Duration
    local function valid(value)
        return type(value.Title) == "string" and type(value.Text) == "string" and NOTICE_TYPES[value.Type] ~= nil
            and finite(value.Duration) and value.Duration >= 0
            and (value.OnClose == nil or type(value.OnClose) == "function")
    end
    assert(valid(options), "Invalid notification options")
    if #self._notices >= 32 then return nil, "Notification queue is full (32)" end
    local notice = {Options = options, Closed = false, Phase = "Queued", Elapsed = 0, Hovered = false}
    function notice:Dismiss(reason)
        if self.Closed or self.Phase == "Closing" then return end
        self.Reason = reason or "Dismissed"
        if self.Instance then self.Phase = "Closing"; self.PhaseAge = 0 else self.Closed = true end
    end
    function notice:Update(changes)
        if self.Closed or self.Phase == "Closing" then return false end
        local nextOptions = table.clone(self.Options)
        for key, value in pairs(changes) do nextOptions[key] = value end
        assert(valid(nextOptions), "Invalid notification update")
        self.Options = nextOptions
        if changes.Duration ~= nil then self.Elapsed = 0 end
        if self._draw then self:_draw() end
        return true
    end
    table.insert(self._notices, notice)
    if not self._noticeConnection then
        self._noticeConnection = RunService.RenderStepped:Connect(function(dt) self:_stepNotices(dt) end)
    end
    return notice
end

-- Optional live ESP: native Frames and Highlights, explicit targets, no remotes.
local ESP_DEFAULTS = {
    Enabled = false, Box = true, BoxFilled = false, Name = true, Health = true,
    Distance = true, Tracer = false, Highlight = false, ThroughWalls = false,
    MaxDistance = 1000, Color = Color3.fromRGB(125, 238, 245),
    FillTransparency = 0.85, TextSize = 12, TracerOrigin = "Bottom",
    -- When true, selected ESP settings and the first registered target mirror
    -- into Window.Preview. It requires Features.Preview at window creation.
    Preview = false,
}

local function espOptions(current, changes)
    local result = table.clone(current)
    for key, value in pairs(changes or {}) do
        assert(ESP_DEFAULTS[key] ~= nil, "Unknown ESP option: " .. tostring(key))
        local default = ESP_DEFAULTS[key]
        if typeof(default) == "Color3" then
            assert(typeof(value) == "Color3", "ESP Color must be a Color3")
        elseif type(default) == "boolean" then
            assert(type(value) == "boolean", "ESP " .. key .. " must be boolean")
        elseif type(default) == "number" then
            assert(finite(value), "ESP " .. key .. " must be finite")
        end
        result[key] = value
    end
    assert(result.MaxDistance >= 0 and result.MaxDistance <= 100000, "MaxDistance must be 0..100000 studs")
    assert(result.FillTransparency >= 0 and result.FillTransparency <= 1, "FillTransparency must be 0..1")
    assert(result.TextSize >= 8 and result.TextSize <= 24, "TextSize must be 8..24")
    assert(result.TracerOrigin == "Top" or result.TracerOrigin == "Center" or result.TracerOrigin == "Bottom", "TracerOrigin must be Top, Center or Bottom")
    return result
end

local function targetOptions(options)
    local result = table.clone(options or {})
    for key, value in pairs(result) do
        assert(key == "Name" or key == "Color", "Target options support Name and Color")
        assert((key == "Name" and type(value) == "string") or (key == "Color" and typeof(value) == "Color3"), "Invalid target " .. key)
    end
    return result
end

function Window:CreateESP(options)
    assert(not self._destroyed and self.Features.ESP, "Enable Features.ESP when creating the window")
    local parsed = espOptions(ESP_DEFAULTS, options)
    assert(not parsed.Preview or self.Preview, "ESP Preview requires Features.Preview = true when creating the window")
    local controller = setmetatable({Window = self, Options = parsed, Targets = {}, _players = {}, _destroyed = false}, ESP)
    controller.Gui = create("ScreenGui", {
        Name = self.Gui.Name .. "ESP", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = math.max(0, self.Gui.DisplayOrder - 1), ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, self.Gui.Parent)
    controller._raycast = RaycastParams.new()
    controller._raycast.FilterType = Enum.RaycastFilterType.Exclude
    controller._raycast.IgnoreWater = true
    table.insert(self._espControllers, controller)
    return controller
end

function ESP:_syncConnection()
    local needed = not self._destroyed and self.Options.Enabled and next(self.Targets) ~= nil
    if needed and not self._connection then
        self._connection = RunService.RenderStepped:Connect(function() self:_render() end)
    elseif not needed and self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
    if not needed then
        for _, target in pairs(self.Targets) do target.Frame.Visible = false; target.Highlight.Enabled = false end
    end
end

function ESP:SetOptions(changes)
    assert(not self._destroyed, "ESP has been destroyed")
    local parsed = espOptions(self.Options, changes)
    assert(not parsed.Preview or self.Window.Preview, "ESP Preview requires Features.Preview = true when creating the window")
    self.Options = parsed
    self:_syncPreview()
    self:_syncConnection()
    return self
end

function ESP:SetEnabled(enabled)
    return self:SetOptions({Enabled = enabled})
end

function ESP:SetPreviewEnabled(enabled)
    return self:SetOptions({Preview = enabled})
end

function ESP:_syncPreview(preferred, distance)
    if not self.Options.Preview then return end
    local preview = self.Window.Preview
    assert(preview, "ESP Preview requires Features.Preview = true when creating the window")
    local target = preferred
    if not target or target.Removed then
        for _, candidate in pairs(self.Targets) do
            target = candidate
            break
        end
    end
    if not target then
        if self._previewTarget then
            self._previewTarget = nil
            self.Window:SetPreviewModel(nil)
        end
        return
    end
    if self._previewTarget ~= target.Model then
        self._previewTarget = target.Model
        self.Window:SetPreviewModel(target.Model)
    end
    local options = self.Options
    local color = target.Options.Color or options.Color
    self.Window:UpdatePreview({
        Box = options.Box,
        BoxFilled = options.BoxFilled,
        Name = options.Name,
        Health = options.Health,
        Details = options.Distance,
        BoxColor = color,
        FillColor = color,
        FillTransparency = options.FillTransparency,
        NameColor = color,
        NameText = target.Options.Name or target.Model.Name,
        DetailsText = distance and (math.round(distance) .. " studs") or "ESP PREVIEW",
        FlagsText = "",
    })
end

function ESP:Add(model, options)
    assert(not self._destroyed, "ESP has been destroyed")
    assert(typeof(model) == "Instance" and model:IsA("Model"), "ESP:Add expects a Model")
    local parsed = targetOptions(options)
    if self.Targets[model] then
        self.Targets[model].Options = parsed
        return self.Targets[model]
    end
    local target = {Model = model, Options = parsed, Removed = false}
    target.Frame = frame(self.Gui, "Target", UDim2.fromOffset(0, 0), UDim2.fromOffset(0, 0), self.Options.Color)
    target.Frame.BackgroundTransparency = 1
    target.Frame.Visible = false
    target.Box = frame(target.Frame, "Box", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), self.Options.Color)
    target.Box.BackgroundTransparency = 1
    target.Stroke = create("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Miter, Thickness = 1, Color = self.Options.Color}, target.Box)
    target.Fill = frame(target.Frame, "Fill", UDim2.fromOffset(1, 1), UDim2.new(1, -2, 1, -2), self.Options.Color)
    target.Fill.BackgroundTransparency = self.Options.FillTransparency
    target.Name = label(target.Frame, "Name", "", UDim2.new(0.5, -120, 0, -20), UDim2.fromOffset(240, 18), self.Options.Color)
    target.Name.TextXAlignment = Enum.TextXAlignment.Center
    target.Distance = label(target.Frame, "Distance", "", UDim2.new(0.5, -75, 1, 3), UDim2.fromOffset(150, 18), self.Options.Color)
    target.Distance.TextXAlignment = Enum.TextXAlignment.Center
    target.Health = frame(target.Frame, "Health", UDim2.fromOffset(-6, 0), UDim2.new(0, 3, 1, 0), Color3.fromRGB(7, 12, 15))
    target.HealthFill = frame(target.Health, "Fill", UDim2.fromScale(0, 1), UDim2.fromScale(1, 1), Color3.fromRGB(65, 205, 143))
    target.HealthFill.AnchorPoint = Vector2.new(0, 1)
    target.Tracer = frame(target.Frame, "Tracer", UDim2.fromOffset(0, 0), UDim2.fromOffset(0, 1), self.Options.Color)
    target.Tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    target.Highlight = create("Highlight", {Name = "Highlight", Adornee = model, Enabled = false}, target.Frame)
    local controller = self
    function target:Remove() controller:Remove(model) end
    function target:SetOptions(changes)
        assert(not self.Removed, "Target was removed")
        local combined = table.clone(self.Options)
        for key, value in pairs(changes) do combined[key] = value end
        self.Options = targetOptions(combined)
        return self
    end
    target._destroyConnection = model.Destroying:Connect(function() self:Remove(model) end)
    self.Targets[model] = target
    self:_syncPreview(target)
    self:_syncConnection()
    return target
end

function ESP:Remove(model)
    local target = self.Targets[model]
    if not target then return end
    self.Targets[model] = nil
    target.Removed = true
    target._destroyConnection:Disconnect()
    target.Frame:Destroy()
    if self._previewTarget == model then self._previewTarget = nil end
    self:_syncPreview()
    self:_syncConnection()
end

function ESP:TrackPlayer(player, options)
    assert(not self._destroyed and typeof(player) == "Instance" and player:IsA("Player"), "TrackPlayer expects a Player")
    assert(not self._players[player], "Player is already tracked")
    local parsed = targetOptions(options)
    if parsed.Name == nil then parsed.Name = player.DisplayName end
    local tracker = {Connected = true, _connections = {}}
    local controller = self
    local current
    local function attach(character)
        if current then controller:Remove(current) end
        current = character
        if character and tracker.Connected then controller:Add(character, parsed) end
    end
    function tracker:Disconnect()
        if not self.Connected then return end
        self.Connected = false
        for _, connection in ipairs(self._connections) do connection:Disconnect() end
        if current then controller:Remove(current) end
        controller._players[player] = nil
    end
    table.insert(tracker._connections, player.CharacterAdded:Connect(attach))
    table.insert(tracker._connections, player.CharacterRemoving:Connect(function(character)
        controller:Remove(character)
        if current == character then current = nil end
    end))
    table.insert(tracker._connections, player.AncestryChanged:Connect(function()
        if player.Parent ~= Players then tracker:Disconnect() end
    end))
    self._players[player] = tracker
    attach(player.Character)
    return tracker
end

function ESP:_render()
    local camera = workspace.CurrentCamera
    if not camera then
        for _, target in pairs(self.Targets) do target.Frame.Visible = false; target.Highlight.Enabled = false end
        return
    end
    local options = self.Options
    local view = camera.ViewportSize
    local character = Players.LocalPlayer.Character
    self._raycast.FilterDescendantsInstances = character and {character} or {}
    for model, target in pairs(self.Targets) do
        target.Frame.Visible = false
        target.Highlight.Enabled = false
        if not model:IsDescendantOf(workspace) or not model:FindFirstChildWhichIsA("BasePart", true) then continue end
        local bounds, size = model:GetBoundingBox()
        local distance = (bounds.Position - camera.CFrame.Position).Magnitude
        if distance > options.MaxDistance then continue end
        if not options.ThroughWalls then
            local hit = workspace:Raycast(camera.CFrame.Position, bounds.Position - camera.CFrame.Position, self._raycast)
            if hit and not hit.Instance:IsDescendantOf(model) then continue end
        end
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local inFront = true
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    local point = camera:WorldToViewportPoint(bounds * Vector3.new(size.X * x / 2, size.Y * y / 2, size.Z * z / 2))
                    if point.Z <= 0.1 then inFront = false end
                    minX, minY = math.min(minX, point.X), math.min(minY, point.Y)
                    maxX, maxY = math.max(maxX, point.X), math.max(maxY, point.Y)
                end
            end
        end
        if not inFront or maxX < 0 or maxY < 0 or minX > view.X or minY > view.Y then continue end
        minX, minY = math.clamp(minX, 0, view.X), math.clamp(minY, 0, view.Y)
        maxX, maxY = math.clamp(maxX, 0, view.X), math.clamp(maxY, 0, view.Y)
        local width, height = math.max(1, maxX - minX), math.max(1, maxY - minY)
        local color = target.Options.Color or options.Color
        if options.Preview and self._previewTarget == model then self:_syncPreview(target, distance) end
        target.Frame.Position = UDim2.fromOffset(math.round(minX), math.round(minY))
        target.Frame.Size = UDim2.fromOffset(math.round(width), math.round(height))
        target.Frame.Visible = true
        target.Box.Visible, target.Stroke.Color = options.Box, color
        target.Fill.Visible, target.Fill.BackgroundColor3, target.Fill.BackgroundTransparency = options.BoxFilled, color, options.FillTransparency
        target.Name.Visible, target.Name.Text, target.Name.TextColor3 = options.Name, target.Options.Name or model.Name, color
        target.Distance.Visible, target.Distance.Text, target.Distance.TextColor3 = options.Distance, math.round(distance) .. " studs", color
        target.Name.TextSize, target.Distance.TextSize = options.TextSize, options.TextSize
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        target.Health.Visible = options.Health and humanoid ~= nil
        if humanoid then
            local ratio = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 0
            target.HealthFill.Size = UDim2.fromScale(1, ratio)
            target.HealthFill.BackgroundColor3 = Color3.fromRGB(237, 99, 100):Lerp(Color3.fromRGB(65, 205, 143), ratio)
        end
        target.Tracer.Visible, target.Tracer.BackgroundColor3 = options.Tracer, color
        if options.Tracer then
            local origin = Vector2.new(view.X / 2, options.TracerOrigin == "Top" and 0 or options.TracerOrigin == "Center" and view.Y / 2 or view.Y)
            local destination = Vector2.new(minX + width / 2, maxY)
            local delta = destination - origin
            local center = (origin + destination) / 2 - Vector2.new(minX, minY)
            target.Tracer.Position = UDim2.fromOffset(center.X, center.Y)
            target.Tracer.Size = UDim2.fromOffset(delta.Magnitude, 1)
            target.Tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
        end
        target.Highlight.Enabled = options.Highlight
        target.Highlight.FillColor, target.Highlight.OutlineColor = color, color
        target.Highlight.FillTransparency = options.FillTransparency
        target.Highlight.DepthMode = options.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    end
end

function ESP:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    if self._connection then self._connection:Disconnect(); self._connection = nil end
    for _, tracker in pairs(table.clone(self._players)) do tracker:Disconnect() end
    for model in pairs(table.clone(self.Targets)) do self:Remove(model) end
    self.Gui:Destroy()
    local index = table.find(self.Window._espControllers, self)
    if index then table.remove(self.Window._espControllers, index) end
end

return Serotonin

end)()

-- SEROTONIN UI v2 | editable developer starter
-- Full documentation: README.md. The library itself adds no tabs or targets.

local UI = Serotonin

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
