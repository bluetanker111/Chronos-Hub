--[[
    CHRONOS HUB — File 3, Part A
    Chunk 3A: Sound Presets, Extra Stats, Config Slots (disk I/O)
]]

warn("=== CHRONOS_3A START ===")

local Hub = getgenv().ChronosHub
if not Hub or not Hub._booted then
    error("[CHRONOS_3A] Chronos_1 not loaded.")
end

local HttpService = Hub.HttpService
local Log         = Hub.Log
local Store       = Hub.Store
local HAS_FS      = Hub.HAS_FS
local UI          = Hub.UI
local theme       = Hub.theme
local notify      = Hub.notify

-- ============================================================
-- [SOUND PRESETS]
-- ============================================================
local SOUND_PRESETS = {
    default = "100173184074904",
    arcade  = "4612374318",
    bell    = "4612375328",
    alarm   = "131961061",
    chime   = "6042053626",
    drop    = "5654321458",
}

Store.subscribe("SoundPreset", function(preset)
    local id = SOUND_PRESETS[preset]
    if id then Store.set("SoundId", id) end
end)

Hub.SOUND_PRESETS = SOUND_PRESETS

-- ============================================================
-- [EXTRA SESSION STATS]
-- ============================================================
local ExtraStats = {
    valueGained   = 0,
    sessionStart  = os.time(),
    bestValue     = 0,
    bestPetName   = "—",
    grabTimes     = {},   -- rolling window of recent grabs
}

local function pushGrabTime()
    local now = os.clock()
    table.insert(ExtraStats.grabTimes, now)
    -- Keep only last 60 seconds
    while #ExtraStats.grabTimes > 0
       and now - ExtraStats.grabTimes[1] > 60 do
        table.remove(ExtraStats.grabTimes, 1)
    end
end

Hub.ExtraStats = ExtraStats
Hub.pushGrabTime = pushGrabTime

-- Hook into StealSM
task.spawn(function()
    local StealSM = Hub.StealSM
    if not StealSM then return end
    local lastGrab = 0
    while true do
        task.wait(0.5)
        if StealSM.totalGrabs > lastGrab then
            local diff = StealSM.totalGrabs - lastGrab
            for _ = 1, diff do pushGrabTime() end
            lastGrab = StealSM.totalGrabs
        end
    end
end)

-- High-value grab tracker
Hub.Scheduler.add("extraStatsTrack", 2, 85, function()
    local pet = Hub.StealSM and Hub.StealSM.currentTarget
    if pet and pet.value and pet.value > ExtraStats.bestValue then
        ExtraStats.bestValue = pet.value
        ExtraStats.bestPetName = tostring(pet.name)
    end
end)

-- ============================================================
-- [CONFIG SLOTS — disk persistence]
-- ============================================================
local SLOTS_PATH = "ChronosHub_Slots.json"

local function loadSlotsFromDisk()
    if not HAS_FS then return {} end
    local ok, contents = pcall(function()
        if isfile(SLOTS_PATH) then return readfile(SLOTS_PATH) end
    end)
    if not ok or not contents or contents == "" then return {} end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(contents)
    end)
    if ok2 and type(data) == "table" then return data end
    return {}
end

local function saveSlotsToDisk(slots)
    if not HAS_FS then return end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(slots)
    end)
    if not ok or not encoded then return end
    pcall(function() writefile(SLOTS_PATH, encoded) end)
end

-- Load on boot
do
    local disk = loadSlotsFromDisk()
    if next(disk) then
        Store._data.ConfigSlots = disk
    end
end

-- Watch for changes and persist
Store.subscribe("ConfigSlots", function(slots)
    saveSlotsToDisk(slots or {})
end)

Hub.saveSlotsToDisk = saveSlotsToDisk

-- ============================================================
-- [SLOTS UI — rebuild on Extras tab if needed]
-- ============================================================
local slotsListFrame = nil

