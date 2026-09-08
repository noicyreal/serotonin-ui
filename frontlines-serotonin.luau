-- FRONTLINES
-- Serotonin UI front end for the combat and visual helpers below.

local EXPECTED_PLACE_ID = 5938036553
if game.PlaceId ~= EXPECTED_PLACE_ID then
    warn(("[Frontlines Companion] Unsupported place: %d"):format(game.PlaceId))
    return
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local state = (getgenv and getgenv()) or _G
local frontlinesActor

if getactors then
    for _, actor in ipairs(getactors()) do
        if actor.Name == "frontlines_client_actor" then
            frontlinesActor = actor
            break
        end
    end
end

if state.__FRONTLINES_COMPANION_UNLOAD then
    pcall(state.__FRONTLINES_COMPANION_UNLOAD)
end

local running = true
local window

local COMBAT_ASSIST_PAYLOAD = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local actor = player.PlayerScripts:FindFirstChild("frontlines_client_actor")
local env = getgenv()

if env.__FRONTLINES_COMBAT_UNLOAD then
    pcall(env.__FRONTLINES_COMBAT_UNLOAD)
end

-- A previous payload revision may have left the oth math.max hook installed
-- on this actor. Clear it so reinstalling stays idempotent.
if env.__FRONTLINES_OTH_AMMO and type(oth) == "table" and type(oth.unhook) == "function" then
    pcall(oth.unhook, math.max)
    env.__FRONTLINES_OTH_AMMO = nil
end

local globals
for _, object in ipairs(getgc(true)) do
    if type(object) == "table"
        and type(rawget(object, "soldier_models")) == "table"
        and type(rawget(object, "cli_state")) == "table"
        and type(rawget(object, "sol_teams")) == "table" then
        globals = object
        break
    end
end

if not globals then
    if actor then
        actor:SetAttribute("__fl_error", "FRONTLINES soldier state was not found")
    end
    return
end

local active = true
local boxesEnabled = true
local highlightsEnabled = true
local teamCheckEnabled = true
local aimEnabled = true
local aimHeld = false
local targetId
local connections = {}
local highlights = {}
local boxes = {}
local renderStepName = "FrontlinesCombatAssistAim"
local FOV_RADIUS = 90
local MAX_DISTANCE = 2000
local fovVisible = true
local noRecoilEnabled = true
local noSpreadEnabled = true
local noReloadEnabled = true
local infiniteAmmoEnabled = true
local triggerBotEnabled = false
local triggerDelay = 0.075
local hitboxMode = "head"
local aimbotEnabled = false
local aimbotSmoothness = 6
local rapidFireEnabled = false
local multiBulletEnabled = false
local highVelocityEnabled = false
local automaticEnabled = false
local TRIGGER_RADIUS = 11
local triggerBusy = false
local lastTrigger = 0
local bulletCallback
local bulletCallbacks = {}
local ammoCallbacks = {}
local ammoHooks = {}
local setAmmoCallback
local decrementCallback
local ammoStore
local reserveStore
local othAmmoHooked = false
local recoilCallback
local exeSet
local bulletSpawnSet
local originalBulletCallback
local originalRecoilCallback
local originalExeSet
local originalWeaponStats = setmetatable({}, {__mode = "k"})

local visualGui = Instance.new("ScreenGui")
visualGui.Name = "FrontlinesCombatVisuals"
visualGui.IgnoreGuiInset = true
visualGui.ResetOnSpawn = false
visualGui.DisplayOrder = 2147483647
visualGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local ok, uiParent = pcall(function()
    return gethui and gethui() or game:GetService("CoreGui")
end)
uiParent = ok and uiParent or game:GetService("CoreGui")
local oldVisualGui = uiParent:FindFirstChild(visualGui.Name)
if oldVisualGui then
    oldVisualGui:Destroy()
end
visualGui.Parent = uiParent

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.fromScale(0.5, 0.5)
fovCircle.Size = UDim2.fromOffset(FOV_RADIUS * 2, FOV_RADIUS * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.ZIndex = 5
fovCircle.Parent = visualGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 175, 80)
fovStroke.Transparency = 0.18
fovStroke.Thickness = 1.5
fovStroke.Parent = fovCircle

local function setAttribute(name, value)
    if actor then
        actor:SetAttribute(name, value)
    end
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function getHead(model)
    return model and (
        model:FindFirstChild("TPVBodyVanillaHead", true)
        or model.PrimaryPart
    )
end

local function getHeadPosition(id, model)
    local joints = globals.soldier_joints and globals.soldier_joints[id]
    local headBone = type(joints) == "table" and joints[6]
    if headBone and headBone:IsA("Bone") then
        return headBone.TransformedWorldCFrame.Position
    end

    local head = getHead(model)
    return head and head.Position or nil
end

local function getBodyPosition(id, model)
    if model then
        local torso = model:FindFirstChild("TPVBodyVanillaTorsoFront", true)
            or model:FindFirstChild("TPVBodyVanillaTorsoBack", true)
        if torso and torso:IsA("BasePart") then
            return torso.Position
        end
    end

    -- Fallback: the chest sits roughly below the head.
    local headPosition = getHeadPosition(id, model)
    if headPosition then
        return headPosition - Vector3.new(0, 1.4, 0)
    end
    return nil
end

local function getAimPosition(id, model)
    local mode = hitboxMode
    if mode == "random" then
        mode = math.random(1, 2) == 1 and "head" or "body"
    end
    if mode == "body" then
        return getBodyPosition(id, model)
    end
    return getHeadPosition(id, model)
end

local function isAlive(id, model)
    local health = globals.gbl_sol_healths and globals.gbl_sol_healths[id]
    return model ~= nil and model.Parent ~= nil and type(health) == "number" and health > 0
end

local function isEnemy(id)
    local fpvId = globals.cli_state.fpv_sol_id
    local ownTeam = globals.sol_teams[fpvId]
    local targetTeam = globals.sol_teams[id]
    return id ~= fpvId and ownTeam ~= nil and targetTeam ~= nil and targetTeam ~= ownTeam
end

local function isVisible(model, point)
    local camera = workspace.CurrentCamera
    if not camera then
        return false
    end

    local origin = camera.CFrame.Position
    local direction = point - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local excluded = {camera}
    local localModel = globals.soldier_models[globals.cli_state.fpv_sol_id]
    if localModel then
        table.insert(excluded, localModel)
    end
    params.FilterDescendantsInstances = excluded

    local result = workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(model)
end

local function screenDistance(id, model)
    local camera = workspace.CurrentCamera
    local headPosition = getAimPosition(id, model)
    if not camera or not headPosition then
        return math.huge, false, nil
    end

    local viewportPoint, onScreen = camera:WorldToViewportPoint(headPosition)
    if not onScreen or viewportPoint.Z <= 0 then
        return math.huge, false, headPosition
    end

    local center = camera.ViewportSize * 0.5
    local distance = (Vector2.new(viewportPoint.X, viewportPoint.Y) - center).Magnitude
    return distance, true, headPosition
end

local function validTarget(id, expandedFov)
    local model = globals.soldier_models[id]
    if not isEnemy(id) or not isAlive(id, model) then
        return false
    end

    local distance, onScreen, headPosition = screenDistance(id, model)
    if not onScreen or distance > FOV_RADIUS * (expandedFov and 1.35 or 1) then
        return false
    end

    local camera = workspace.CurrentCamera
    if not camera or (headPosition - camera.CFrame.Position).Magnitude > MAX_DISTANCE then
        return false
    end

    return true
end

local function chooseTarget()
    local bestId
    local bestDistance = FOV_RADIUS

    for id, model in pairs(globals.soldier_models) do
        if isEnemy(id) and isAlive(id, model) then
            local distance, onScreen, headPosition = screenDistance(id, model)
            local camera = workspace.CurrentCamera
            if onScreen
                and distance < bestDistance
                and camera
                and (headPosition - camera.CFrame.Position).Magnitude <= MAX_DISTANCE then
                bestId = id
                bestDistance = distance
            end
        end
    end

    return bestId
end

local function updateTargetAttribute()
    local name = targetId and globals.cli_names and globals.cli_names[targetId]
    setAttribute("__fl_target", name or "")
end

local function clearHighlights()
    for id, highlight in pairs(highlights) do
        if highlight then
            highlight:Destroy()
        end
        highlights[id] = nil
    end
end

local function clearBoxes()
    for id, box in pairs(boxes) do
        if box.frame then
            box.frame:Destroy()
        end
        boxes[id] = nil
    end
end

local function getPlayerColors(id)
    if id == targetId then
        return Color3.fromRGB(255, 210, 45), Color3.fromRGB(255, 245, 180)
    elseif isEnemy(id) then
        return Color3.fromRGB(235, 65, 65), Color3.fromRGB(255, 190, 190)
    end
    return Color3.fromRGB(55, 165, 255), Color3.fromRGB(190, 225, 255)
end

local function getScreenBounds(id, model)
    local camera = workspace.CurrentCamera
    if not camera or not model then
        return nil
    end

    -- FRONTLINES uses skinned meshes. BasePart positions stay near the rig origin,
    -- while TransformedWorldCFrame is where the animated player is actually drawn.
    local joints = globals.soldier_joints and globals.soldier_joints[id]
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local projected = 0

    if type(joints) == "table" then
        for jointIndex, joint in pairs(joints) do
            if type(jointIndex) == "number"
                and jointIndex <= 86
                and joint
                and joint:IsA("Bone") then
                local point = camera:WorldToViewportPoint(joint.TransformedWorldCFrame.Position)
                if point.Z > 0 then
                    minX = math.min(minX, point.X)
                    minY = math.min(minY, point.Y)
                    maxX = math.max(maxX, point.X)
                    maxY = math.max(maxY, point.Y)
                    projected += 1
                end
            end
        end
    end

    if projected < 3 then
        local headPosition = getAimPosition(id, model)
        local root = model.PrimaryPart
        if not headPosition or not root then
            return nil
        end
        local headPoint = camera:WorldToViewportPoint(headPosition + Vector3.new(0, 0.3, 0))
        local footPoint = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.7, 0))
        if headPoint.Z <= 0 or footPoint.Z <= 0 then
            return nil
        end
        minX = math.min(headPoint.X, footPoint.X)
        maxX = math.max(headPoint.X, footPoint.X)
        minY = math.min(headPoint.Y, footPoint.Y)
        maxY = math.max(headPoint.Y, footPoint.Y)
    end

    local width = maxX - minX
    local height = maxY - minY
    local horizontalPadding = math.max(3, width * 0.1)
    local verticalPadding = math.max(2, height * 0.04)
    minX -= horizontalPadding
    maxX += horizontalPadding
    minY -= verticalPadding
    maxY += verticalPadding

    local viewport = camera.ViewportSize
    minX = math.clamp(minX, 0, viewport.X)
    minY = math.clamp(minY, 0, viewport.Y)
    maxX = math.clamp(maxX, 0, viewport.X)
    maxY = math.clamp(maxY, 0, viewport.Y)

    if maxX - minX < 4 or maxY - minY < 4 then
        return nil
    end
    return minX, minY, maxX, maxY
end

local function createBox(id)
    local frame = Instance.new("Frame")
    frame.Name = "PlayerBox_" .. tostring(id)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = visualGui

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 2
    stroke.Transparency = 0.02
    stroke.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, -20, 0, -19)
    nameLabel.Size = UDim2.new(1, 40, 0, 17)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextStrokeTransparency = 0.25
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.ZIndex = 11
    nameLabel.Parent = frame

    local box = {frame = frame, stroke = stroke, name = nameLabel}
    boxes[id] = box
    return box
end

local function updateBoxes()
    if not boxesEnabled then
        clearBoxes()
        return
    end

    local seen = {}
    for id, model in pairs(globals.soldier_models) do
        if id ~= globals.cli_state.fpv_sol_id
            and isAlive(id, model)
            and (not teamCheckEnabled or isEnemy(id)) then
            seen[id] = true
            local box = boxes[id] or createBox(id)
            local minX, minY, maxX, maxY = getScreenBounds(id, model)
            if minX then
                local fillColor, outlineColor = getPlayerColors(id)
                box.frame.Position = UDim2.fromOffset(minX, minY)
                box.frame.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
                box.frame.Visible = true
                box.stroke.Color = outlineColor
                box.name.TextColor3 = fillColor
                box.name.Text = globals.cli_names and globals.cli_names[id] or ("Player " .. tostring(id))
            else
                box.frame.Visible = false
            end
        end
    end

    for id, box in pairs(boxes) do
        if not seen[id] then
            box.frame:Destroy()
            boxes[id] = nil
        end
    end
end

local function setFovRadius(radius)
    FOV_RADIUS = math.clamp(radius, 30, 250)
    fovCircle.Size = UDim2.fromOffset(FOV_RADIUS * 2, FOV_RADIUS * 2)
    setAttribute("__fl_fov", FOV_RADIUS)