local function rebuildSlotsUI()
    if not slotsListFrame then return end
    for _, c in ipairs(slotsListFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local slots = Store.get("ConfigSlots") or {}
    for name, snap in pairs(slots) do
        local row = Instance.new("Frame", slotsListFrame)
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = theme().panel
        row.BorderSizePixel = 0
        row:SetAttribute("themeRole", "panel")
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1, -110, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 11
        lbl.TextColor3 = theme().text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl:SetAttribute("themeTextRole", "text")

        local loadBtn = Instance.new("TextButton", row)
        loadBtn.Size = UDim2.new(0, 46, 1, -6)
        loadBtn.Position = UDim2.new(1, -100, 0, 3)
        loadBtn.BorderSizePixel = 0
        loadBtn.Text = "Load"
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 10
        loadBtn.BackgroundColor3 = theme().accent
        loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
        loadBtn.MouseButton1Click:Connect(function()
            local s = (Store.get("ConfigSlots") or {})[name]
            if not s then return end
            for k, v in pairs(s) do
                if k ~= "_version" and k ~= "ConfigSlots" then
                    Store.set(k, v)
                end
            end
            notify("Slot", "Loaded: " .. name, theme().accent)
        end)

        local delBtn = Instance.new("TextButton", row)
        delBtn.Size = UDim2.new(0, 46, 1, -6)
        delBtn.Position = UDim2.new(1, -50, 0, 3)
        delBtn.BorderSizePixel = 0
        delBtn.Text = "×"
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 12
        delBtn.BackgroundColor3 = theme().danger
        delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
        delBtn.MouseButton1Click:Connect(function()
            local s = Store.get("ConfigSlots") or {}
            s[name] = nil
            Store.set("ConfigSlots", s)
            rebuildSlotsUI()
        end)
    end
end

Hub.rebuildSlotsUI = rebuildSlotsUI
Hub.attachSlotsListFrame = function(frame)
    slotsListFrame = frame
    rebuildSlotsUI()
end

Store.subscribe("ConfigSlots", function()
    task.defer(rebuildSlotsUI)
end)

Log.info("Part 9A loaded ✔")
warn("=== CHRONOS_3A END ===")
--[[
    CHRONOS HUB — File 3, Part B
    Chunk 3B: Turret ESP, Mine ESP, Zone Detection, Distance Markers
]]

warn("=== CHRONOS_3B START ===")

local Hub = getgenv().ChronosHub
if not Hub or not Hub._booted then
    error("[CHRONOS_3B] Chronos_1 not loaded.")
end

local Players       = Hub.Players
local Workspace     = Hub.Workspace
local RunService    = Hub.RunService
local LocalPlayer   = Hub.LocalPlayer
local Log           = Hub.Log
local Store         = Hub.Store
local HUI           = Hub.HUI
local Scheduler     = Hub.Scheduler
local MutColor      = Hub.MutColor
local trackConn     = Hub.trackConn

local ACCENT = Color3.fromRGB(0, 200, 115)
local DANGER = Color3.fromRGB(255, 80, 80)
local WARN   = Color3.fromRGB(255, 190, 80)

-- ============================================================
-- [TURRET ESP]
-- ============================================================
local turretFolder = HUI:FindFirstChild("ChronosTurretESP")
if not turretFolder then
    turretFolder = Instance.new("Folder")
    turretFolder.Name = "ChronosTurretESP"
    turretFolder.Parent = HUI
end

local turretTracker = {}   -- [instance] = {highlight, billboard}

Scheduler.add("turretESP", 1.5, 35, function()
    if not Store.get("TurretESPEnabled") then
        for inst, entry in pairs(turretTracker) do
            if entry.highlight then entry.highlight:Destroy() end
            if entry.billboard then entry.billboard:Destroy() end
            turretTracker[inst] = nil
        end
        return
    end

    local seen = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:match("^Sentry_%d+$") then
            seen[obj] = true
            if not turretTracker[obj] then
                local part = obj:IsA("BasePart") and obj
                          or obj:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ChronosTurretHL"
                    hl.FillColor = DANGER
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.4
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Adornee = obj
                    hl.Parent = turretFolder

                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 160, 0, 20)
                    bb.StudsOffset = Vector3.new(0, 4, 0)
                    bb.AlwaysOnTop = true
                    bb.Parent = turretFolder

                    local lbl = Instance.new("TextLabel", bb)
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 11
                    lbl.TextColor3 = DANGER
                    lbl.TextStrokeTransparency = 0.3
                    lbl.Text = "⚠ TURRET"

                    turretTracker[obj] = {highlight = hl, billboard = bb}
                end
            end
        end
    end

    for inst, entry in pairs(turretTracker) do
        if not seen[inst] or not inst.Parent then
            if entry.highlight then entry.highlight:Destroy() end
            if entry.billboard then entry.billboard:Destroy() end
            turretTracker[inst] = nil
        end
    end
end)