end

local function rememberWeapon(equipment)
    if type(equipment) ~= "table" or originalWeaponStats[equipment] then
        return originalWeaponStats[equipment]
    end

    local fire = equipment.fire_params
    local reload = equipment.reload_params
    local saved = {fire = {}, reload = {}}
    if type(fire) == "table" then
        saved.fire.rpm = fire.rpm
        saved.fire.discharge_n = fire.discharge_n
        saved.fire.muzzle_velocity = fire.muzzle_velocity
        saved.fire.cycle_mode = fire.cycle_mode
    end
    if type(reload) == "table" then
        saved.reload.dry_reload_duration = reload.dry_reload_duration
        saved.reload.tac_reload_duration = reload.tac_reload_duration
        saved.reload.reload_increment_duration = reload.reload_increment_duration
        saved.reload.reload_end_duration = reload.reload_end_duration
        saved.reload.ammo_in_time = reload.ammo_in_time
    end
    originalWeaponStats[equipment] = saved
    return saved
end

local function restoreWeaponGroup(group)
    for equipment, saved in pairs(originalWeaponStats) do
        local destination = group == "fire" and equipment.fire_params or equipment.reload_params
        local values = saved[group]
        if type(destination) == "table" and type(values) == "table" then
            for name, value in pairs(values) do
                destination[name] = value
            end
        end
    end
end

local function applyWeaponMods()
    local equipmentState = globals.fpv_sol_equipment
    local equipment = equipmentState and equipmentState.curr_equipment
    if type(equipment) ~= "table" then
        return
    end

    local saved = rememberWeapon(equipment)
    local fire = equipment.fire_params
    local reload = equipment.reload_params
    if type(fire) == "table" then
        if type(saved.fire.rpm) == "number" then
            fire.rpm = rapidFireEnabled and math.max(saved.fire.rpm * 2, 1200) or saved.fire.rpm
        end
        if type(saved.fire.discharge_n) == "number" then
            fire.discharge_n = multiBulletEnabled and math.max(saved.fire.discharge_n * 2, 2) or saved.fire.discharge_n
        end
        if type(saved.fire.muzzle_velocity) == "number" then
            fire.muzzle_velocity = highVelocityEnabled and saved.fire.muzzle_velocity * 1.75 or saved.fire.muzzle_velocity
        end
        if saved.fire.cycle_mode ~= nil then
            local cycleModes = rawget(_G, "cycle_mode")
            fire.cycle_mode = automaticEnabled and type(cycleModes) == "table" and cycleModes.AUTO
                or saved.fire.cycle_mode
        end
    end

    if type(reload) == "table" then
        for name, value in pairs(saved.reload) do
            reload[name] = value
        end
        if noReloadEnabled then
            reload.dry_reload_duration = 0
            reload.tac_reload_duration = 0
            reload.reload_end_duration = 0
            -- Incremental weapons use modulo here, so keep this just above zero.
            reload.reload_increment_duration = 0.001
            reload.ammo_in_time = 0.001
        end
    end

    if infiniteAmmoEnabled and type(globals.fpv_sol_ammo) == "table" then
        local ammo = globals.fpv_sol_ammo
        if type(ammo.capacity) == "number" then
            ammo.ammo = ammo.capacity
        end
        ammo.reserve = math.max(tonumber(ammo.reserve) or 0, 999)
        -- Pin the authoritative mag/reserve stores captured from
        -- fpv_sol_ammo upvalues so server syncs can't drain the mag between
        -- oth interceptions.
        local current = equipmentState and equipmentState.curr_equipment
        if type(current) == "table" then
            if type(ammoStore) == "table"
                and type(current.id) == "number"
                and type(current.ammo_params) == "table"
                and type(current.ammo_params.capacity) == "number" then
                ammoStore[current.id] = current.ammo_params.capacity
            end
            if type(reserveStore) == "table"
                and type(current.subtype) == "number" then
                reserveStore[current.subtype] = math.max(
                    tonumber(reserveStore[current.subtype]) or 0, 999)
            end
        end
    end
end

local function pulseTrigger()
    local now = os.clock()
    if triggerBusy or now - lastTrigger < triggerDelay then
        return
    end
    triggerBusy = true
    lastTrigger = now
    setAttribute("__fl_last_trigger", now)

    task.spawn(function()
        local camera = workspace.CurrentCamera
        if camera then
            local center = camera.ViewportSize * 0.5
            pcall(VirtualInputManager.SendMouseButtonEvent, VirtualInputManager,
                center.X, center.Y, 0, true, game, 0)
            task.wait(0.025)
            pcall(VirtualInputManager.SendMouseButtonEvent, VirtualInputManager,
                center.X, center.Y, 0, false, game, 0)
        end
        triggerBusy = false
    end)
end

local function updateTriggerBot()
    if not triggerBotEnabled then
        return
    end

    local selectedId = targetId
    local model = selectedId and globals.soldier_models[selectedId]
    if not selectedId or not isAlive(selectedId, model) or not isEnemy(selectedId) then
        return
    end

    local distance, onScreen, point = screenDistance(selectedId, model)
    if onScreen and distance <= TRIGGER_RADIUS and point and isVisible(model, point) then
        pulseTrigger()
    end
end

local function applyAimbot()
    if not aimbotEnabled then
        return
    end

    local camera = workspace.CurrentCamera
    local selectedId = targetId
    local model = selectedId and globals.soldier_models[selectedId]
    if not camera or not selectedId
        or not isAlive(selectedId, model) or not isEnemy(selectedId) then
        return
    end

    local point = getAimPosition(selectedId, model)
    if not point then
        return
    end

    -- Higher smoothness = slower, more human camera glide. 1 snaps instantly.
    local alpha = math.clamp(1 / math.max(aimbotSmoothness, 1), 0.02, 1)
    camera.CFrame = camera.CFrame:Lerp(
        CFrame.new(camera.CFrame.Position, point), alpha)
end