-- ============================================================
-- [MINE ESP]
-- ============================================================
local mineFolder = HUI:FindFirstChild("ChronosMineESP")
if not mineFolder then
    mineFolder = Instance.new("Folder")
    mineFolder.Name = "ChronosMineESP"
    mineFolder.Parent = HUI
end

local mineTracker = {}

local function isMineItem(name)
    if not name then return false end
    local low = tostring(name):lower()
    return low:find("subspace") or low:find("tripmine")
        or low:find("mine_") or low:find("mineitem")
end

Scheduler.add("mineESP", 1.5, 35, function()
    if not Store.get("MineESPEnabled") then
        for inst, entry in pairs(mineTracker) do
            if entry.highlight then entry.highlight:Destroy() end
            if entry.billboard then entry.billboard:Destroy() end
            mineTracker[inst] = nil
        end
        return
    end

    local seen = {}
    local toolFolder = Workspace:FindFirstChild("ToolsAdds")
    if toolFolder then
        for _, child in ipairs(toolFolder:GetChildren()) do
            if isMineItem(child.Name) then
                seen[child] = true
                if not mineTracker[child] then
                    local part = child:IsA("BasePart") and child
                              or child:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local hl = Instance.new("Highlight")
                        hl.Name = "ChronosMineHL"
                        hl.FillColor = Color3.fromRGB(255, 140, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.4
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Adornee = child
                        hl.Parent = mineFolder

                        local bb = Instance.new("BillboardGui")
                        bb.Size = UDim2.new(0, 160, 0, 20)
                        bb.StudsOffset = Vector3.new(0, 4, 0)
                        bb.AlwaysOnTop = true
                        bb.Parent = mineFolder

                        local lbl = Instance.new("TextLabel", bb)
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextSize = 11
                        lbl.TextColor3 = Color3.fromRGB(255, 140, 0)
                        lbl.TextStrokeTransparency = 0.3
                        lbl.Text = "💣 MINE"

                        mineTracker[child] = {highlight = hl, billboard = bb}
                    end
                end
            end
        end
    end

    for inst, entry in pairs(mineTracker) do
        if not seen[inst] or not inst.Parent then
            if entry.highlight then entry.highlight:Destroy() end
            if entry.billboard then entry.billboard:Destroy() end
            mineTracker[inst] = nil
        end
    end
end)

-- ============================================================
-- [ZONE DETECTION — Kill / Safe Zones]
-- ============================================================
local ZoneState = {killActive = false, safeActive = false, lastCheck = 0}

Scheduler.add("zoneDetect", 3, 50, function()
    if not (Store.get("KillZoneEnabled") or Store.get("SafeZoneEnabled")) then
        ZoneState.killActive = false
        ZoneState.safeActive = false
        return
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    local nearPlot = false
    for _, plot in ipairs(plots:GetChildren()) do
        local ok, pivot = pcall(function() return plot:GetPivot() end)
        if ok and pivot then
            if (root.Position - pivot.Position).Magnitude <= 40 then
                nearPlot = true
                break
            end
        end
    end

    ZoneState.killActive = nearPlot
    ZoneState.safeActive = not nearPlot

    if Store.get("KillZoneEnabled") and ZoneState.killActive then
        if not Store.get("AntiRagdoll") then
            Store.set("AntiRagdoll", true)
            Hub.notify("Kill Zone", "Anti-Ragdoll auto-ON", DANGER)
        end
        if not Store.get("AntiDie") then
            Store.set("AntiDie", true)
        end
    end
end)

Hub.ZoneState = ZoneState

-- ============================================================
-- [DISTANCE MARKERS — show distance to nearby pets]
-- ============================================================
local distGui = HUI:FindFirstChild("ChronosDistMarkers")
if not distGui then
    distGui = Instance.new("ScreenGui")
    distGui.Name = "ChronosDistMarkers"
    distGui.ResetOnSpawn = false
    distGui.DisplayOrder = 5
    distGui.Parent = HUI
end

Scheduler.add("distMarkers", 3, 40, function()
    if not Store.get("DistanceMarkers") then
        for _, c in ipairs(distGui:GetChildren()) do
            c:Destroy()
        end
        return
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, c in ipairs(distGui:GetChildren()) do
        c:Destroy()
    end

    local minVal = (Store.get("MinValueMillions") or 5) * 1e6
    local maxShow = 5
    local shown = 0

    for _, pet in ipairs(Hub.scanAllPets(minVal)) do
        if shown >= maxShow then break end
        if pet.part and pet.part.Parent then
            local dist = (root.Position - pet.part.Position).Magnitude
            if dist <= 200 then
                shown = shown + 1
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 60, 0, 18)
                bb.StudsOffset = Vector3.new(0, 6, 0)
                bb.AlwaysOnTop = true
                bb.Adornee = pet.part
                bb.Parent = distGui

                local lbl = Instance.new("TextLabel", bb)
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 0.4
                lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                lbl.Font = Enum.Font.Code
                lbl.TextSize = 10
                lbl.TextColor3 = WARN
                lbl.TextStrokeTransparency = 0.3
                lbl.Text = string.format("%dm", math.floor(dist))
            end
        end
    end
end)