local function installWeaponHooks()
    for _, object in ipairs(getgc(true)) do
        if type(object) == "function" then
            local sourceOk, source = pcall(debug.info, object, "s")
            if sourceOk then
                source = tostring(source)
                if source:find("fpv_sol_firearm_bullet", 1, true)
                    and debug.info(object, "l") == 31 then
                    local upvalues = getupvalues(object)
                    -- Ignore old hook wrappers retained by getgc after reloads.
                    if upvalues[1] == globals.cli_state
                        and upvalues[3] == globals.fpv_sol_spread
                        and type(upvalues[4]) == "function"
                        and type(upvalues[5]) == "number" then
                        bulletCallback = object
                        table.insert(bulletCallbacks, object)
                        exeSet = upvalues[4]
                        bulletSpawnSet = upvalues[5]
                    end
                elseif source:find("fpv_sol_recoil_anim", 1, true)
                    and debug.info(object, "l") == 146
                    and not recoilCallback then
                    recoilCallback = object
                elseif source:find("fpv_sol_ammo", 1, true)
                    and debug.info(object, "l") == 108 then
                    table.insert(ammoCallbacks, object)
                    -- decrement_ammo(equipment): upvalues are
                    -- (set_ammo, table_create_ret). The second upvalue is the
                    -- authoritative per-weapon mag table.
                    if not decrementCallback then
                        local upvalues = getupvalues(object)
                        if type(upvalues[1]) == "function"
                            and type(upvalues[2]) == "table" then
                            decrementCallback = object
                            ammoStore = ammoStore or upvalues[2]
                        end
                    end
                elseif source:find("fpv_sol_ammo", 1, true)
                    and debug.info(object, "l") == 37 then
                    -- set_ammo(id, amount): upvalue 5 is the authoritative
                    -- reserve table, upvalue 9 is the mag table.
                    if not setAmmoCallback then
                        local upvalues = getupvalues(object)
                        if type(upvalues[5]) == "table"
                            and type(upvalues[9]) == "table" then
                            setAmmoCallback = object
                            reserveStore = reserveStore or upvalues[5]
                            ammoStore = ammoStore or upvalues[9]
                        end
                    end
                end
            end
        end
    end

    if type(exeSet) ~= "function" or type(bulletSpawnSet) ~= "number" then
        return false, "bullet redirect hook was not found"
    end

    local function redirectBulletSpawn(setType, ...)
        local args = table.pack(...)
        if active and aimEnabled and setType == bulletSpawnSet then
            local selectedId = targetId
            if not selectedId or not validTarget(selectedId, true) then
                selectedId = chooseTarget()
                targetId = selectedId
                updateTargetAttribute()
            end

            local model = selectedId and globals.soldier_models[selectedId]
            local targetPoint = selectedId and getAimPosition(selectedId, model)
            local origin = args[3]
            local velocity = args[4]
            if targetPoint and typeof(origin) == "Vector3" and typeof(velocity) == "Vector3" then
                local targetVelocity = globals.sol_linear_velocities
                    and globals.sol_linear_velocities[selectedId]
                    or Vector3.zero
                targetPoint += targetVelocity * 0.045
                local direction = targetPoint - origin
                if direction.Magnitude > 0.001 then
                    args[4] = direction.Unit * velocity.Magnitude
                    setAttribute("__fl_last_redirect", os.clock())
                end
            end
        end
        return originalExeSet(setType, table.unpack(args, 1, args.n))
    end

    originalExeSet = exeSet
    -- Patch the bullet callback's captured exe_set directly. FRONTLINES keeps a
    -- private closure reference, so replacing this upvalue is more reliable than
    -- detouring the global dispatcher.
    if #bulletCallbacks > 0 and type(setupvalue) == "function" then
        for _, callback in ipairs(bulletCallbacks) do
            setupvalue(callback, 4, redirectBulletSpawn)
        end
    else
        originalExeSet = hookfunction(exeSet, redirectBulletSpawn)
    end

    if type(bulletCallback) == "function" then
        originalBulletCallback = hookfunction(bulletCallback, function(...)
            setAttribute("__fl_last_shot", os.clock())
            if active and noSpreadEnabled and globals.fpv_sol_spread then
                globals.fpv_sol_spread.spread = 0
            end
            return originalBulletCallback(...)
        end)
    end

    if type(recoilCallback) == "function" then
        originalRecoilCallback = hookfunction(recoilCallback, function(...)
            if active and noRecoilEnabled then
                if globals.fpv_sol_recoil then
                    globals.fpv_sol_recoil.attitude_delta = Vector3.zero
                end
                return
            end
            return originalRecoilCallback(...)
        end)
    end

    -- Infinite ammo via Potassium's Off-Thread hooks (oth.*).
    -- oth.hook only accepts C closures, so we hook math.max, which
    -- fpv_sol_ammo.set_ammo calls as math.max(0, newAmmo). Decreases aimed at
    -- the equipped weapon are refused at the source. The caller is verified
    -- with oth.get_original_thread + getscriptfromthread and the original is
    -- invoked with oth.get_root_callback(), per Potassium docs.
    local function installOthAmmoHook()
        local othLib = oth
        if type(othLib) ~= "table" or type(othLib.hook) ~= "function" then
            return false, "oth is unavailable"
        end
        if othAmmoHooked then
            return true
        end
        local hookOk, hookErr = pcall(othLib.hook, math.max, function(...)
            local argCount = select("#", ...)
            if argCount ~= 2 then
                return othLib.get_root_callback()(...)
            end
            if not (active and infiniteAmmoEnabled) then
                return othLib.get_root_callback()(...)
            end
            local first, second = ...
            -- set_ammo always calls math.max(0, newAmount).
            if first ~= 0 or type(second) ~= "number" then
                return othLib.get_root_callback()(...)
            end
            -- Never intercept our own calls, only the game's ammo module.
            local callerThread
            local gotThread = pcall(function()
                callerThread = othLib.get_original_thread()
            end)
            if not gotThread or callerThread == nil then
                return othLib.get_root_callback()(...)
            end
            if type(isourthread) == "function" then
                local oursOk, ours = pcall(isourthread, callerThread)
                if oursOk and ours then
                    return othLib.get_root_callback()(...)
                end
            end
            local callerScript
            if type(getscriptfromthread) == "function" then
                pcall(function()
                    callerScript = getscriptfromthread(callerThread)
                end)
            end
            local scriptName
            if callerScript ~= nil then
                pcall(function()
                    scriptName = callerScript.Name
                end)
            end
            if scriptName ~= "fpv_sol_ammo" then
                return othLib.get_root_callback()(...)
            end
            -- Refuse any decrease aimed at the equipped weapon, whether it is
            -- a firing decrement, a throw, or a server-forced set.
            local currentId
            pcall(function()
                local equipment = globals.fpv_sol_equipment
                    and globals.fpv_sol_equipment.curr_equipment
                if type(equipment) == "table" then
                    currentId = equipment.id
                end
            end)
            if type(currentId) == "number"
                and type(ammoStore) == "table"
                and type(ammoStore[currentId]) == "number"
                and second < ammoStore[currentId] then
                setAttribute("__fl_last_ammo_block", os.clock())
                return ammoStore[currentId]
            end
            return othLib.get_root_callback()(...)
        end)
        if not hookOk then
            return false, tostring(hookErr)
        end
        othAmmoHooked = true
        env.__FRONTLINES_OTH_AMMO = true
        setAttribute("__fl_ammo_mode", "oth")
        return true
    end

    local function installFallbackAmmoHooks()
        -- Legacy hookfunction path, used only when oth is unavailable. Calls
        -- through to the original and then restores the authoritative mag so
        -- firing/reload sequencing keeps working.
        for _, callback in ipairs(ammoCallbacks) do
            local original
            original = hookfunction(callback, function(equipment)
                local result = original(equipment)
                if active and infiniteAmmoEnabled and type(equipment) == "table" then
                    local wid = equipment.id
                    if type(wid) == "number"
                        and type(ammoStore) == "table"
                        and type(ammoStore[wid]) == "number" then
                        local capacity
                        pcall(function()
                            local entry = globals.equipments
                                and globals.equipments[wid]
                            if type(entry) == "table"
                                and type(entry.ammo_params) == "table" then
                                capacity = entry.ammo_params.capacity
                            end
                        end)
                        if type(capacity) == "number" then
                            ammoStore[wid] = capacity
                        end
                    end
                    local ammo = globals.fpv_sol_ammo
                    if type(ammo) == "table" and type(ammo.capacity) == "number" then
                        ammo.ammo = ammo.capacity
                        ammo.reserve = math.max(tonumber(ammo.reserve) or 0, 999)
                    end
                    setAttribute("__fl_last_ammo_block", os.clock())
                end
                return result
            end)
            table.insert(ammoHooks, {callback = callback, original = original})
        end
        setAttribute("__fl_ammo_mode", "hookfunction")
    end

    local othOk, othErr = installOthAmmoHook()
    if not othOk and type(hookfunction) == "function" and #ammoCallbacks > 0 then
        local fallbackOk, fallbackErr = pcall(installFallbackAmmoHooks)
        if not fallbackOk then
            setAttribute("__fl_ammo_mode", "none:" .. tostring(fallbackErr))
        end
    elseif not othOk then
        setAttribute("__fl_ammo_mode", "none:" .. tostring(othErr))
    end

    return true
end

local function updateHighlights()
    if not highlightsEnabled then
        clearHighlights()
        return
    end

    local seen = {}
    for id, model in pairs(globals.soldier_models) do
        if id ~= globals.cli_state.fpv_sol_id
            and isAlive(id, model)
            and (not teamCheckEnabled or isEnemy(id)) then
            seen[id] = true
            local highlight = highlights[id]
            if not highlight or not highlight.Parent then
                highlight = Instance.new("Highlight")
                highlight.Name = "__FL_PlayerHighlight"
                highlight.Adornee = model
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.FillTransparency = 0.68
                highlight.OutlineTransparency = 0.08
                highlight.Parent = model
                highlights[id] = highlight
            end

            highlight.FillColor, highlight.OutlineColor = getPlayerColors(id)
        end
    end

    for id, highlight in pairs(highlights) do
        if not seen[id] then
            if highlight then
                highlight:Destroy()
            end
            highlights[id] = nil
        end
    end
end

local function unload()
    if not active then
        return
    end
    active = false
    aimHeld = false
    targetId = nil

    RunService:UnbindFromRenderStep(renderStepName)
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
    clearHighlights()
    clearBoxes()
    restoreWeaponGroup("fire")
    restoreWeaponGroup("reload")
    if othAmmoHooked and type(oth) == "table" and type(oth.unhook) == "function" then
        pcall(oth.unhook, math.max)
    end
    othAmmoHooked = false
    env.__FRONTLINES_OTH_AMMO = nil
    if visualGui then
        visualGui:Destroy()
    end

    setAttribute("__fl_boxes", false)
    setAttribute("__fl_highlights", false)
    setAttribute("__fl_team_check", false)
    setAttribute("__fl_aim", false)
    setAttribute("__fl_aimheld", false)
    setAttribute("__fl_no_recoil", false)
    setAttribute("__fl_no_spread", false)
    setAttribute("__fl_no_reload", false)
    setAttribute("__fl_infinite_ammo", false)
    setAttribute("__fl_ammo_mode", false)
    setAttribute("__fl_last_ammo_block", nil)
    setAttribute("__fl_triggerbot", false)
    setAttribute("__fl_trigger_delay", false)
    setAttribute("__fl_hitbox", false)
    setAttribute("__fl_aimbot", false)
    setAttribute("__fl_aim_smooth", false)
    setAttribute("__fl_rapid_fire", false)
    setAttribute("__fl_multi_bullet", false)
    setAttribute("__fl_high_velocity", false)
    setAttribute("__fl_automatic", false)
    setAttribute("__fl_hooks", false)
    setAttribute("__fl_fov_visible", false)
    setAttribute("__fl_fov", nil)
    setAttribute("__fl_target", "")
    setAttribute("__fl_last_redirect", nil)
    setAttribute("__fl_last_shot", nil)
    setAttribute("__fl_last_trigger", nil)
    setAttribute("__fl_error", nil)
    env.__FRONTLINES_COMBAT_UNLOAD = nil
end

env.__FRONTLINES_COMBAT_UNLOAD = unload
setAttribute("__fl_error", nil)
setAttribute("__fl_boxes", boxesEnabled)
setAttribute("__fl_highlights", highlightsEnabled)
setAttribute("__fl_team_check", teamCheckEnabled)
setAttribute("__fl_aim", aimEnabled)
setAttribute("__fl_aimheld", false)
setAttribute("__fl_no_recoil", noRecoilEnabled)
setAttribute("__fl_no_spread", noSpreadEnabled)
setAttribute("__fl_no_reload", noReloadEnabled)
setAttribute("__fl_infinite_ammo", infiniteAmmoEnabled)
setAttribute("__fl_ammo_mode", "pending")
setAttribute("__fl_last_ammo_block", nil)
setAttribute("__fl_triggerbot", triggerBotEnabled)
setAttribute("__fl_trigger_delay", triggerDelay)
setAttribute("__fl_hitbox", hitboxMode)
setAttribute("__fl_aimbot", aimbotEnabled)
setAttribute("__fl_aim_smooth", aimbotSmoothness)
setAttribute("__fl_rapid_fire", rapidFireEnabled)
setAttribute("__fl_multi_bullet", multiBulletEnabled)
setAttribute("__fl_high_velocity", highVelocityEnabled)
setAttribute("__fl_automatic", automaticEnabled)
setAttribute("__fl_fov_visible", fovVisible)
setAttribute("__fl_target", "")
setFovRadius(FOV_RADIUS)