-- ============================================================
-- [AUTO SCAVENGE — pick up dropped items]
-- ============================================================
Scheduler.add("autoScavenge", 2, 38, function()
    if not Store.get("AutoScavenge") then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local debris = Workspace:FindFirstChild("Debris")
    if not debris then return end

    for _, item in ipairs(debris:GetChildren()) do
        local part = item:IsA("BasePart") and item
                  or item:FindFirstChildWhichIsA("BasePart", true)
        if part and (root.Position - part.Position).Magnitude <= 20 then
            for _, d in ipairs(item:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d.Enabled then
                    local t = ((d.ActionText or "") .. " " ..
                               (d.ObjectText or "")):lower()
                    if t:find("collect") or t:find("grab")
                       or t:find("pickup") then
                        Hub.Network.FirePrompt(d)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- [UI TOGGLES for the new features — add to Extras tab]
-- ============================================================
if Hub.pExtras then
    local pExtras = Hub.pExtras
    local UI = Hub.UI
    UI.makeToggle(pExtras, "TurretESPEnabled", "Turret ESP")
    UI.makeToggle(pExtras, "MineESPEnabled", "Mine ESP")
    UI.makeToggle(pExtras, "KillZoneEnabled", "Kill Zone Auto-Protect")
    UI.makeToggle(pExtras, "SafeZoneEnabled", "Safe Zone Auto-Pause")
    UI.makeToggle(pExtras, "DistanceMarkers", "Distance Markers")
    UI.makeToggle(pExtras, "AutoScavenge", "Auto-Scavenge Drops")
end

Log.info("Part 9B loaded ✔")
warn("=== CHRONOS_3B END ===")
--[[
    CHRONOS HUB — File 3, Part C
    Chunk 3C: Incoming Tracker, Session Backup, Roam Guard,
              AP Webhook, Diagnostics, Script Reloader
]]

warn("=== CHRONOS_3C START ===")

local Hub = getgenv().ChronosHub
if not Hub or not Hub._booted then
    error("[CHRONOS_3C] Chronos_1 not loaded.")
end

local Players         = Hub.Players
local Workspace       = Hub.Workspace
local HttpService     = Hub.HttpService
local TeleportService = Hub.TeleportService
local LocalPlayer     = Hub.LocalPlayer
local PlayerGui       = Hub.PlayerGui
local PlaceId         = Hub.PlaceId
local JobId           = Hub.JobId
local Log             = Hub.Log
local Store           = Hub.Store
local HAS_FS          = Hub.HAS_FS
local HUI             = Hub.HUI
local Scheduler       = Hub.Scheduler
local trackConn       = Hub.trackConn

local ACCENT = Color3.fromRGB(0, 200, 115)
local DANGER = Color3.fromRGB(255, 80, 80)
local WARN   = Color3.fromRGB(255, 190, 80)

-- ============================================================
-- [INCOMING TRACKER — Log all steals by other players]
-- ============================================================
local IncomingLog = {}
local IncomingLogFile = "ChronosHub_Incoming.json"

-- Load previous log
if HAS_FS then
    pcall(function()
        if isfile(IncomingLogFile) then
            local contents = readfile(IncomingLogFile)
            if contents and contents ~= "" then
                local ok, data = pcall(function()
                    return HttpService:JSONDecode(contents)
                end)
                if ok and type(data) == "table" then
                    IncomingLog = data
                end
            end
        end
    end)
end

local function saveIncomingLog()
    if not HAS_FS then return end
    pcall(function()
        if #IncomingLog > 500 then
            -- Keep last 500
            local trimmed = {}
            for i = #IncomingLog - 499, #IncomingLog do
                if IncomingLog[i] then
                    table.insert(trimmed, IncomingLog[i])
                end
            end
            IncomingLog = trimmed
        end
        writefile(IncomingLogFile, HttpService:JSONEncode(IncomingLog))
    end)
end

local lastSeenStealing = {}

Scheduler.add("incomingTracker", 1.5, 63, function()
    if not Store.get("IncomingTracker") then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local stealing = p:GetAttribute("Stealing")
            local idx = p:GetAttribute("StealingIndex")
            if stealing and idx then
                local key = p.UserId .. "_" .. tostring(idx)
                if not lastSeenStealing[key] then
                    lastSeenStealing[key] = os.time()
                    table.insert(IncomingLog, {
                        t = os.time(),
                        timeStr = os.date("%H:%M:%S"),
                        player = p.DisplayName or p.Name,
                        username = p.Name,
                        userId = p.UserId,
                        petIndex = tostring(idx),
                    })
                    saveIncomingLog()
                    if Store.get("IncomingTrackerNotify") then
                        Hub.notify("Incoming Steal",
                            p.DisplayName .. " → " .. tostring(idx),
                            WARN)
                    end
                end
            end
        end
    end

    -- Cleanup old keys
    local now = os.time()
    for k, t in pairs(lastSeenStealing) do
        if now - t > 60 then
            lastSeenStealing[k] = nil
        end
    end
end)

Hub.IncomingLog = IncomingLog

-- ============================================================
-- [SESSION BACKUP]
-- ============================================================
local BACKUP_PATH = "ChronosHub_Backup.json"

function Hub.createBackup()
    if not HAS_FS then
        Hub.notify("Backup", "File system unavailable", DANGER)
        return false
    end
    local snap = Store.snapshot()
    snap._version = nil
    snap._booted = nil
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(snap)
    end)
    if not ok or not encoded then
        Hub.notify("Backup", "Encode failed", DANGER)
        return false
    end
    pcall(function() writefile(BACKUP_PATH, encoded) end)
    Hub.notify("Backup", "Session saved", ACCENT)
    return true
end

function Hub.restoreBackup()
    if not HAS_FS then return false end
    local ok, contents = pcall(function()
        if isfile(BACKUP_PATH) then return readfile(BACKUP_PATH) end
    end)
    if not ok or not contents or contents == "" then
        Hub.notify("Restore", "No backup found", WARN)
        return false
    end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(contents)
    end)
    if not ok2 or type(data) ~= "table" then
        Hub.notify("Restore", "Corrupt backup", DANGER)
        return false
    end
    for k, v in pairs(data) do
        if k ~= "_version" and k ~= "_booted" then
            Store.set(k, v)
        end
    end
    Hub.notify("Restore", "Session restored", ACCENT)
    return true