local hookCallOk, hooksReady, hookError = pcall(installWeaponHooks)
setAttribute("__fl_hooks", hookCallOk and hooksReady)
if not hookCallOk or not hooksReady then
    setAttribute("__fl_error", tostring(hookError or hooksReady or "weapon hooks failed"))
end

if actor then
    connect(actor:GetAttributeChangedSignal("__fl_command"), function()
        local command = tostring(actor:GetAttribute("__fl_command") or "")
        local name, rawValue = command:match("^([^:]+):([^:]+)")
        local enabled = rawValue == "true"

        if name == "unload" then
            unload()
        elseif name == "silent" then
            aimEnabled = enabled
            targetId = nil
            updateTargetAttribute()
            setAttribute("__fl_aim", aimEnabled)
        elseif name == "fov" then
            setFovRadius(tonumber(rawValue) or FOV_RADIUS)
        elseif name == "showfov" then
            fovVisible = enabled
            setAttribute("__fl_fov_visible", fovVisible)
        elseif name == "boxes" then
            boxesEnabled = enabled
            setAttribute("__fl_boxes", boxesEnabled)
            updateBoxes()
        elseif name == "highlights" then
            highlightsEnabled = enabled
            setAttribute("__fl_highlights", highlightsEnabled)
            updateHighlights()
        elseif name == "teamcheck" then
            teamCheckEnabled = enabled
            setAttribute("__fl_team_check", teamCheckEnabled)
            updateBoxes()
            updateHighlights()
        elseif name == "norecoil" then
            noRecoilEnabled = enabled
            setAttribute("__fl_no_recoil", noRecoilEnabled)
        elseif name == "nospread" then
            noSpreadEnabled = enabled
            setAttribute("__fl_no_spread", noSpreadEnabled)
        elseif name == "noreload" then
            noReloadEnabled = enabled
            if not enabled then restoreWeaponGroup("reload") end
            setAttribute("__fl_no_reload", noReloadEnabled)
        elseif name == "infammo" then
            infiniteAmmoEnabled = enabled
            setAttribute("__fl_infinite_ammo", infiniteAmmoEnabled)
        elseif name == "triggerbot" then
            triggerBotEnabled = enabled
            setAttribute("__fl_triggerbot", triggerBotEnabled)
        elseif name == "triggerdelay" then
            triggerDelay = math.clamp((tonumber(rawValue) or 75) / 1000, 0.01, 1)
            setAttribute("__fl_trigger_delay", triggerDelay)
        elseif name == "hitbox" then
            local mode = tostring(rawValue or "head"):lower()
            if mode ~= "head" and mode ~= "body" and mode ~= "random" then
                mode = "head"
            end
            hitboxMode = mode
            setAttribute("__fl_hitbox", hitboxMode)
        elseif name == "aimbot" then
            aimbotEnabled = enabled
            setAttribute("__fl_aimbot", aimbotEnabled)
        elseif name == "aimsmooth" then
            aimbotSmoothness = math.clamp(math.floor(tonumber(rawValue) or 6), 1, 20)
            setAttribute("__fl_aim_smooth", aimbotSmoothness)
        elseif name == "rapidfire" then
            rapidFireEnabled = enabled
            if not enabled then restoreWeaponGroup("fire") end
            setAttribute("__fl_rapid_fire", rapidFireEnabled)
        elseif name == "multibullet" then
            multiBulletEnabled = enabled
            if not enabled then restoreWeaponGroup("fire") end
            setAttribute("__fl_multi_bullet", multiBulletEnabled)
        elseif name == "highvelocity" then
            highVelocityEnabled = enabled
            if not enabled then restoreWeaponGroup("fire") end
            setAttribute("__fl_high_velocity", highVelocityEnabled)
        elseif name == "automatic" then
            automaticEnabled = enabled
            if not enabled then restoreWeaponGroup("fire") end
            setAttribute("__fl_automatic", automaticEnabled)
        end
    end)
end

RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Camera.Value + 10, function()
    if not active then
        return
    end

    if aimEnabled or aimbotEnabled then
        if not targetId or not validTarget(targetId, true) then
            targetId = chooseTarget()
            updateTargetAttribute()
        end
    elseif targetId then
        targetId = nil
        updateTargetAttribute()
    end

    if noSpreadEnabled and globals.fpv_sol_spread then
        globals.fpv_sol_spread.spread = 0
    end
    if noRecoilEnabled and globals.fpv_sol_recoil then
        globals.fpv_sol_recoil.attitude_delta = Vector3.zero
    end
    applyWeaponMods()
    updateTriggerBot()
    applyAimbot()

    fovCircle.Visible = fovVisible and aimEnabled
    fovStroke.Color = targetId
        and Color3.fromRGB(255, 220, 65)
        or Color3.fromRGB(255, 175, 80)
    updateHighlights()
    updateBoxes()
end)
]==]

local function installCombatAssist()
    if not frontlinesActor then
        return false, "FRONTLINES actor not found"
    end
    if not run_on_actor then
        return false, "run_on_actor is unavailable"
    end

    frontlinesActor:SetAttribute("__fl_command", "")
    local success, errorMessage = pcall(run_on_actor, frontlinesActor, COMBAT_ASSIST_PAYLOAD)
    return success, success and nil or tostring(errorMessage)
end

local combatLoaded, combatError = installCombatAssist()
if not combatLoaded and frontlinesActor then
    frontlinesActor:SetAttribute("__fl_error", combatError)
end

local commandNumber = 0

local function sendCommand(name, value)
    if not frontlinesActor then
        return
    end

    commandNumber += 1
    frontlinesActor:SetAttribute(
        "__fl_command",
        string.format("%s:%s:%d", name, tostring(value), commandNumber)
    )
end

local function unload()
    if not running then
        return
    end

    running = false
    sendCommand("unload", true)
    state.__FRONTLINES_COMPANION_UNLOAD = nil

    if window then
        pcall(window.Destroy, window)
    end
end

state.__FRONTLINES_COMPANION_UNLOAD = unload

local libraryLoaded, Library = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/noicyreal/serotonin-ui/main/Serotonin.luau"
    ))()
end)

if not libraryLoaded then
    warn("[FRONTLINES] Serotonin UI failed to load: " .. tostring(Library))
    unload()
    return
end

window = Library.new({
    Name = "FrontlinesSerotonin",
    Title = "serotonin - FRONTLINES",
    PreviewTitle = "ESP Preview",
    ToggleKey = Enum.KeyCode.RightShift,
    Features = {Preview = true, Notifications = true},
    Theme = {
        Background = Color3.fromRGB(15, 18, 24),
        Panel = Color3.fromRGB(20, 24, 32),
        Header = Color3.fromRGB(24, 29, 38),
        Field = Color3.fromRGB(26, 31, 40),
        Border = Color3.fromRGB(55, 63, 76),
        Text = Color3.fromRGB(231, 235, 241),
        Muted = Color3.fromRGB(157, 167, 183),
        Accent = Color3.fromRGB(255, 112, 54),
        Hover = Color3.fromRGB(62, 71, 86),
    },
    Notifications = {Position = "BottomRight", Duration = 4, MaxVisible = 3},
})
window:OnDestroy(function()
    if running then unload() end
end)

local combatTab = window:AddTab("Combat")
local silentSection = combatTab:AddSection({Title = "Silent Aim", Side = "Left", Height = 210})
local aimbotSection = combatTab:AddSection({Title = "Aimbot", Side = "Left", Height = 230})
local weaponSection = combatTab:AddSection({Title = "Weapon", Side = "Right", Height = 270})

silentSection:AddToggle({
    Text = "Silent Aim",
    Default = true,
    Flag = "FL_SilentAim",
    Callback = function(enabled)
        sendCommand("silent", enabled)
    end
})

silentSection:AddDropdown({
    Text = "Hitbox",
    Options = {"Head", "Body", "Random"},
    Default = "Head",
    Flag = "FL_Hitbox",
    Callback = function(value)
        sendCommand("hitbox", tostring(value):lower())
    end
})

silentSection:AddToggle({
    Text = "Show FOV",
    Default = true,
    Flag = "FL_ShowFov",
    Callback = function(enabled)
        sendCommand("showfov", enabled)
    end
})

silentSection:AddSlider({
    Text = "FOV Radius",
    Default = 90,
    Min = 30,
    Max = 250,
    Step = 1,
    Suffix = " px",
    Flag = "FL_FovRadius",
    Callback = function(value)
        sendCommand("fov", math.floor(value + 0.5))
    end
})

aimbotSection:AddToggle({
    Text = "Aimbot",
    Default = false,
    Flag = "FL_Aimbot",
    Callback = function(enabled)
        sendCommand("aimbot", enabled)
    end
})

aimbotSection:AddSlider({
    Text = "Aimbot Smoothness",
    Default = 6,
    Min = 1,
    Max = 20,
    Step = 1,
    Flag = "FL_AimbotSmooth",
    Callback = function(value)
        sendCommand("aimsmooth", math.floor(value + 0.5))
    end
})

aimbotSection:AddToggle({
    Text = "Trigger Bot",
    Default = false,
    Flag = "FL_TriggerBot",
    Callback = function(enabled)
        sendCommand("triggerbot", enabled)
    end
})

aimbotSection:AddSlider({
    Text = "Trigger Delay",
    Default = 75,
    Min = 10,
    Max = 500,
    Step = 1,
    Suffix = " ms",
    Flag = "FL_TriggerDelay",
    Callback = function(value)
        sendCommand("triggerdelay", math.floor(value + 0.5))
    end
})

local targetLabel = aimbotSection:AddLabel("Target: none")

weaponSection:AddToggle({
    Text = "No Recoil",
    Default = true,
    Flag = "FL_NoRecoil",
    Callback = function(enabled)
        sendCommand("norecoil", enabled)
    end
})

weaponSection:AddToggle({
    Text = "No Reload",
    Default = true,
    Flag = "FL_NoReload",
    Callback = function(enabled)
        sendCommand("noreload", enabled)
    end
})

weaponSection:AddToggle({
    Text = "Infinite Ammo",
    Default = true,
    Flag = "FL_InfiniteAmmo",
    Callback = function(enabled)
        sendCommand("infammo", enabled)
    end
})

weaponSection:AddToggle({
    Text = "Rapid Fire",
    Default = false,
    Flag = "FL_RapidFire",
    Callback = function(enabled)
        sendCommand("rapidfire", enabled)
    end
})

local ballisticsSection = combatTab:AddSection({Title = "Ballistics", Side = "Right", Height = 170})

ballisticsSection:AddToggle({
    Text = "Multi Bullet",
    Default = false,
    Flag = "FL_MultiBullet",
    Callback = function(enabled)
        sendCommand("multibullet", enabled)
    end
})

ballisticsSection:AddToggle({
    Text = "High Velocity",
    Default = false,
    Flag = "FL_HighVelocity",
    Callback = function(enabled)
        sendCommand("highvelocity", enabled)
    end
})

ballisticsSection:AddToggle({
    Text = "Force Automatic",
    Default = false,
    Flag = "FL_Automatic",
    Callback = function(enabled)
        sendCommand("automatic", enabled)
    end
})

weaponSection:AddToggle({
    Text = "No Spread",
    Default = true,
    Flag = "FL_NoSpread",
    Callback = function(enabled)
        sendCommand("nospread", enabled)
    end
})

local visualsTab = window:AddTab("Visuals")
local espSection = visualsTab:AddSection({Title = "Player ESP", Side = "Left"})
local previewSection = visualsTab:AddSection({Title = "ESP Preview", Side = "Right"})
local previewState = {
    Box = true,
    Highlights = true,
    TeamCheck = true,
    Enabled = true,
    Color = Color3.fromRGB(125, 238, 245),
    TargetName = "FRONTLINES target",
}

local function updateESPPreview()
    window:UpdatePreview({
        Box = previewState.Box,
        BoxFilled = previewState.Highlights,
        Name = true,
        Health = true,
        Flags = previewState.TeamCheck,
        Details = true,
        BoxColor = previewState.Color,
        FillColor = previewState.Color,
        FillTransparency = 0.82,
        NameColor = previewState.Color,
        NameText = previewState.TargetName,
        FlagsText = previewState.TeamCheck and "ENEMY\nTEAM CHECK" or "ALL PLAYERS",
        DetailsText = "FOV TARGET\nFRONTLINES",
    })