end

-- Auto-backup every 5 minutes
Scheduler.add("autoBackup", 0.01, 98, function()
    Hub.createBackup()
end)

-- ============================================================
-- [ROAM GUARD — Aggressive teleport-back]
-- ============================================================
Scheduler.add("roamGuard", 1, 41, function()
    if not Store.get("RoamGuard") then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local plot = Hub.findMyPlot()
    if not plot then return end

    local ok, pivot = pcall(function() return plot:GetPivot() end)
    if not ok or not pivot then return end

    local maxDist = Store.get("RoamGuardRadius") or 200
    if (root.Position - pivot.Position).Magnitude > maxDist then
        -- Check if we're being flung (velocity spike)
        local vel = root.AssemblyLinearVelocity.Magnitude
        if vel > 200 then
            Hub.notify("Roam Guard", "Fling detected — returning",
                DANGER)
        end
        pcall(function()
            root.CFrame = CFrame.new(pivot.Position
                + Vector3.new(0, 5, 0))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end)

-- ============================================================
-- [AP WEBHOOK — Log all AP fires to Discord]
-- ============================================================
local originalFireAP = Hub.fireAP

Hub.fireAP = function(target, command)
    local result = originalFireAP(target, command)

    if result and Store.get("APWebhookEnabled") then
        local url = Store.get("WebhookURL")
        if url and url ~= "" then
            local targetName = type(target) == "Instance"
                and target.Name or tostring(target)
            pcall(function()
                local req = http_request or request
                    or (syn and syn.request)
                if req then
                    req({
                        Url = url, Method = "POST",
                        Headers = {["Content-Type"] =
                            "application/json"},
                        Body = HttpService:JSONEncode({
                            username = "Chronos Hub — AP",
                            embeds = {{
                                title = "AP Fired",
                                description = "Command: **" .. command
                                    .. "**\nTarget: **"
                                    .. targetName .. "**",
                                color = 0x00c873,
                                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                            }},
                        }),
                    })
                end
            end)
        end
    end
    return result
end

-- ============================================================
-- [DIAGNOSTICS — /diag command shows system status]
-- ============================================================
function Hub.diagnose()
    local lines = {}
    table.insert(lines, "=== CHRONOS DIAGNOSTICS ===")
    table.insert(lines, "Session: " .. Log.session)
    table.insert(lines, "PlaceId: " .. tostring(PlaceId))
    table.insert(lines, "JobId: " .. JobId:sub(1, 8))
    table.insert(lines, "IsMobile: " .. tostring(Hub.IsMobile))
    table.insert(lines, "FS Available: " .. tostring(HAS_FS))
    table.insert(lines, "Network:")
    table.insert(lines, "  getconnections: "
        .. tostring(Hub.Network.hasGetConnections))
    table.insert(lines, "  fireproximity: "
        .. tostring(Hub.Network.hasFastFire))
    table.insert(lines, "  gethui: "
        .. tostring(Hub.Network.hasGethui))
    table.insert(lines, "Scheduler:")
    table.insert(lines, "  Jobs: " .. #Scheduler.jobs)
    table.insert(lines, "  Throttle: "
        .. math.floor((Scheduler.throttleMult or 1) * 100) .. "%")
    table.insert(lines, "Scanner:")
    table.insert(lines, "  Pets cached: "
        .. (Hub.ScanCache and Hub.ScanCache.petCount or 0))
    table.insert(lines, "Steal:")
    table.insert(lines, "  Total grabs: "
        .. (Hub.StealSM and Hub.StealSM.totalGrabs or 0))
    table.insert(lines, "  Current streak: "
        .. (Hub.StealSM and Hub.StealSM.streak or 0))
    table.insert(lines, "Data layer: "
        .. (Hub.DataCache and Hub.DataCache.Ready
            and "loaded" or "loading"))
    table.insert(lines, "Invis enabled: "
        .. tostring(Hub.invisibleStealEnabled))

    local report = table.concat(lines, "\n")
    warn(report)

    if HAS_FS then
        pcall(function()
            writefile("ChronosHub_Diagnostics.txt", report)
        end)
    end

    Hub.notify("Diagnostics", "Report written to log",
        ACCENT)
    return report
end

-- ============================================================
-- [SCRIPT RELOADER — Wipe and re-execute]
-- ============================================================
function Hub.reloadScript()
    Hub.notify("Reload", "Wiping old state...", WARN)
    task.wait(0.3)

    -- Disconnect all tracked connections
    for _, conn in ipairs(env.ChronosHub._connections or {}) do
        pcall(function() conn:Disconnect() end)
    end

    -- Destroy UI elements
    local toDestroy = {
        "ChronosHubUI", "ChronosHubToggle", "ChronosHubNotifs",
        "ChronosTracker", "ChronosBases", "ChronosStats",
        "ChronosRadar", "ChronosPerf", "ChronosTurretESP",
        "ChronosMineESP", "ChronosDistMarkers",
    }
    for _, name in ipairs(toDestroy) do
        local elem = HUI:FindFirstChild(name)
        if elem then elem:Destroy() end
    end

    -- Clear globals
    env.ChronosHub = nil
    env.ChronosHubParts = nil

    Hub.notify("Reload", "State cleared. Re-run Chronos_1.",
        ACCENT)
end

-- ============================================================
-- [UI TOGGLES for new features]
-- ============================================================
if Hub.pExtras then
    local pExtras = Hub.pExtras
    local UI = Hub.UI
    UI.makeToggle(pExtras, "IncomingTracker", "Incoming Steal Tracker")
    UI.makeToggle(pExtras, "IncomingTrackerNotify",
        "Notify on Incoming Steals")
    UI.makeToggle(pExtras, "RoamGuard", "Aggressive Roam Guard")
    UI.makeToggle(pExtras, "APWebhookEnabled", "AP Webhook Logging")
    UI.makeSlider(pExtras, "RoamGuardRadius", "Roam Guard Radius",
        100, 800, " studs")

    UI.makeButton(pExtras, "💾 Backup Session", function()
        Hub.createBackup()
    end)
    UI.makeButton(pExtras, "📥 Restore Backup", function()
        Hub.restoreBackup()
    end)
    UI.makeButton(pExtras, "🔧 Run Diagnostics", function()
        Hub.diagnose()
    end)
    UI.makeButton(pExtras, "♻ Reload Script", function()
        Hub.reloadScript()
    end)
end

-- Diagnostics keybind (F9)
trackConn(Hub.UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F9 then
        Hub.diagnose()
    end
end))

Log.info("Part 9C loaded ✔")
warn("=== CHRONOS_3C END ===")
--[[
    CHRONOS HUB — File 3, Part D
    Chunk 3D: Keybind Guide UI, Slots integration, Final Boot
]]

warn("=== CHRONOS_3D START ===")

local Hub = getgenv().ChronosHub
if not Hub or not Hub._booted then
    error("[CHRONOS_3D] Chronos_1 not loaded.")
end

local LocalPlayer      = Hub.LocalPlayer
local UserInputService = Hub.UserInputService
local Log              = Hub.Log
local Store            = Hub.Store
local HUI              = Hub.HUI
local UI               = Hub.UI
local theme            = Hub.theme
local Scheduler        = Hub.Scheduler

local ACCENT = Color3.fromRGB(0, 200, 115)
local WARN   = Color3.fromRGB(255, 190, 80)

-- ============================================================
-- [KEYBIND GUIDE UI]
-- ============================================================
local guideGui = HUI:FindFirstChild("ChronosKeybinds")
if not guideGui then
    guideGui = Instance.new("ScreenGui")
    guideGui.Name = "ChronosKeybinds"
    guideGui.ResetOnSpawn = false
    guideGui.DisplayOrder = 99998
    guideGui.Parent = HUI
end

local guideFrame = Instance.new("Frame", guideGui)
guideFrame.Size = UDim2.new(0, 260, 0, 260)
guideFrame.Position = UDim2.new(1, -280, 0, 60)
guideFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
guideFrame.BackgroundTransparency = 0.08
guideFrame.BorderSizePixel = 0
guideFrame.Visible = false
Instance.new("UICorner", guideFrame).CornerRadius = UDim.new(0, 10)

local gs = Instance.new("UIStroke", guideFrame)
gs.Color = ACCENT
gs.Thickness = 1.5
gs.Transparency = 0.3

local gTitle = Instance.new("TextLabel", guideFrame)
gTitle.Size = UDim2.new(1, -40, 0, 26)
gTitle.Position = UDim2.new(0, 12, 0, 4)
gTitle.BackgroundTransparency = 1
gTitle.Font = Enum.Font.GothamBold
gTitle.TextSize = 13
gTitle.Text = "Keybinds"
gTitle.TextColor3 = Color3.fromRGB(230, 235, 245)
gTitle.TextXAlignment = Enum.TextXAlignment.Left

local gClose = Instance.new("TextButton", guideFrame)
gClose.Size = UDim2.new(0, 24, 0, 24)
gClose.Position = UDim2.new(1, -30, 0, 4)
gClose.BackgroundTransparency = 1
gClose.Text = "×"
gClose.Font = Enum.Font.GothamBold
gClose.TextSize = 16
gClose.TextColor3 = Color3.fromRGB(180, 180, 200)
gClose.MouseButton1Click:Connect(function()
    guideFrame.Visible = false
end)

local gList = Instance.new("ScrollingFrame", guideFrame)
gList.Size = UDim2.new(1, -12, 1, -38)
gList.Position = UDim2.new(0, 6, 0, 32)
gList.BackgroundTransparency = 1
gList.BorderSizePixel = 0
gList.ScrollBarThickness = 3
gList.CanvasSize = UDim2.new(0, 0, 0, 0)
gList.AutomaticCanvasSize = Enum.AutomaticSize.Y

local keybinds = {
    {"Ctrl + P",  "Open command palette"},
    {"Ctrl + LC", "Toggle main window"},
    {"End",       "Panic (disable dangerous)"},
    {"F9",        "Run diagnostics"},
    {"PageUp",    "Toggle keybind guide"},
    {"U",         "Toggle invisible steal"},
    {"T",         "Manual teleport to target"},
    {"R",         "Drop brainrot (ragdoll)"},
    {"F",         "Instant clone"},
    {"G",         "Toggle float"},
    {"V",         "Toggle walkspeed"},
    {"Q",         "Toggle carpet speed"},
    {"Z",         "Toggle carpet boost"},
}

local layout = Instance.new("UIListLayout", gList)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder

for i, kb in ipairs(keybinds) do
    local row = Instance.new("Frame", gList)
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundColor3 = theme().panel
    row.BackgroundTransparency = 0.5
    row.BorderSizePixel = 0
    row.LayoutOrder = i
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local keyLbl = Instance.new("TextLabel", row)
    keyLbl.Size = UDim2.new(0, 80, 1, 0)
    keyLbl.Position = UDim2.new(0, 6, 0, 0)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Font = Enum.Font.Code
    keyLbl.TextSize = 11
    keyLbl.TextColor3 = ACCENT
    keyLbl.TextXAlignment = Enum.TextXAlignment.Left
    keyLbl.Text = kb[1]

    local descLbl = Instance.new("TextLabel", row)
    descLbl.Size = UDim2.new(1, -90, 1, 0)
    descLbl.Position = UDim2.new(0, 90, 0, 0)
    descLbl.BackgroundTransparency = 1
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 11
    descLbl.TextColor3 = Color3.fromRGB(200, 205, 220)
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.Text = kb[2]
end

-- Toggle keybind for the guide
Hub.UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.PageUp then
        guideFrame.Visible = not guideFrame.Visible
    end
end)