end

espSection:AddToggle({
    Text = "Box ESP",
    Default = true,
    Flag = "FL_BoxEsp",
    Callback = function(enabled)
        previewState.Box = enabled
        sendCommand("boxes", enabled)
        updateESPPreview()
    end
})

espSection:AddToggle({
    Text = "Player Highlights",
    Default = true,
    Flag = "FL_Highlights",
    Callback = function(enabled)
        previewState.Highlights = enabled
        sendCommand("highlights", enabled)
        updateESPPreview()
    end
})

espSection:AddToggle({
    Text = "Team Check",
    Default = true,
    Flag = "FL_TeamCheck",
    Callback = function(enabled)
        previewState.TeamCheck = enabled
        sendCommand("teamcheck", enabled)
        updateESPPreview()
    end
})

previewSection:AddToggle({
    Text = "Use ESP preview",
    Flag = "FL_ESPPreview",
    Default = true,
    Callback = function(enabled)
        previewState.Enabled = enabled
        window:SetPreviewVisible(enabled)
    end,
})
previewSection:AddDropdown({
    Text = "Preview label",
    Flag = "FL_PreviewLabel",
    Options = {"Target name", "FRONTLINES"},
    Default = "Target name",
    Callback = function(value)
        previewState.TargetName = value == "FRONTLINES" and "FRONTLINES" or previewState.TargetName
        updateESPPreview()
    end,
})
previewSection:AddColorPicker({
    Text = "Preview color",
    Flag = "FL_PreviewColor",
    Default = previewState.Color,
    Callback = function(value)
        previewState.Color = value.Color
        updateESPPreview()
    end,
})
previewSection:AddButton({Text = "Reset preview model", Callback = function()
    window:SetPreviewModel(nil)
    updateESPPreview()
end})
previewSection:AddLabel("The preview mirrors ESP settings. FRONTLINES target rendering remains controlled by the actor payload.", {
    Muted = true, Wrapped = true, Height = 52,
})
updateESPPreview()

local settingsTab = window:AddTab("Settings")
local sessionSection = settingsTab:AddSection({Title = "Session", Side = "Left"})
local appearanceSection = settingsTab:AddSection({Title = "Appearance", Side = "Right"})
local engineLabel = sessionSection:AddLabel("Engine: checking...")
sessionSection:AddLabel("scriptblox.com: noic", {Muted = true})
sessionSection:AddLabel("rscripts.net: noic", {Muted = true})
sessionSection:AddLabel("robloxscripts.com: noic", {Muted = true})
sessionSection:AddLabel("haxhell.com: noic", {Muted = true})
sessionSection:AddLabel("RightShift: hide/show GUI", {Muted = true})

sessionSection:AddButton({
    Text = "Unload FRONTLINES",
    Callback = unload
})

local rainbowAccent = true
local staticAccent = Color3.fromRGB(255, 112, 54)
appearanceSection:AddDropdown({
    Text = "Accent mode",
    Flag = "FL_AccentMode",
    Options = {"Rainbow", "Static"},
    Default = "Rainbow",
    Callback = function(value)
        rainbowAccent = value == "Rainbow"
        if not rainbowAccent then window:SetAccent(staticAccent) end
    end,
})
appearanceSection:AddColorPicker({
    Text = "Static accent",
    Flag = "FL_StaticAccent",
    Default = staticAccent,
    Callback = function(value)
        staticAccent = value.Color
        if not rainbowAccent then window:SetAccent(staticAccent) end
    end,
})
appearanceSection:AddSlider({
    Text = "UI scale", Flag = "FL_UIScale", Min = 0.65, Max = 1.35,
    Step = 0.05, Decimals = 2, Default = 1,
    Callback = function(value) window:SetScale(value) end,
})
appearanceSection:AddKeybind({
    Text = "Menu key", Flag = "FL_MenuKey", Default = Enum.KeyCode.RightShift,
    Callback = function(key) window:SetToggleKey(key) end,
})
appearanceSection:AddButton({Text = "Test notification", Callback = function()
    window:Notify({Title = "FRONTLINES", Text = "Serotonin notifications are working.", Type = "Success"})
end})

local configsTab = window:AddTab("Configs")
local configSection = configsTab:AddSection({Title = "Configuration"})
configSection:AddLabel("Export or paste a Serotonin configuration below.", {Muted = true, Wrapped = true, Height = 38})
local configText = configSection:AddTextbox({Text = "Configuration JSON", Multiline = true, Height = 260})
configSection:AddButton({Text = "Export config", Callback = function()
    configText:SetValue(window:ExportConfig(), true)
    window:Notify({Title = "Config exported", Text = "The JSON is ready in the textbox.", Type = "Success"})
end})
configSection:AddButton({Text = "Import config", Callback = function()
    local ok, problem = window:ImportConfig(configText.TextBox.Text)
    window:Notify({
        Title = ok and "Config imported" or "Import failed",
        Text = ok and "FRONTLINES settings were applied." or tostring(problem),
        Type = ok and "Success" or "Error",
    })
end})

task.spawn(function()
    while running and window do
        if rainbowAccent then
            window:SetAccent(Color3.fromHSV((os.clock() * 0.12) % 1, 0.82, 1))
        end
        task.wait(0.05)
    end
end)

task.spawn(function()
    while running do
        if frontlinesActor then
            local targetName = tostring(frontlinesActor:GetAttribute("__fl_target") or "")
            local actorError = frontlinesActor:GetAttribute("__fl_error")
            targetLabel.Text = targetName ~= "" and ("Target: " .. targetName) or "Target: none"
            if window.Flags.FL_PreviewLabel == "Target name" then
                previewState.TargetName = targetName ~= "" and targetName or "FRONTLINES target"
                updateESPPreview()
            end
            engineLabel.Text = actorError and ("Engine: " .. tostring(actorError)) or "Engine: ready"
        else
            targetLabel.Text = "Target: unavailable"
            engineLabel.Text = "Engine: actor not found"
        end
        task.wait(0.25)
    end
end)

window:Notify({
    Title = combatLoaded and "FRONTLINES loaded" or "Combat helper error",
    Text = combatLoaded and "Right Shift toggles the Serotonin interface." or tostring(combatError),
    Type = combatLoaded and "Success" or "Error",
    Duration = 4,
})

print("[FRONTLINES] Loaded with Serotonin UI — press RightShift to show or hide")