-- ============================================================
-- [SLOTS INTEGRATION — attach to Slots tab]
-- ============================================================
if Hub.pSlots and Hub.attachSlotsListFrame then
    local listFrame = Instance.new("Frame", Hub.pSlots)
    listFrame.Size = UDim2.new(1, 0, 0, 300)
    listFrame.BackgroundTransparency = 1
    Hub.attachSlotsListFrame(listFrame)
end

-- ============================================================
-- [PANIC KEY SUPPORT (double-check)]
-- ============================================================
if Hub.UserInputService then
    Hub.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if input.KeyCode == Enum.KeyCode.End then
            local saved = Store.get("PanicLastEnabled") or {}
            if next(saved) then
                if Hub.unpanic then Hub.unpanic() end
            else
                if Hub.panicButton then Hub.panicButton() end
            end
        end
    end)
end

-- ============================================================
-- [FINAL BOOT]
-- ============================================================
Log.info("=" .. string.rep("=", 50))
Log.info("  CHRONOS HUB — FULLY LOADED")
Log.info("  Files: Chronos_1, Chronos_2, Chronos_3")
Log.info("  Tabs: Steal, ESP, Protect, Render, Notify,")
Log.info("        Extras, AP, Advanced, Slots, Config, Presets")
Log.info("  Total jobs:", #Scheduler.jobs)
Log.info("  Network: getconn="
    .. tostring(Hub.Network.hasGetConnections)
    .. " fastfire=" .. tostring(Hub.Network.hasFastFire)
    .. " hui=" .. tostring(Hub.HUI ~= nil))
Log.info("=" .. string.rep("=", 50))

-- Queue on teleport if supported
pcall(function()
    if queue_on_teleport then
        queue_on_teleport([[
            -- Re-run Chronos after teleport
            -- Replace with your loadstring URL
        ]])
    end
end)

task.defer(function()
    Hub.notify("Chronos Hub",
        "Fully loaded. Press PageUp for keybinds, Ctrl+P for palette.",
        ACCENT)
end)

-- ============================================================
-- [FINAL EXPORT]
-- ============================================================
Hub.guideFrame = guideFrame
Hub.keybinds = keybinds
Hub._fullyLoaded = true

warn("=== CHRONOS_3D END ===")
warn("=============================================")
warn("=== CHRONOS HUB v4 — COMPLETE ===")
warn("=== Run order: Chronos_1, Chronos_2, Chronos_3 ===")
warn("=============================================")