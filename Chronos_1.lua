--[[
    CHRONOS HUB — File 1
    Chunk 1A-1: Header, Env, Services, Log
]]

warn("=== CHRONOS_1A-1 START ===")

local env = (getgenv and getgenv()) or _G
env.ChronosHub = env.ChronosHub or {}
env.ChronosHubParts = env.ChronosHubParts or {}

if env.ChronosHub._booted then
    warn("[CHRONOS] Cleaning old state...")
    for _, conn in ipairs(env.ChronosHub._connections or {}) do
        pcall(function() conn:Disconnect() end)
    end
    env.ChronosHub._connections = {}
end

env.ChronosHub._connections = env.ChronosHub._connections or {}
env.ChronosHub._booted = false

local function trackConn(conn)
    if not env.ChronosHub._connections then
        env.ChronosHub._connections = {}
    end
    table.insert(env.ChronosHub._connections, conn)
    return conn
end

local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local RunService           = game:GetService("RunService")
local TweenService         = game:GetService("TweenService")
local UserInputService     = game:GetService("UserInputService")
local TeleportService      = game:GetService("TeleportService")
local HttpService          = game:GetService("HttpService")
local SoundService         = game:GetService("SoundService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace            = game:GetService("Workspace")
local Lighting             = game:GetService("Lighting")
local StarterGui           = game:GetService("StarterGui")
local GuiService           = game:GetService("GuiService")
local CoreGui              = game:GetService("CoreGui")
local CollectionService    = game:GetService("CollectionService")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui", 15)
local PlaceId      = game.PlaceId
local JobId        = game.JobId
local IsMobile     = UserInputService.TouchEnabled
                     and not UserInputService.KeyboardEnabled
                     and not UserInputService.MouseEnabled

local Log = {
    buffer = {}, maxBuffer = 800, minLevel = 2,
    levels = {"[DBG]", "[INF]", "[WRN]", "[ERR]"},
    startTime = os.clock(),
    session = "CH_" .. math.random(100000, 999999),
}

local function _emit(level, ...)
    if level < Log.minLevel then return end
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    local msg = table.concat(parts, " ")
    warn(string.format("%s %s", Log.levels[level], msg))
    Log.buffer[#Log.buffer + 1] = {level = level, t = os.clock(), msg = msg}
    if #Log.buffer > Log.maxBuffer then
        table.remove(Log.buffer, 1)
    end
end

Log.debug = function(...) _emit(1, ...) end
Log.info  = function(...) _emit(2, ...) end
Log.warn  = function(...) _emit(3, ...) end
Log.error = function(...) _emit(4, ...) end

Log.export = function()
    local out = {}
    for _, e in ipairs(Log.buffer) do
        out[#out + 1] = string.format("[%.2f] %s %s",
            e.t - Log.startTime, Log.levels[e.level], e.msg)
    end
    return table.concat(out, "\n")
end

Log.info("Chronos Hub booting...")
Log.info("Session:", Log.session, "| PlaceId:", PlaceId, "| Mobile:", tostring(IsMobile))

warn("=== CHRONOS_1A-1 END ===")
--[[
    CHRONOS HUB — File 1
    Chunk 1A-2: Reactive Store
]]

warn("=== CHRONOS_1A-2 START ===")

local Store = {_data = {}, _subs = {}, _anySub = {}, _batched = false, _pending = {}}

function Store.set(key, value)
    local prev = Store._data[key]
    if prev == value then return end
    Store._data[key] = value
    if Store._batched then
        Store._pending[key] = {new = value, old = prev}
        return
    end
    Store._dispatch(key, value, prev)
end

function Store._dispatch(key, value, prev)
    local subs = Store._subs[key]
    if subs then
        for i = #subs, 1, -1 do
            local ok, err = pcall(subs[i], value, prev, key)
            if not ok then
                Log.error("Store sub failed for", key, ":", err)
                table.remove(subs, i)
            end
        end
    end
    for i = #Store._anySub, 1, -1 do
        local ok, err = pcall(Store._anySub[i], key, value, prev)
        if not ok then
            Log.error("Store wildcard failed:", err)
            table.remove(Store._anySub, i)
        end
    end
end

function Store.get(key) return Store._data[key] end

function Store.subscribe(key, callback)
    if not Store._subs[key] then Store._subs[key] = {} end
    table.insert(Store._subs[key], callback)
    pcall(callback, Store._data[key], nil, key)
end

function Store.subscribeAny(callback)
    table.insert(Store._anySub, callback)
end

function Store.snapshot()
    local out = {}
    for k, v in pairs(Store._data) do out[k] = v end
    return out
end

function Store.loadFrom(tbl)
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do Store._data[k] = v end
end

function Store.beginBatch()
    Store._batched = true
    Store._pending = {}
end

function Store.commitBatch()
    Store._batched = false
    local pending = Store._pending
    Store._pending = {}
    for key, data in pairs(pending) do
        Store._dispatch(key, data.new, data.old)
    end
end

warn("=== CHRONOS_1A-2 END ===")
--[[
    CHRONOS HUB — File 1
    Chunk 1A-3: DEFAULTS table
]]

warn("=== CHRONOS_1A-3 START ===")

local DEFAULTS = {
    _version = 4,

    -- Steal
    AutoGrab             = false,
    InstantSteal         = false,
    HoldSteal            = false,
    PredictiveGrab       = true,
    AutoUnlockDoors      = false,
    AutoLockBase         = false,
    SortMode             = "Nearest",
    GrabRadius           = 55,
    MinValueMillions     = 5,
    PerPromptCooldown    = 0.08,
    InstantGrabMode      = true,

    -- Advanced Steal
    AutoInvisDuringSteal   = false,
    AutoUnlockDuringSteal  = false,
    AutoWalkspeedOnSteal   = false,
    AutoSellThresholdM     = 0,
    AutoCloneAfterTP       = false,
    AutoBuyCarpet          = false,
    AutoBuyRadius          = 40,
    AutoBuyCooldown        = 3,
    ContinuousTP           = false,
    AutoRecoverEnabled     = true,
    AutoKickEnabled        = true,
    SafeMode               = false,
    SafeModeDelay          = 0.35,

    -- ESP / Tracking
    BrainrotESP          = false,
    StealerESP           = false,
    IncomingPredictor    = false,
    ESPInterval          = 0.5,
    ESPMaxDistance       = 500,
    ESPShowViewport      = true,

    -- Panels
    PlayerTrackerPanel   = false,
    BaseOwnershipPanel   = false,
    DistanceRadar        = false,
    StatsEnabled         = true,
    PerfOverlay          = false,
    ChatLogger           = false,

    -- Pet monitoring
    PetMoveDetection     = false,
    PetMoveWatchName     = "",

    -- Webhook
    WebhookEnabled       = false,
    WebhookURL           = "",
    WebhookMinMillions   = 100,
    WebhookCooldownSec   = 30,

    -- Protection
    AntiRagdoll          = false,
    AntiDie              = false,
    AntiFling            = false,
    AntiBodySwap         = false,
    InfiniteJump         = false,
    RemoveAccessories    = false,
    RemoveAnimations     = false,
    WalkSpeedValue       = 16,

    -- Idle / Roam
    IdleDetection        = false,
    IdleTimeoutSec       = 300,
    AntiIdleTeleport     = false,
    RoamProtection       = false,
    RoamMaxDistance      = 300,

    -- Visual cleanup
    VisualCleanup        = true,
    FPSOptimizer         = false,
    FPSDarkMode          = false,
    FPSDisableAnimations = true,

    -- Notify
    NotifyEnabled        = true,
    NotifyMinMillions    = 50,
    SoundEnabled         = false,
    SoundId              = "100173184074904",
    SoundPreset          = "default",

    -- UI
    UITheme              = "dark",
    UIScale              = 1.0,
    CurrentTab           = "Steal",
    UILocked             = true,
    UIOpacity            = 0.05,

    -- Panic
    PanicKey             = "End",
    PanicLastEnabled     = {},

    -- AP Suite
    ProximityAP          = false,
    ProximityAPRadius    = 15,
    ProximityAPCommand   = "balloon",
    ClickAPCommand       = "balloon",
    APBlacklistEnabled   = false,
    APBlacklistNames     = {},
    SpamBaseCustomize    = false,
    SpamBaseCommands     = {
        jail = true, rocket = true, inverse = true, ragdoll = true,
        jumpscare = true, tiny = true, balloon = true, morph = true,
        nightvision = true,
    },

    -- Invis Steal internals
    InvisStealAngle      = 180,
    SinkSliderValue      = 5,
    MynxxWSValue         = 28,
    MynxxWSEnabled       = false,

    -- Slots / Misc
    ConfigSlots          = {},
    OwnerWhitelist       = {},
    OwnerBlacklist       = {},

    PriorityList = {
        "headless horseman", "signore carapace", "strawberry elephant", "meowl",
        "john pork", "skibidi toilet", "elefanto frigo", "arcadragon", "griffin",
        "love love bear", "phoenix", "antonio", "dragon gingerini", "kalika bros",
        "dragon aquanini", "fishino clownino", "moby bros", "bumbatron",
        "jelly moby", "digi narwhal", "la supreme combinasion", "kraken",
        "ginger gerat", "hydra bunny", "s'more serat", "grabatron", "pancake and syrup",
        "hydra dragon cannelloni", "la casa boo", "dragon cannelloni",
    },
}

Store.loadFrom(DEFAULTS)

warn("=== CHRONOS_1A-3 END ===")
--[[
    CHRONOS HUB — File 1
    Chunk 1A-4: Config persistence
]]

warn("=== CHRONOS_1A-4 START ===")

local HAS_FS = (function()
    local ok = pcall(function() return writefile and readfile and isfile end)
    return ok and writefile and readfile and isfile
end)()

local CONFIG_PATH = "ChronosHub_Config.json"
local CONFIG_TMP  = CONFIG_PATH .. ".tmp"
local Config = {_saveScheduled = false}

local function safeDecode(str)
    local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
    if ok and type(data) == "table" then return data end
    return nil
end

local function safeEncode(tbl)
    local ok, str = pcall(function() return HttpService:JSONEncode(tbl) end)
    if ok and type(str) == "string" then return str end
    return nil
end

function Config.load()
    if not HAS_FS then return end
    local ok, contents = pcall(function()
        if isfile(CONFIG_PATH) then return readfile(CONFIG_PATH) end
    end)
    if not ok or not contents or contents == "" then return end
    local data = safeDecode(contents)
    if not data then return end
    for k, v in pairs(data) do
        if DEFAULTS[k] ~= nil then Store._data[k] = v end
    end
    Log.info("[CONFIG] Loaded from disk")
end

function Config.save()
    if not HAS_FS then return end
    if Config._saveScheduled then return end
    Config._saveScheduled = true
    task.delay(0.6, function()
        Config._saveScheduled = false
        local snap = Store.snapshot()
        snap._booted = nil
        local encoded = safeEncode(snap)
        if not encoded then return end
        pcall(function() writefile(CONFIG_TMP, encoded) end)
        pcall(function()
            writefile(CONFIG_PATH, encoded)
            if delfile then pcall(delfile, CONFIG_TMP) end
        end)
    end)
end

Config.load()
Store.subscribeAny(function() Config.save() end)

warn("=== CHRONOS_1A-4 END ===")
--[[
    CHRONOS HUB — File 1
    Chunk 1A-5: Network layer (HUI + prompt firer)
]]

warn("=== CHRONOS_1A-5 START ===")

local Network = {
    hasGetConnections  = type(getconnections) == "function",
    hasFastFire        = type(fireproximityprompt) == "function",
    hasSetIdentity     = type(setthreadidentity) == "function",
    hasGetIdentity     = type(getthreadidentity) == "function",
    hasCloneref        = type(cloneref) == "function",
    hasGethui          = type(gethui) == "function",
    hasRunConsole      = type(rconsoleprint) == "function",
}

Network.HUI = (function()
    if Network.hasGethui then
        local ok, res = pcall(gethui)
        if ok and typeof(res) == "Instance" then
            Log.info("[NET] HUI resolved via gethui()")
            return res
        end
    end
    if type(get_hidden_gui) == "function" then
        local ok, res = pcall(get_hidden_gui)
        if ok and typeof(res) == "Instance" then
            Log.info("[NET] HUI resolved via get_hidden_gui()")
            return res
        end
    end
    if Network.hasCloneref then
        local ok, res = pcall(function() return cloneref(CoreGui) end)
        if ok and typeof(res) == "Instance" then
            Log.info("[NET] HUI resolved via cloneref(CoreGui)")
            return res
        end
    end
    Log.warn("[NET] HUI fallback to CoreGui")
    return CoreGui
end)()

Network._callbacks = setmetatable({}, {__mode = "k"})

local function safeGetConnections(signal)
    if not Network.hasGetConnections then return nil end
    local ok, conns = pcall(getconnections, signal)
    if ok and type(conns) == "table" then return conns end
    return nil
end

function Network.CapturePromptCallbacks(prompt)
    if not prompt or not prompt.Parent then return nil end
    local cached = Network._callbacks[prompt]
    if cached then return cached end
    if not Network.hasGetConnections then return nil end

    local hold, trigger, holdEnd = {}, {}, {}

    local conns = safeGetConnections(prompt.PromptButtonHoldBegan)
    if conns then
        for _, c in ipairs(conns) do
            if type(c.Function) == "function" then
                table.insert(hold, c.Function)
            end
        end
    end

    local tconns = safeGetConnections(prompt.Triggered)
    if tconns then
        for _, c in ipairs(tconns) do
            if type(c.Function) == "function" then
                table.insert(trigger, c.Function)
            end
        end
    end

    local econns = safeGetConnections(prompt.PromptButtonHoldEnded)
    if econns then
        for _, c in ipairs(econns) do
            if type(c.Function) == "function" then
                table.insert(holdEnd, c.Function)
            end
        end
    end

    if #hold == 0 and #trigger == 0 and #holdEnd == 0 then return nil end

    local captured = {hold = hold, trigger = trigger, holdEnd = holdEnd}
    Network._callbacks[prompt] = captured
    return captured
end

function Network.FirePrompt(prompt)
    if not prompt or not prompt.Parent then return false, "dead" end
    if not prompt.Enabled then return false, "disabled" end

    local cbs = Network.CapturePromptCallbacks(prompt)
    if cbs then
        for _, fn in ipairs(cbs.hold)    do task.spawn(fn) end
        for _, fn in ipairs(cbs.holdEnd) do task.spawn(fn) end
        for _, fn in ipairs(cbs.trigger) do task.spawn(fn) end
        return true, "callback"
    end

    if Network.hasFastFire then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then return true, "fastfire" end
    end

    local duration = math.min(prompt.HoldDuration or 1.5, 2.0) + 0.05
    local began = pcall(function() prompt:InputHoldBegin() end)
    if not began then return false, "no_method" end
    task.wait(duration)
    pcall(function() prompt:InputHoldEnd() end)
    return true, "hold"
end

function Network.WithElevated(fn, level)
    level = level or 8
    if not Network.hasSetIdentity or not Network.hasGetIdentity then
        return fn()
    end
    local prev = nil
    pcall(function() prev = getthreadidentity() end)
    if prev == level then return fn() end
    pcall(setthreadidentity, level)
    local ok, res = pcall(fn)
    if prev then pcall(setthreadidentity, prev) end
    if not ok then
        Log.error("[NET] Elevated call failed:", res)
        return nil
    end
    return res
end

function Network.ResolveRemote(path, class)
    class = class or "RemoteEvent"
    return Network.WithElevated(function()
        local cur = ReplicatedStorage
        for part in string.gmatch(path, "[^/]+") do
            cur = cur and cur:FindFirstChild(part)
            if not cur then return nil end
        end
        if cur and cur:IsA(class) then return cur end
        return nil
    end)
end

Log.info("[NET] Layer ready | getconn:", Network.hasGetConnections,
    "| fastfire:", Network.hasFastFire, "| hui:", Network.HUI ~= nil)

warn("=== CHRONOS_1A-5 END ===")
--[[
    CHRONOS HUB — File 1
    Chunk 1A-6: Export Part A
]]

warn("=== CHRONOS_1A-6 START ===")

env.ChronosHub = {
    -- Preserved from 1A-1
    _connections = env.ChronosHub._connections,
    -- Services
    Players = Players,
    ReplicatedStorage = ReplicatedStorage,
    RunService = RunService,
    TweenService = TweenService,
    UserInputService = UserInputService,
    TeleportService = TeleportService,
    HttpService = HttpService,
    SoundService = SoundService,
    ContextActionService = ContextActionService,
    Workspace = Workspace,
    Lighting = Lighting,
    StarterGui = StarterGui,
    GuiService = GuiService,
    CoreGui = CoreGui,
    CollectionService = CollectionService,

    -- Player
    LocalPlayer = LocalPlayer,
    PlayerGui = PlayerGui,
    PlaceId = PlaceId,
    JobId = JobId,
    IsMobile = IsMobile,

    -- Core
    Log = Log,
    Store = Store,
    Config = Config,
    DEFAULTS = DEFAULTS,
    HAS_FS = HAS_FS,

    -- Network
    Network = Network,
    HUI = Network.HUI,

    -- Utility
    trackConn = trackConn,

    -- Populated by Part B
    invisibleStealEnabled = false,
    _InvisState = nil,
    _WSState = nil,
}

env.ChronosHub._booted = true

Log.info("Part 1A loaded ✔")
warn("=== CHRONOS_1A-6 END ===")
warn("=== CHRONOS_1 PART A COMPLETE ===")
--[[
    CHRONOS HUB — File 1, Part B
    Chunk 1B-1: Scheduler
]]

warn("=== CHRONOS_1B-1 START ===")
do

local Hub = getgenv().ChronosHub
if not Hub or not Hub._booted then
    error("[CHRONOS_1B] Part A not loaded.")
end

local RunService = Hub.RunService
local Log        = Hub.Log
local trackConn  = Hub.trackConn

local Scheduler = {
    jobs = {}, maxJobs = 512, fpsSamples = {},
    throttleMult = 1.0, FRAME_BUDGET = 0.0035,
    consecutiveSlow = 0, consecutiveFast = 0,
}

function Scheduler.add(name, rateHz, priority, callback)
    if #Scheduler.jobs >= Scheduler.maxJobs then return end
    for i, j in ipairs(Scheduler.jobs) do
        if j.name == name then table.remove(Scheduler.jobs, i) break end
    end
    table.insert(Scheduler.jobs, {
        name = name, rateHz = rateHz,
        interval = 1 / math.max(rateHz, 0.01),
        priority = priority or 50, lastRun = 0,
        callback = callback, failCount = 0, runCount = 0, avgCost = 0,
    })
    table.sort(Scheduler.jobs, function(a, b) return a.priority < b.priority end)
end

function Scheduler.remove(name)
    for i, j in ipairs(Scheduler.jobs) do
        if j.name == name then table.remove(Scheduler.jobs, i) return true end
    end
    return false
end

function Scheduler.setRate(name, rateHz)
    for _, j in ipairs(Scheduler.jobs) do
        if j.name == name then
            j.rateHz = rateHz
            j.interval = 1 / math.max(rateHz, 0.01)
            return true
        end
    end
    return false
end

trackConn(RunService.Heartbeat:Connect(function(dt)
    local fps = 1 / math.max(dt, 0.001)
    Scheduler.fpsSamples[#Scheduler.fpsSamples + 1] = fps
    if #Scheduler.fpsSamples > 90 then
        table.remove(Scheduler.fpsSamples, 1)
    end

    if #Scheduler.fpsSamples >= 45 then
        local sum = 0
        for _, f in ipairs(Scheduler.fpsSamples) do sum = sum + f end
        local avg = sum / #Scheduler.fpsSamples

        if avg < 40 then
            Scheduler.consecutiveSlow = Scheduler.consecutiveSlow + 1
            Scheduler.consecutiveFast = 0
            if Scheduler.consecutiveSlow >= 5 then
                Scheduler.throttleMult = math.max(0.35, Scheduler.throttleMult * 0.97)
            end
        elseif avg > 55 then
            Scheduler.consecutiveFast = Scheduler.consecutiveFast + 1
            Scheduler.consecutiveSlow = 0
            if Scheduler.consecutiveFast >= 8 then
                Scheduler.throttleMult = math.min(1.0, Scheduler.throttleMult * 1.015)
            end
        end
    end
end))

trackConn(RunService.Heartbeat:Connect(function()
    local now = os.clock()
    local budget = Scheduler.FRAME_BUDGET * Scheduler.throttleMult
    local iterStart = now

    for _, job in ipairs(Scheduler.jobs) do
        local interval = job.interval / Scheduler.throttleMult
        if now - job.lastRun >= interval then
            local t0 = os.clock()
            local ok, err = pcall(job.callback)
            local cost = os.clock() - t0

            if not ok then
                Log.error("[SCHED]", job.name, "failed:", err)
                job.failCount = job.failCount + 1
                if job.failCount > 15 then
                    job.rateHz = 0
                    job.interval = math.huge
                end
            else
                job.failCount = 0
                job.runCount = job.runCount + 1
                job.avgCost = job.avgCost == 0
                    and cost or (job.avgCost * 0.85 + cost * 0.15)
            end

            job.lastRun = now
            if os.clock() - iterStart >= budget then break end
        end
    end
end))

Hub.Scheduler = Scheduler
end
warn("=== CHRONOS_1B-1 END ===")
--[[
    CHRONOS HUB — File 1, Part B
    Chunk 1B-2: SegmentCache + Mutation Colors
]]

warn("=== CHRONOS_1B-2 START ===")
do

local Hub = getgenv().ChronosHub

local SegmentCache = {
    entries = {}, ttl = 0.25, maxSize = 1024,
    hits = 0, misses = 0,
}

local function _q(v) return math.floor(v + 0.5) end

local function _hashSegment(a, b)
    return string.format("%d,%d,%d_%d,%d,%d",
        _q(a.X), _q(a.Y), _q(a.Z),
        _q(b.X), _q(b.Y), _q(b.Z))
end

function SegmentCache.check(a, b)
    local key = _hashSegment(a, b)
    local e = SegmentCache.entries[key]
    if e and os.clock() - e.t < SegmentCache.ttl then
        SegmentCache.hits = SegmentCache.hits + 1
        return e.result, key
    end
    SegmentCache.misses = SegmentCache.misses + 1
    return nil, key
end

function SegmentCache.store(key, result)
    if not key then return end
    if #SegmentCache.entries > SegmentCache.maxSize then
        local keys = {}
        for k in pairs(SegmentCache.entries) do
            keys[#keys + 1] = k
        end
        table.sort(keys, function(x, y)
            return SegmentCache.entries[x].t < SegmentCache.entries[y].t
        end)
        for i = 1, math.floor(#keys * 0.25) do
            SegmentCache.entries[keys[i]] = nil
        end
    end
    SegmentCache.entries[key] = {result = result, t = os.clock()}
end

function SegmentCache.clear()
    SegmentCache.entries = {}
end

-- [MUTATION COLORS]
local MutColor = {
    Cursed      = Color3.fromRGB(255, 50, 50),
    Gold        = Color3.fromRGB(255, 215, 0),
    Diamond     = Color3.fromRGB(0, 255, 255),
    YinYang     = Color3.fromRGB(220, 220, 220),
    Rainbow     = Color3.fromRGB(255, 100, 200),
    Lava        = Color3.fromRGB(255, 100, 20),
    Crystal     = Color3.fromRGB(228, 175, 242),
    Candy       = Color3.fromRGB(255, 105, 180),
    Bloodrot    = Color3.fromRGB(139, 0, 0),
    Radioactive = Color3.fromRGB(0, 255, 0),
    Divine      = Color3.fromRGB(255, 255, 150),
    Galaxy      = Color3.fromRGB(155, 50, 255),
    Cyber       = Color3.fromRGB(50, 180, 255),
    Phantom     = Color3.fromRGB(150, 150, 150),
    Eclipse     = Color3.fromRGB(30, 30, 30),
}

local RAINBOW_HEX = {
    "rgb(255,0,0)", "rgb(255,127,0)", "rgb(255,255,0)",
    "rgb(0,255,0)", "rgb(0,150,255)", "rgb(75,0,255)", "rgb(200,0,255)",
}

local function fmtMutation(mutation, petName)
    if not mutation or mutation == "None" or mutation == "" then
        return petName
    end

    if mutation == "Rainbow" then
        local up = mutation:upper()
        local out = {}
        for i = 1, #up do
            out[#out + 1] = string.format("<font color='%s'>%s</font>",
                RAINBOW_HEX[(i - 1) % #RAINBOW_HEX + 1], up:sub(i, i))
        end
        return table.concat(out) .. " " .. petName
    end

    if mutation == "YinYang" or mutation == "Yin Yang" then
        return "<font color='rgb(30,30,30)'>Yin</font> <font color='rgb(255,255,255)'>Yang</font> " .. petName
    end

    if mutation == "Candy" then
        local n = #mutation
        local out = {}
        for i = 1, n do
            local t = n > 1 and (i - 1) / (n - 1) or 0
            local r = math.floor(255 - 55 * t)
            local g = math.floor(190 - 30 * t)
            local b = math.floor(230 + 25 * t)
            out[#out + 1] = string.format(
                "<font color='rgb(%d,%d,%d)'>%s</font>",
                r, g, b, mutation:sub(i, i))
        end
        return table.concat(out) .. " " .. petName
    end

    local c = MutColor[mutation]
    if c then
        local hex = string.format("rgb(%d,%d,%d)",
            c.R * 255, c.G * 255, c.B * 255)
        local tag = string.format("<font color='%s'>%s</font>", hex, mutation)
        if mutation == "Phantom" then
            tag = "<stroke color='#000000' thickness='2'>" .. tag .. "</stroke>"
        end
        return tag .. " " .. petName
    end

    return mutation .. " " .. petName
end

Hub.SegmentCache = SegmentCache
Hub.MutColor = MutColor
Hub.fmtMutation = fmtMutation

end
warn("=== CHRONOS_1B-2 END ===")
--[[
    CHRONOS HUB — File 1, Part B
    Chunk 1B-3: Data Layer + Value Calc + Scanner
]]

warn("=== CHRONOS_1B-3 START ===")
do

local Hub = getgenv().ChronosHub
local ReplicatedStorage = Hub.ReplicatedStorage
local Workspace         = Hub.Workspace
local HttpService       = Hub.HttpService
local Log               = Hub.Log
local Store             = Hub.Store
local trackConn         = Hub.trackConn

-- [DATA LAYER]
local DataCache = {
    Animals = nil, Mutations = nil, Traits = nil,
    Ready = false, attempts = 0,
}

local function tryRequire(inst)
    if not inst then return nil end
    local ok, res = pcall(require, inst)
    if ok and type(res) == "table" then return res end
    return nil
end

local function findDataFolder()
    for _, name in ipairs({"Datas", "Data", "Modules", "GameData"}) do
        local f = ReplicatedStorage:FindFirstChild(name)
        if f then return f end
    end
    return nil
end

function DataCache.init()
    if DataCache.Ready then return true end
    DataCache.attempts = DataCache.attempts + 1
    local folder = findDataFolder()
    if not folder then return false end
    DataCache.Animals   = tryRequire(folder:FindFirstChild("Animals"))
    DataCache.Mutations = tryRequire(folder:FindFirstChild("Mutations"))
    DataCache.Traits    = tryRequire(folder:FindFirstChild("Traits"))
    DataCache.Ready = DataCache.Animals ~= nil
    if DataCache.Ready then
        Log.info("[DATA] Loaded at attempt", DataCache.attempts)
    end
    return DataCache.Ready
end

task.spawn(function()
    for i = 1, 30 do
        if DataCache.init() then break end
        task.wait(0.5)
    end
end)

-- [VALUE CALC]
local function computeValue(itemIndex, mutationType, traitsList)
    if not DataCache.Ready then return 1000000 end
    local entry = DataCache.Animals[itemIndex]
    if not entry then return 1000000 end

    local base = entry.Generation
              or entry.Value
              or entry.Price
              or entry.Income
              or 0

    local modifier = 1.0

    if mutationType and mutationType ~= "None" and mutationType ~= "" then
        local m = DataCache.Mutations and DataCache.Mutations[mutationType]
        if m and type(m) == "table" then
            modifier = modifier + (m.Modifier or 0)
        end
    end

    local sleepy = false
    if type(traitsList) == "table" then
        for trait in pairs(traitsList) do
            local t = DataCache.Traits and DataCache.Traits[trait]
            if t then
                if trait == "Sleepy" then sleepy = true
                else modifier = modifier + (t.MultiplierModifier or 0) end
            end
        end
    end

    local val = base * modifier
    if sleepy then val = val * 0.5 end
    return math.round(val)
end

-- [SCANNER]
local ScanCache = {
    results = {}, lastFullScan = 0, interval = 0.65,
    dirty = true, petCount = 0,
}

task.spawn(function()
    local plots = Workspace:FindFirstChild("Plots")
               or Workspace:WaitForChild("Plots", 20)
    if not plots then return end
    local function mark() ScanCache.dirty = true end
    trackConn(plots.DescendantAdded:Connect(mark))
    trackConn(plots.DescendantRemoving:Connect(mark))
end)

local function readPetAttributes(petModel)
    local idx = petModel:GetAttribute("Index")
             or petModel:GetAttribute("PetIndex")
             or petModel.Name
    local mut = petModel:GetAttribute("Mutation")
    local traits = petModel:GetAttribute("Traits")
    if type(traits) == "string" then
        local ok, parsed = pcall(function()
            return HttpService:JSONDecode(traits)
        end)
        if ok then traits = parsed end
    end
    return idx, mut, traits
end

local function readPlotOwner(plot)
    local owner = plot:GetAttribute("Owner")
    if owner then return owner end
    local sign = plot:FindFirstChild("PlotSign")
    local sGui = sign and sign:FindFirstChildWhichIsA("SurfaceGui", true)
    local lbl  = sGui and sGui:FindFirstChildWhichIsA("TextLabel", true)
    if lbl and lbl.Text then
        return lbl.Text:match("^([^']+)'s") or lbl.Text
    end
    return nil
end

local function findPetBasePart(petModel)
    if petModel:IsA("BasePart") then return petModel end
    return petModel:FindFirstChild("HumanoidRootPart")
        or petModel:FindFirstChild("Head")
        or petModel.PrimaryPart
        or petModel:FindFirstChildWhichIsA("BasePart", true)
end
local function scanAllPets(minValue)
    minValue = minValue or 0
    local now = os.clock()

    if not ScanCache.dirty
       and now - ScanCache.lastFullScan < ScanCache.interval then
        if minValue <= 0 then return ScanCache.results end
        local filtered = {}
        for _, p in ipairs(ScanCache.results) do
            if p.value >= minValue then
                filtered[#filtered + 1] = p
            end
        end
        return filtered
    end

    local results = {}
    local seen = {}

    local function addBrainrot(model, brainrotName, plotName, slotId)
        if not model or not brainrotName or brainrotName == "" then return end
        if seen[model] then return end
        seen[model] = true

        local mut = model:GetAttribute("Mutation")
        if not mut or mut == "" then mut = "None" end
        local traits = model:GetAttribute("Traits")

        local val = computeValue(brainrotName, mut, traits)
        if val < minValue then return end

        local part = model:FindFirstChild("RootPart")
            or model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("Head")
            or model.PrimaryPart
            or model:FindFirstChildWhichIsA("BasePart", true)

        if not part then return end

        local uid = plotName and (plotName .. "_" .. tostring(slotId))
                    or ("ws_" .. tostring(model))

        results[#results + 1] = {
            name = brainrotName,
            value = val,
            mutation = mut,
            traits = traits,
            owner = nil,
            plot = plotName,
            slot = slotId,
            part = part,
            model = model,
            uid = uid,
        }
    end

    -- 1. UUID-named Models directly in Workspace (placed brainrots)
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") then
            local idx = child:GetAttribute("Index")
            if idx and idx ~= "" then
                addBrainrot(child, idx, nil, nil)
            end
        end
    end

    -- 2. RenderedMovingAnimals (being carried / stolen)
    local rma = Workspace:FindFirstChild("RenderedMovingAnimals")
    if rma then
        for _, child in ipairs(rma:GetChildren()) do
            if child:IsA("Model") and child.Name ~= "" then
                addBrainrot(child, child.Name, nil, nil)
            end
        end
    end

    -- 3. Inside Plots (in case any are placed there)
    local plots = Workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            for _, d in ipairs(plot:GetDescendants()) do
                if d:IsA("Model") then
                    local idx = d:GetAttribute("Index")
                    if idx and idx ~= "" then
                        addBrainrot(d, idx, plot.Name, d.Name)
                    end
                end
            end
        end
    end

    table.sort(results, function(a, b) return a.value > b.value end)
    ScanCache.results = results
    ScanCache.dirty = false
    ScanCache.lastFullScan = now
    ScanCache.petCount = #results
    return results
end
Hub.DataCache = DataCache
Hub.computeValue = computeValue
Hub.scanAllPets = scanAllPets
Hub.ScanCache = ScanCache

end
warn("=== CHRONOS_1B-3 END ===")
--[[
    CHRONOS HUB — File 1, Part B
    Chunk 1B-4: Owner filters, Prompt activator, My plot,
                Invisible Steal, TP Highest, WalkSpeed, Export
]]

warn("=== CHRONOS_1B-4 START ===")
do

local Hub = getgenv().ChronosHub
local Workspace    = Hub.Workspace
local RunService   = Hub.RunService
local LocalPlayer  = Hub.LocalPlayer
local Log          = Hub.Log
local Store        = Hub.Store
local Network      = Hub.Network
local Scheduler    = Hub.Scheduler
local trackConn    = Hub.trackConn

-- [OWNER FILTERS]
local function ownerPassesFilters(ownerName)
    if not ownerName then return true end
    local lower = tostring(ownerName):lower()
    local wl = Store.get("OwnerWhitelist")
    local bl = Store.get("OwnerBlacklist")
    if type(wl) == "table" and #wl > 0 then
        for _, n in ipairs(wl) do
            if lower:find(tostring(n):lower(), 1, true) then return true end
        end
        return false
    end
    if type(bl) == "table" then
        for _, n in ipairs(bl) do
            if lower:find(tostring(n):lower(), 1, true) then return false end
        end
    end
    return true
end

-- [PROMPT ACTIVATOR]
local _promptCooldowns = {}
local function activatePrompt(prompt, holdTime)
    if not prompt or not prompt.Enabled then return false, "disabled" end
    local now = os.clock()
    local last = _promptCooldowns[prompt] or 0
    if now - last < Store.get("PerPromptCooldown") then
        return false, "cooldown"
    end
    _promptCooldowns[prompt] = now
    return Network.FirePrompt(prompt)
end

Scheduler.add("promptCooldownPrune", 0.03, 90, function()
    local now = os.clock()
    for prompt, t in pairs(_promptCooldowns) do
        if now - t > 90 or not prompt.Parent then
            _promptCooldowns[prompt] = nil
        end
    end
end)

-- [MY PLOT]
local _myPlotCache = {plot = nil, t = 0}
local function findMyPlot()
    if _myPlotCache.plot and _myPlotCache.plot.Parent
       and os.clock() - _myPlotCache.t < 2 then
        return _myPlotCache.plot
    end
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local myName = LocalPlayer.Name:lower()
    local myDisp = (LocalPlayer.DisplayName or ""):lower()
    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:GetAttribute("Owner")
        if owner and owner == LocalPlayer.Name then
            _myPlotCache.plot = plot
            _myPlotCache.t = os.clock()
            return plot
        end
        local sign = plot:FindFirstChild("PlotSign")
        local sGui = sign and sign:FindFirstChildWhichIsA("SurfaceGui", true)
        local lbl = sGui and sGui:FindFirstChildWhichIsA("TextLabel", true)
        if lbl and lbl.Text then
            local t = lbl.Text:lower()
            if t:find(myName, 1, true)
               or (myDisp ~= "" and t:find(myDisp, 1, true)) then
                _myPlotCache.plot = plot
                _myPlotCache.t = os.clock()
                return plot
            end
        end
    end
    return nil
end

local function invalidateMyPlot()
    _myPlotCache.plot = nil
    _myPlotCache.t = 0
end

-- [INVISIBLE STEAL SYSTEM]
local InvisState = {
    enabled = false, clone = nil, rootPart = nil, hipHeight = nil,
    tracks = {}, connections = {}, lastToggle = 0,
    applying = false, cancelPending = false,
    recoveryBusy = false, lastGoodPos = nil,
}

local INVIS_ANIM_ID = "rbxassetid://18537363391"

local function cleanupInvis()
    if InvisState.connections then
        for _, c in ipairs(InvisState.connections) do
            pcall(function() c:Disconnect() end)
        end
        InvisState.connections = {}
    end
    for _, t in ipairs(InvisState.tracks) do
        pcall(function() t:Stop(0) end)
        pcall(function() t:Destroy() end)
    end
    InvisState.tracks = {}
    if InvisState.clone then
        pcall(function() InvisState.clone:Destroy() end)
        InvisState.clone = nil
    end
    InvisState.rootPart = nil
    InvisState.hipHeight = nil
end

local function applyInvisRig()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    InvisState.hipHeight = hum.HipHeight
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp.Parent then return false end

    for _, c in ipairs(hrp:GetChildren()) do
        if c:IsA("Attachment") or c:IsA("Beam") then
            pcall(function() c:Destroy() end)
        end
    end

    local Model = Instance.new("Model")
    Model.Parent = game
    char.Parent = Model

    InvisState.clone = hrp:Clone()
    InvisState.clone.Parent = char
    hrp.Parent = Workspace.CurrentCamera
    InvisState.clone.CFrame = hrp.CFrame
    char.PrimaryPart = InvisState.clone
    char.Parent = Workspace

    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Weld") or d:IsA("Motor6D") then
            if d.Part0 == hrp then d.Part0 = InvisState.clone end
            if d.Part1 == hrp then d.Part1 = InvisState.clone end
        end
    end
    Model:Destroy()
    InvisState.rootPart = hrp
    return true
end

local function restoreInvisRig()
    local char = LocalPlayer.Character
    if not InvisState.rootPart
       or not InvisState.rootPart:IsDescendantOf(Workspace.CurrentCamera) then
        return
    end
    if not char then return end

    local Model = Instance.new("Model")
    Model.Parent = game
    char.Parent = Model
    InvisState.rootPart.Parent = char
    char.PrimaryPart = InvisState.rootPart
    char.Parent = Workspace
    InvisState.rootPart.CanCollide = true

    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Weld") or d:IsA("Motor6D") then
            if d.Part0 == InvisState.clone then d.Part0 = InvisState.rootPart end
            if d.Part1 == InvisState.clone then d.Part1 = InvisState.rootPart end
        end
    end
    Model:Destroy()

    if InvisState.clone then
        local cf = InvisState.clone.CFrame
        InvisState.clone:Destroy()
        InvisState.clone = nil
        InvisState.rootPart.CFrame = cf
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and InvisState.hipHeight then
        hum.HipHeight = InvisState.hipHeight
    end
end

local function playInvisAnim()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = INVIS_ANIM_ID
    local track = (hum:FindFirstChildOfClass("Animator")
                   or Instance.new("Animator", hum)):LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    track:Play(0, 1, 0)
    anim:Destroy()
    table.insert(InvisState.tracks, track)
    track.Stopped:Connect(function()
        if InvisState.enabled then playInvisAnim() end
    end)
    task.defer(function()
        track.TimePosition = 0.75
        task.delay(0.2, function()
            pcall(function() track:AdjustSpeed(0) end)
        end)
    end)
end

local function applyInvisBody()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 or not InvisState.rootPart then return end
    local primary = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
    if not primary then return end
    local sink = (Store.get("SinkSliderValue") or 5) * 0.5
    local angle = Store.get("InvisStealAngle") or 180
    local base = primary.CFrame - Vector3.new(0, sink, 0)
    InvisState.rootPart.CFrame = base * CFrame.Angles(math.rad(angle), 0, 0)
    InvisState.rootPart.AssemblyLinearVelocity = primary.AssemblyLinearVelocity
    InvisState.rootPart.CanCollide = false
    InvisState.lastGoodPos = InvisState.rootPart.Position
end

local function connectInvisLoop()
    local conn = RunService.PreSimulation:Connect(function()
        if not InvisState.enabled then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 or not InvisState.rootPart then return end

        for _, c in ipairs(InvisState.rootPart:GetChildren()) do
            if c:IsA("Attachment") or c:IsA("Beam") then
                pcall(function() c:Destroy() end)
            end
        end

        if InvisState.lastGoodPos then
            local dist = (InvisState.rootPart.Position
                       - InvisState.lastGoodPos).Magnitude
            if dist > 25 and not InvisState.recoveryBusy
               and Store.get("AutoRecoverEnabled") then
                InvisState.recoveryBusy = true
                Hub.notify("RECOVER", "Lagback detected",
                    Color3.fromRGB(255, 190, 80))
                task.spawn(function()
                    task.wait(0.4)
                    InvisState.recoveryBusy = false
                end)
            end
        end

        applyInvisBody()
    end)
    table.insert(InvisState.connections, conn)
end

function Hub.enableInvisibleSteal()
    if InvisState.enabled then return end
    if os.clock() - InvisState.lastToggle < 0.3 then return end
    InvisState.lastToggle = os.clock()

    InvisState.enabled = true
    Hub.invisibleStealEnabled = true

    if not applyInvisRig() then
        InvisState.enabled = false
        Hub.invisibleStealEnabled = false
        return
    end

    task.wait(0.05)
    playInvisAnim()
    connectInvisLoop()

    if Store.get("MynxxWSEnabled") and Hub.setWalkSpeedEnabled then
        task.delay(1, function()
            if InvisState.enabled and Hub.setWalkSpeedEnabled then
                Hub.setWalkSpeedEnabled(true)
            end
        end)
    end
end

function Hub.disableInvisibleSteal()
    if not InvisState.enabled then return end
    if os.clock() - InvisState.lastToggle < 0.3 then return end
    InvisState.lastToggle = os.clock()

    InvisState.enabled = false
    Hub.invisibleStealEnabled = false

    for _, c in ipairs(InvisState.connections) do
        pcall(function() c:Disconnect() end)
    end
    InvisState.connections = {}

    for _, t in ipairs(InvisState.tracks) do
        pcall(function() t:Stop(0) end)
    end
    InvisState.tracks = {}

    restoreInvisRig()
    cleanupInvis()

    if Hub.setWalkSpeedEnabled then
        pcall(Hub.setWalkSpeedEnabled, false)
    end
end

function Hub.toggleInvisibleSteal()
    if InvisState.enabled then Hub.disableInvisibleSteal()
    else Hub.enableInvisibleSteal() end
end

trackConn(LocalPlayer.CharacterAdded:Connect(function()
    if InvisState.enabled then
        InvisState.enabled = false
        Hub.invisibleStealEnabled = false
        cleanupInvis()
    end
end))

Hub.invisibleStealEnabled = false
Hub._InvisState = InvisState

-- [TELEPORT TO HIGHEST]
local TPHighState = {lastTP = 0, cooldown = 0.6}

function Hub.TeleportToHighest()
    if os.clock() - TPHighState.lastTP < TPHighState.cooldown then
        return false
    end
    TPHighState.lastTP = os.clock()

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    local minVal = (Store.get("MinValueMillions") or 5) * 1e6
    local best, bestDist = nil, math.huge
    for _, pet in ipairs(Hub.scanAllPets(minVal)) do
        if pet.part and pet.part.Parent
           and ownerPassesFilters(pet.owner) then
            local d = (root.Position - pet.part.Position).Magnitude
            if d < bestDist then best = pet bestDist = d end
        end
    end

    if not best then return false end

    local targetPos = best.part.Position
    local floorY = targetPos.Y > 23 and 21
                or targetPos.Y > 10 and 14.5 or -4
    local dest = Vector3.new(targetPos.X, floorY, targetPos.Z)

    pcall(function()
        for _, toolName in ipairs({
            "Flying Carpet", "Waverider", "Witch's Broom",
            "Santa's Sleigh", "Cupid's Wings",
        }) do
            local tool = LocalPlayer.Backpack:FindFirstChild(toolName)
            if tool then hum:EquipTool(tool) break end
        end
    end)

    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = CFrame.new(dest)

    if InvisState.lastGoodPos then
        InvisState.lastGoodPos = dest
    end
    return true
end

-- [WALKSPEED HELPER]
local WSState = {enabled = false, connection = nil}

function Hub.setWalkSpeedEnabled(enabled)
    WSState.enabled = enabled
    if WSState.connection then
        pcall(function() WSState.connection:Disconnect() end)
        WSState.connection = nil
    end
    if not enabled then return end

    WSState.connection = RunService.Heartbeat:Connect(function(dt)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then return end
        local target = tonumber(Store.get("MynxxWSValue") or 28)
        if hum.MoveDirection.Magnitude > 0
           and target > hum.WalkSpeed then
            root.CFrame = root.CFrame
                + hum.MoveDirection * (target - hum.WalkSpeed) * dt
        end
    end)
end

Hub._WSState = WSState

-- [EXPORT]
Hub.Scheduler = Scheduler
Hub.SegmentCache = Hub.SegmentCache or Hub.SegmentCache
Hub.ownerPassesFilters = ownerPassesFilters
Hub.activatePrompt = activatePrompt
Hub.findMyPlot = findMyPlot
Hub.invalidateMyPlot = invalidateMyPlot
Hub.markScanDirty = function() Hub.ScanCache.dirty = true end

Log.info("Part 1B loaded ✔")
end
warn("=== CHRONOS_1B-4 END ===")
warn("=== CHRONOS_1 PART B COMPLETE ===")
--[[
    CHRONOS HUB — File 1, Part C
    Chunk 1C-1: Sound, Notifications, Steal SM, Main Steal Tick
]]

warn("=== CHRONOS_1C-1 START ===")
do

local Hub = getgenv().ChronosHub
if not Hub or not Hub._booted then
    error("[CHRONOS_1C] Part A not loaded.")
end

local Players          = Hub.Players
local Workspace        = Hub.Workspace
local RunService       = Hub.RunService
local TweenService     = Hub.TweenService
local HttpService      = Hub.HttpService
local SoundService     = Hub.SoundService
local LocalPlayer      = Hub.LocalPlayer
local PlaceId          = Hub.PlaceId
local JobId            = Hub.JobId
local IsMobile         = Hub.IsMobile
local Log              = Hub.Log
local Store            = Hub.Store
local HAS_FS           = Hub.HAS_FS
local Network          = Hub.Network
local HUI              = Hub.HUI
local Scheduler        = Hub.Scheduler
local MutColor         = Hub.MutColor
local fmtMutation      = Hub.fmtMutation
local scanAllPets      = Hub.scanAllPets
local ownerPassesFilters = Hub.ownerPassesFilters
local findMyPlot       = Hub.findMyPlot
local markScanDirty    = Hub.markScanDirty
local trackConn        = Hub.trackConn

-- [SOUND]
local alertSound = Instance.new("Sound")
alertSound.Name = "ChronosHubAlert"
alertSound.Volume = 1
alertSound.Parent = SoundService

function Hub.playAlert()
    if not Store.get("SoundEnabled") then return end
    pcall(function()
        alertSound:Stop()
        local id = tostring(Store.get("SoundId") or ""):gsub("%D", "")
        if id == "" then return end
        alertSound.SoundId = "rbxassetid://" .. id
        alertSound:Play()
    end)
end

-- [NOTIFICATION GUI]
local notifGui = HUI:FindFirstChild("ChronosHubNotifs")
if not notifGui then
    notifGui = Instance.new("ScreenGui")
    notifGui.Name = "ChronosHubNotifs"
    notifGui.ResetOnSpawn = false
    notifGui.DisplayOrder = 99999
    notifGui.Parent = HUI
end

local activeNotifs = {}

function Hub.notify(title, body, color)
    if not Store.get("NotifyEnabled") then return end
    color = color or Color3.fromRGB(0, 200, 115)

    if #activeNotifs >= 6 then
        local oldest = table.remove(activeNotifs, 1)
        if oldest then pcall(function() oldest:Destroy() end) end
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 66)
    frame.Position = UDim2.new(1, 320, 0, 100 + (#activeNotifs * 74))
    frame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    frame.BackgroundTransparency = 0.06
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -20, 0, 20)
    titleLbl.Position = UDim2.new(0, 12, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextColor3 = color
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.RichText = true

    local bodyLbl = Instance.new("TextLabel", frame)
    bodyLbl.Size = UDim2.new(1, -20, 0, 30)
    bodyLbl.Position = UDim2.new(0, 12, 0, 28)
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Text = body
    bodyLbl.Font = Enum.Font.Gotham
    bodyLbl.TextSize = 12
    bodyLbl.TextColor3 = Color3.fromRGB(200, 205, 220)
    bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
    bodyLbl.TextWrapped = true
    bodyLbl.RichText = true

    table.insert(activeNotifs, frame)

    TweenService:Create(frame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 0, 100 + ((#activeNotifs - 1) * 74))}
    ):Play()

    task.delay(4, function()
        for i, f in ipairs(activeNotifs) do
            if f == frame then table.remove(activeNotifs, i) break end
        end
        TweenService:Create(frame, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 320,
                frame.Position.Y.Scale, frame.Position.Y.Offset)
        }):Play()
        task.wait(0.35)
        pcall(function() frame:Destroy() end)
    end)
end

-- [STEAL STATE MACHINE]
local StealSM = {
    state = "IDLE",
    currentTarget = nil,
    enteredAt = os.clock(),
    streak = 0,
    bestStreak = 0,
    lastGrab = 0,
    totalGrabs = 0,
}

local function setState(newState)
    if StealSM.state == newState then return end
    StealSM.state = newState
    StealSM.enteredAt = os.clock()
end

local function inStateFor()
    return os.clock() - StealSM.enteredAt
end

-- [MAIN STEAL TICK]
local lastFire = 0
local stealBusy = false

Scheduler.add("stealTick", 8, 10, function()
    if not Store.get("AutoGrab") then
        if StealSM.state ~= "IDLE" then setState("IDLE") end
        StealSM.currentTarget = nil
        return
    end

    if stealBusy then return end

    local minDelay = Store.get("InstantGrabMode") and 0.08 or 0.4
    if os.clock() - lastFire < minDelay then return end

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local radius = Store.get("GrabRadius") or 55
    local minVal = (Store.get("MinValueMillions") or 5) * 1e6
    local candidates = {}

    for _, pet in ipairs(scanAllPets(minVal)) do
        if pet.part and pet.part.Parent
           and ownerPassesFilters(pet.owner) then
            local dist = (root.Position - pet.part.Position).Magnitude
            if dist <= radius then
                candidates[#candidates + 1] = {
                    pet = pet,
                    dist = dist,
                    value = pet.value,
                    name = pet.name,
                }
            end
        end
    end

    if #candidates == 0 then
        if StealSM.state ~= "IDLE" then setState("IDLE") end
        return
    end

    local mode = Store.get("SortMode") or "Nearest"
    if mode == "Priority" then
        local prioList = Store.get("PriorityList") or {}
        for _, c in ipairs(candidates) do
            c.prio = 999
            local lname = tostring(c.name):lower()
            for i, tok in ipairs(prioList) do
                if lname:find(tok, 1, true) then
                    c.prio = i break
                end
            end
        end
        table.sort(candidates, function(a, b)
            if a.prio ~= b.prio then return a.prio < b.prio end
            if a.value ~= b.value then return a.value > b.value end
            return a.dist < b.dist
        end)
    elseif mode == "Highest" then
        table.sort(candidates,
            function(a, b) return a.value > b.value end)
    else
        table.sort(candidates,
            function(a, b) return a.dist < b.dist end)
    end

    local best = candidates[1]
    StealSM.currentTarget = best.pet
    setState("GRABBING")
    lastFire = os.clock()

    stealBusy = true
    task.spawn(function()
local prompt = nil
pcall(function()
    local searchRoot = best.pet.model or best.pet.part
    if searchRoot and searchRoot.Parent then
        for _, d in ipairs(searchRoot:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then
                local at = (d.ActionText or ""):lower()
            if at:find("steal") or at:find("grab")
               or at:find("take") or at:find("collect")
               or at:find("interact") then   
                prompt = d
                break
                end
            end
        end
    end
    if not prompt then
        local plots = Workspace:FindFirstChild("Plots")
        local plot = plots and plots:FindFirstChild(best.pet.plot)
        if plot then
            for _, d in ipairs(plot:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d.Enabled then
                    local at = (d.ActionText or ""):lower()
                    if at:find("steal") or at:find("interact") then
                        prompt = d break
                    end
                end
            end
        end
    end
end)
        if prompt then
            local ok, method = Network.FirePrompt(prompt)
            if ok then
                StealSM.streak = StealSM.streak + 1
                StealSM.totalGrabs = StealSM.totalGrabs + 1
                if StealSM.streak > StealSM.bestStreak then
                    StealSM.bestStreak = StealSM.streak
                end
                StealSM.lastGrab = os.clock()
                setState("COOLDOWN")
            else
                StealSM.streak = 0
                setState("IDLE")
            end
        else
            setState("IDLE")
        end
        stealBusy = false
    end)
end)

Scheduler.add("stealCooldownReset", 4, 80, function()
    if StealSM.state == "COOLDOWN" and inStateFor() > 0.15 then
        setState("IDLE")
    end
end)

Hub.StealSM = StealSM
Hub.setState = setState

end
warn("=== CHRONOS_1C-1 END ===")
--[[
    CHRONOS HUB — File 1, Part C
    Chunk 1C-2: Auto Doors, Auto Invis, Auto Sell, Auto Kick,
                Auto Recover, Continuous TP, Safe Mode
]]

warn("=== CHRONOS_1C-2 START ===")
do

local Hub = getgenv().ChronosHub
local Players      = Hub.Players
local Workspace    = Hub.Workspace
local LocalPlayer  = Hub.LocalPlayer
local Log          = Hub.Log
local Store        = Hub.Store
local Network      = Hub.Network
local Scheduler    = Hub.Scheduler
local scanAllPets  = Hub.scanAllPets
local findMyPlot   = Hub.findMyPlot
local ownerPassesFilters = Hub.ownerPassesFilters

-- [AUTO DOORS]
Scheduler.add("autoDoors", 2, 40, function()
    local wantUnlock = Store.get("AutoUnlockDoors")
    local wantLock   = Store.get("AutoLockBase")
    if not (wantUnlock or wantLock) then return end

    local plot = findMyPlot()
    if not plot then return end

    for _, el in ipairs(plot:GetDescendants()) do
        if el:IsA("ProximityPrompt") and el.Enabled then
            local t = ((el.ActionText or "") .. " " ..
                       (el.ObjectText or "")):lower()
            if wantUnlock and (t:find("unlock")
               or t:find("gate") or t:find("door")
               or t:find("open")) then
                Network.FirePrompt(el)
            end
            if wantLock and (t:find("lock")
               or t:find("activate")) then
                Network.FirePrompt(el)
            end
        end
    end
end)

-- [AUTO INVIS DURING STEAL]
Scheduler.add("autoInvisSteal", 4, 45, function()
    if not Store.get("AutoInvisDuringSteal") then return end
    if LocalPlayer:GetAttribute("Stealing") then
        if Hub.toggleInvisibleSteal
           and not Hub.invisibleStealEnabled then
            pcall(Hub.toggleInvisibleSteal)
        end
    else
        if Hub.toggleInvisibleSteal
           and Hub.invisibleStealEnabled then
            pcall(Hub.toggleInvisibleSteal)
        end
    end
end)

-- [AUTO UNLOCK DURING STEAL]
Scheduler.add("autoUnlockSteal", 3, 46, function()
    if not Store.get("AutoUnlockDuringSteal") then return end
    if not LocalPlayer:GetAttribute("Stealing") then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    for _, plot in ipairs(plots:GetChildren()) do
        for _, el in ipairs(plot:GetDescendants()) do
            if el:IsA("ProximityPrompt") and el.Enabled then
                local t = ((el.ActionText or "") .. " " ..
                           (el.ObjectText or "")):lower()
                if t:find("unlock") or t:find("gate")
                   or t:find("open") then
                    local part = el.Parent
                        and (el.Parent:IsA("BasePart") and el.Parent
                        or el.Parent:FindFirstChildWhichIsA("BasePart", true))
                    if part then
                        local dist = (root.Position - part.Position).Magnitude
                        if dist <= 20 then
                            Network.FirePrompt(el)
                        end
                    end
                end
            end
        end
    end
end)

-- [AUTO WALKSPEED DURING STEAL]
Scheduler.add("autoWSSteal", 5, 47, function()
    if not Store.get("AutoWalkspeedOnSteal") then return end
    local stealing = LocalPlayer:GetAttribute("Stealing")
    local current  = Store.get("_wsAutoApplied") or false
    if stealing and not current then
        Store.set("_wsAutoApplied", true)
        Store.set("_wsPreSteal", Store.get("WalkSpeedValue"))
        Store.set("WalkSpeedValue", 120)
    elseif not stealing and current then
        Store.set("_wsAutoApplied", false)
        Store.set("WalkSpeedValue", Store.get("_wsPreSteal") or 16)
    end
end)

-- [AUTO SELL THRESHOLD]
Scheduler.add("autoSellThreshold", 5, 65, function()
    local threshold = (Store.get("AutoSellThresholdM") or 0) * 1e6
    if threshold <= 0 then return end

    local myPlot = findMyPlot()
    if not myPlot then return end

    local total = 0
    for _, pet in ipairs(scanAllPets(0)) do
        if pet.plot == myPlot.Name then
            total = total + pet.value
        end
    end

    if total >= threshold then
        for _, prompt in ipairs(myPlot:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local t = ((prompt.ActionText or "") .. " " ..
                           (prompt.ObjectText or "")):lower()
                if t:find("sell") or t:find("cash") then
                    Network.FirePrompt(prompt)
                end
            end
        end
    end
end)

-- [AUTO CLONE AFTER TP]
Scheduler.add("autoCloneAfterTP", 6, 48, function()
    if not Store.get("AutoCloneAfterTP") then return end
    if not LocalPlayer:GetAttribute("Stealing") then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    pcall(function()
        local cloner = LocalPlayer.Backpack:FindFirstChild("Quantum Cloner")
            or char:FindFirstChild("Quantum Cloner")
        if cloner and cloner.Parent == LocalPlayer.Backpack then
            hum:EquipTool(cloner)
        end
    end)
end)

-- [AUTO BUY CARPET]
Scheduler.add("autoBuy", 2, 45, function()
    if not Store.get("AutoBuyCarpet") then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local radius = Store.get("AutoBuyRadius") or 40

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local t = ((prompt.ActionText or "") .. " " ..
                       (prompt.ObjectText or "")):lower()
            if t:find("buy") or t:find("purchase") then
                local parent = prompt.Parent
                local part = parent
                    and (parent:IsA("BasePart") and parent
                    or parent:FindFirstChildWhichIsA("BasePart", true))
                if part and (root.Position - part.Position).Magnitude
                            <= radius then
                    Network.FirePrompt(prompt)
                end
            end
        end
    end
end)

-- [CONTINUOUS TP]
Scheduler.add("continuousTP", 5, 55, function()
    if not Store.get("ContinuousTP") then return end
    if LocalPlayer:GetAttribute("Stealing") then return end
    if not Hub.TeleportToHighest then return end
    pcall(Hub.TeleportToHighest)
end)

-- [AUTO KICK]
local kickPatterns = {
    "you stole", "you have stolen",
    "you successfully stole", "you been stole",
    "you've stolen",
}
local autoKickFired = false

local function scanForKick(text)
    if not Store.get("AutoKickEnabled") then return end
    if autoKickFired then return end
    if not text or text == "" then return end
    local lower = tostring(text):lower()
    for _, pat in ipairs(kickPatterns) do
        if lower:find(pat, 1, true) then
            autoKickFired = true
            Log.warn("[AUTOKICK] Triggered:", pat)
            pcall(function()
                Hub.notify("AUTO KICK", pat,
                    Color3.fromRGB(255, 90, 90))
            end)
            task.wait(0.12)
            pcall(function()
                LocalPlayer:Kick("Auto-Kick: " .. pat)
            end)
            pcall(function() game:Shutdown() end)
            return
        end
    end
end

local hookedKickLabels = setmetatable({}, {__mode = "k"})

local function hookKickLabel(label)
    if hookedKickLabels[label] then return end
    if not (label:IsA("TextLabel")
       or label:IsA("TextButton")
       or label:IsA("TextBox")) then return end
    hookedKickLabels[label] = true
    scanForKick(label.Text)
    local conn = label:GetPropertyChangedSignal("Text"):Connect(function()
        scanForKick(label.Text)
    end)
    Hub.trackConn(conn)
end

task.spawn(function()
    local pg = LocalPlayer:WaitForChild("PlayerGui", 30)
    if not pg then return end
    for _, d in ipairs(pg:GetDescendants()) do
        hookKickLabel(d)
    end
    Hub.trackConn(pg.DescendantAdded:Connect(function(d)
        hookKickLabel(d)
    end))
end)

-- [AUTO RECOVER ON LAGBACK]
Scheduler.add("autoRecoverLagback", 10, 82, function()
    if not Store.get("AutoRecoverEnabled") then return end
    if not LocalPlayer:GetAttribute("Stealing") then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local lastPos = Store.get("_lastRootPos")
    if lastPos then
        local jump = (root.Position - lastPos).Magnitude
        if jump > 25 then
            Log.warn("[RECOVER] Detected lagback of",
                math.floor(jump), "studs")
            pcall(function()
                Hub.notify("RECOVER", "Lagback detected",
                    Color3.fromRGB(255, 190, 80))
            end)
            if Hub.toggleInvisibleSteal
               and Hub.invisibleStealEnabled then
                pcall(Hub.toggleInvisibleSteal)
                task.wait(0.4)
                pcall(Hub.toggleInvisibleSteal)
            end
        end
    end
    Store.set("_lastRootPos", root.Position)
end)

-- [SAFE MODE]
Store.subscribe("SafeMode", function(v)
    if v then
        Store.set("PerPromptCooldown", 0.35)
        Hub.notify("Safe Mode", "Enabled — throttled",
            Color3.fromRGB(255, 190, 80))
    else
        Store.set("PerPromptCooldown", 0.08)
        Hub.notify("Safe Mode", "Disabled",
            Color3.fromRGB(0, 200, 115))
    end
end)

end
warn("=== CHRONOS_1C-2 END ===")
--[[
    CHRONOS HUB — File 1, Part C
    Chunk 1C-3: Tracking Suite
]]

warn("=== CHRONOS_1C-3 START ===")
do

local Hub = getgenv().ChronosHub
local Players          = Hub.Players
local Workspace        = Hub.Workspace
local RunService       = Hub.RunService
local TweenService     = Hub.TweenService
local HttpService      = Hub.HttpService
local LocalPlayer      = Hub.LocalPlayer
local Log              = Hub.Log
local Store            = Hub.Store
local HUI              = Hub.HUI
local Scheduler        = Hub.Scheduler
local MutColor         = Hub.MutColor
local fmtMutation      = Hub.fmtMutation
local scanAllPets      = Hub.scanAllPets
local ownerPassesFilters = Hub.ownerPassesFilters

-- [HIGH VALUE NOTIFIER]
local lastNotified = {}
Scheduler.add("notifyHighValue", 0.5, 60, function()
    if not (Store.get("NotifyEnabled")
       or Store.get("SoundEnabled")) then return end
    local minVal = (Store.get("NotifyMinMillions") or 50) * 1e6
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, pet in ipairs(scanAllPets(minVal)) do
        if pet.part and pet.part.Parent then
            if (root.Position - pet.part.Position).Magnitude < 150 then
                if ownerPassesFilters(pet.owner) then
                    local uid = pet.uid or
                        (pet.plot .. "_" .. tostring(pet.slot))
                    if not lastNotified[uid] then
                        lastNotified[uid] = os.clock()
                        local fmtVal = pet.value >= 1e9
                            and string.format("%.2fB", pet.value / 1e9)
                            or pet.value >= 1e6
                            and string.format("%.1fM", pet.value / 1e6)
                            or tostring(pet.value)
                        Hub.notify("High Value Detected",
                            fmtMutation(pet.mutation,
                                tostring(pet.name):upper()) ..
                            "\n<font color='rgb(0,255,100)'>$"
                            .. fmtVal .. "/s</font>",
                            MutColor[pet.mutation]
                            or Color3.fromRGB(0, 200, 115))
                        Hub.playAlert()
                    end
                end
            end
        end
    end

    local now = os.clock()
    for k, t in pairs(lastNotified) do
        if now - t > 90 then lastNotified[k] = nil end
    end
end)

-- [PLAYER TRACKER]
local trackerGui = HUI:FindFirstChild("ChronosTracker")
if not trackerGui then
    trackerGui = Instance.new("ScreenGui")
    trackerGui.Name = "ChronosTracker"
    trackerGui.ResetOnSpawn = false
    trackerGui.DisplayOrder = 8
    trackerGui.Parent = HUI
end

local trackerFrame = Instance.new("Frame", trackerGui)
trackerFrame.Size = UDim2.new(0, 320, 0, 260)
trackerFrame.Position = UDim2.new(0.5, -160, 0.35, -130)
trackerFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
trackerFrame.BackgroundTransparency = 0.08
trackerFrame.BorderSizePixel = 0
trackerFrame.Visible = false
Instance.new("UICorner", trackerFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", trackerFrame).Color =
    Color3.fromRGB(0, 200, 115)

local trackerTitle = Instance.new("TextLabel", trackerFrame)
trackerTitle.Size = UDim2.new(1, -40, 0, 26)
trackerTitle.Position = UDim2.new(0, 12, 0, 4)
trackerTitle.BackgroundTransparency = 1
trackerTitle.Font = Enum.Font.GothamBold
trackerTitle.TextSize = 13
trackerTitle.Text = "Player Tracker"
trackerTitle.TextColor3 = Color3.fromRGB(230, 235, 245)
trackerTitle.TextXAlignment = Enum.TextXAlignment.Left

local trackerClose = Instance.new("TextButton", trackerFrame)
trackerClose.Size = UDim2.new(0, 24, 0, 24)
trackerClose.Position = UDim2.new(1, -30, 0, 4)
trackerClose.BackgroundTransparency = 1
trackerClose.Text = "×"
trackerClose.Font = Enum.Font.GothamBold
trackerClose.TextSize = 16
trackerClose.TextColor3 = Color3.fromRGB(180, 180, 200)
trackerClose.MouseButton1Click:Connect(function()
    trackerFrame.Visible = false
    Store.set("PlayerTrackerPanel", false)
end)

local trackerScroll = Instance.new("ScrollingFrame", trackerFrame)
trackerScroll.Size = UDim2.new(1, -12, 1, -38)
trackerScroll.Position = UDim2.new(0, 6, 0, 32)
trackerScroll.BackgroundTransparency = 1
trackerScroll.BorderSizePixel = 0
trackerScroll.ScrollBarThickness = 4
trackerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
trackerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

Store.subscribe("PlayerTrackerPanel", function(v)
    trackerFrame.Visible = v and true or false
end)

Scheduler.add("trackerPanel", 2, 78, function()
    if not trackerFrame.Visible then return end
    for _, c in ipairs(trackerScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end

    local rows = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local status = "offline"
            local dist = "—"
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local stealing = p:GetAttribute("Stealing")
                local heldTool = nil
                for _, t in ipairs(char:GetChildren()) do
                    if t:IsA("Tool") then heldTool = t.Name break end
                end
                if stealing then status = "STEALING"
                elseif heldTool then status = heldTool
                else status = "idle" end

                if root then
                    local myRoot = LocalPlayer.Character
                        and LocalPlayer.Character:FindFirstChild(
                            "HumanoidRootPart")
                    if myRoot then
                        dist = string.format("%dm",
                            math.floor((root.Position
                            - myRoot.Position).Magnitude))
                    end
                end
            end
            table.insert(rows, string.format("%-16s %-12s %s",
                p.DisplayName:sub(1, 16), status, dist))
        end
    end

    for i, line in ipairs(rows) do
        local l = Instance.new("TextLabel", trackerScroll)
        l.Size = UDim2.new(1, 0, 0, 18)
        l.Position = UDim2.new(0, 0, 0, (i - 1) * 18)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.Code
        l.TextSize = 11
        l.TextColor3 = Color3.fromRGB(220, 225, 240)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = line
    end
end)

-- [BASE OWNERSHIP PANEL]
local baseGui = HUI:FindFirstChild("ChronosBases")
if not baseGui then
    baseGui = Instance.new("ScreenGui")
    baseGui.Name = "ChronosBases"
    baseGui.ResetOnSpawn = false
    baseGui.DisplayOrder = 8
    baseGui.Parent = HUI
end

local baseFrame = Instance.new("Frame", baseGui)
baseFrame.Size = UDim2.new(0, 340, 0, 280)
baseFrame.Position = UDim2.new(0.5, -170, 0.4, -140)
baseFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
baseFrame.BackgroundTransparency = 0.08
baseFrame.BorderSizePixel = 0
baseFrame.Visible = false
Instance.new("UICorner", baseFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", baseFrame).Color =
    Color3.fromRGB(0, 200, 115)

local baseTitle = Instance.new("TextLabel", baseFrame)
baseTitle.Size = UDim2.new(1, -40, 0, 26)
baseTitle.Position = UDim2.new(0, 12, 0, 4)
baseTitle.BackgroundTransparency = 1
baseTitle.Font = Enum.Font.GothamBold
baseTitle.TextSize = 13
baseTitle.Text = "Base Ownership"
baseTitle.TextColor3 = Color3.fromRGB(230, 235, 245)
baseTitle.TextXAlignment = Enum.TextXAlignment.Left

local baseClose = Instance.new("TextButton", baseFrame)
baseClose.Size = UDim2.new(0, 24, 0, 24)
baseClose.Position = UDim2.new(1, -30, 0, 4)
baseClose.BackgroundTransparency = 1
baseClose.Text = "×"
baseClose.Font = Enum.Font.GothamBold
baseClose.TextSize = 16
baseClose.TextColor3 = Color3.fromRGB(180, 180, 200)
baseClose.MouseButton1Click:Connect(function()
    baseFrame.Visible = false
    Store.set("BaseOwnershipPanel", false)
end)

local baseScroll = Instance.new("ScrollingFrame", baseFrame)
baseScroll.Size = UDim2.new(1, -12, 1, -38)
baseScroll.Position = UDim2.new(0, 6, 0, 32)
baseScroll.BackgroundTransparency = 1
baseScroll.BorderSizePixel = 0
baseScroll.ScrollBarThickness = 4
baseScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
baseScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

Store.subscribe("BaseOwnershipPanel", function(v)
    baseFrame.Visible = v and true or false
end)

Scheduler.add("basePanel", 2, 78, function()
    if not baseFrame.Visible then return end
    for _, c in ipairs(baseScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end

    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end
    local allPets = scanAllPets(0)
    local rows = {}

    for _, plot in ipairs(plots:GetChildren()) do
        local owner = plot:GetAttribute("Owner")
        if not owner then
            local sign = plot:FindFirstChild("PlotSign")
            local sGui = sign and sign:FindFirstChildWhichIsA(
                "SurfaceGui", true)
            local lbl = sGui and sGui:FindFirstChildWhichIsA(
                "TextLabel", true)
            if lbl then owner = lbl.Text end
        end

        local totalValue = 0
        for _, pet in ipairs(allPets) do
            if pet.plot == plot.Name then
                totalValue = totalValue + pet.value
            end
        end
        table.insert(rows,
            {name = tostring(owner or plot.Name), value = totalValue})
    end

    table.sort(rows, function(a, b) return a.value > b.value end)

    for i, row in ipairs(rows) do
        local fmt = row.value >= 1e9
                and string.format("%.2fB", row.value / 1e9)
                or row.value >= 1e6
                and string.format("%.1fM", row.value / 1e6)
                or tostring(row.value)
        local l = Instance.new("TextLabel", baseScroll)
        l.Size = UDim2.new(1, 0, 0, 18)
        l.Position = UDim2.new(0, 0, 0, (i - 1) * 18)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.Code
        l.TextSize = 11
        l.TextColor3 = Color3.fromRGB(220, 225, 240)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = string.format("%-18s %10s",
            row.name:sub(1, 18), "$" .. fmt)
    end
end)

-- [PET MOVE DETECTION]
local petLastSeen = {}
Scheduler.add("petMoveDetect", 1, 70, function()
    if not Store.get("PetMoveDetection") then return end
    local watchName = (Store.get("PetMoveWatchName") or ""):lower()
    if watchName == "" then return end

    for _, pet in ipairs(scanAllPets(0)) do
        local name = tostring(pet.name):lower()
        if name:find(watchName, 1, true) then
            local key = pet.name
            local prev = petLastSeen[key]
            if prev and prev.plot ~= pet.plot then
                Hub.notify("Pet Moved",
                    pet.name .. ": " .. prev.plot .. " → " .. pet.plot,
                    Color3.fromRGB(255, 190, 80))
            end
            petLastSeen[key] = {plot = pet.plot, t = os.clock()}
        end
    end
end)

-- [DISTANCE RADAR]
local radarGui = HUI:FindFirstChild("ChronosRadar")
if not radarGui then
    radarGui = Instance.new("ScreenGui")
    radarGui.Name = "ChronosRadar"
    radarGui.ResetOnSpawn = false
    radarGui.DisplayOrder = 8
    radarGui.Parent = HUI
end

local radar = Instance.new("Frame", radarGui)
radar.Size = UDim2.new(0, 130, 0, 130)
radar.Position = UDim2.new(0, 20, 0.55, 0)
radar.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
radar.BackgroundTransparency = 0.3
radar.BorderSizePixel = 0
radar.Visible = false
Instance.new("UICorner", radar).CornerRadius = UDim.new(1, 0)

local radarStroke = Instance.new("UIStroke", radar)
radarStroke.Color = Color3.fromRGB(0, 200, 115)
radarStroke.Thickness = 1.5

Scheduler.add("radar", 4, 68, function()
    if not Store.get("DistanceRadar") then
        radar.Visible = false
        return
    end
    radar.Visible = true
    for _, c in ipairs(radar:GetChildren()) do
        if c:IsA("Frame") and c:GetAttribute("radarDot") then
            c:Destroy()
        end
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local myPos = root.Position
    local fwd = root.CFrame.LookVector
    local right = root.CFrame.RightVector
    local maxRange = 150

    for _, pet in ipairs(scanAllPets(0)) do
        if pet.part and pet.part.Parent then
            local delta = pet.part.Position - myPos
            if delta.Magnitude < maxRange then
                local nx = math.clamp(delta:Dot(right) / maxRange, -1, 1)
                local nz = math.clamp(delta:Dot(fwd) / maxRange, -1, 1)
                local dot = Instance.new("Frame", radar)
                dot:SetAttribute("radarDot", true)
                dot.Size = UDim2.new(0, 6, 0, 6)
                dot.Position = UDim2.new(0.5 + nx * 0.5, -3,
                    0.5 - nz * 0.5, -3)
                dot.BackgroundColor3 = MutColor[pet.mutation]
                    or Color3.fromRGB(0, 200, 115)
                dot.BorderSizePixel = 0
                Instance.new("UICorner", dot).CornerRadius =
                    UDim.new(1, 0)
            end
        end
    end

    if not radar:FindFirstChild("RadarCenter") then
        local center = Instance.new("Frame", radar)
        center.Name = "RadarCenter"
        center.Size = UDim2.new(0, 8, 0, 8)
        center.Position = UDim2.new(0.5, -4, 0.5, -4)
        center.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        center.BorderSizePixel = 0
        Instance.new("UICorner", center).CornerRadius =
            UDim.new(1, 0)
    end
end)

end
warn("=== CHRONOS_1C-3 END ===")
--[[
    CHRONOS HUB — File 1, Part C
    Chunk 1C-4A: Stats HUD, Chat, Webhook, Incoming Predictor,
                 Server Hop, Rejoin, JobID Spam, Panic, Idle,
                 Anti-TP, Roam
]]

warn("=== CHRONOS_1C-4A START ===")
do

local Hub = getgenv().ChronosHub
local Players         = Hub.Players
local Workspace       = Hub.Workspace
local UserInputService = Hub.UserInputService
local HttpService     = Hub.HttpService
local TeleportService = Hub.TeleportService
local LocalPlayer     = Hub.LocalPlayer
local PlaceId         = Hub.PlaceId
local JobId           = Hub.JobId
local Log             = Hub.Log
local Store           = Hub.Store
local HUI             = Hub.HUI
local Scheduler       = Hub.Scheduler
local scanAllPets     = Hub.scanAllPets
local trackConn       = Hub.trackConn
local StealSM         = Hub.StealSM

-- [STATS HUD]
local statsGui = HUI:FindFirstChild("ChronosStats")
if not statsGui then
    statsGui = Instance.new("ScreenGui")
    statsGui.Name = "ChronosStats"
    statsGui.ResetOnSpawn = false
    statsGui.DisplayOrder = 6
    statsGui.Parent = HUI
end

local statsFrame = Instance.new("Frame", statsGui)
statsFrame.Size = UDim2.new(0, 200, 0, 70)
statsFrame.Position = UDim2.new(1, -210, 1, -160)
statsFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
statsFrame.BackgroundTransparency = 0.15
statsFrame.BorderSizePixel = 0
statsFrame.Visible = false
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 8)

local statsLbl = Instance.new("TextLabel", statsFrame)
statsLbl.Size = UDim2.new(1, -12, 1, -8)
statsLbl.Position = UDim2.new(0, 6, 0, 4)
statsLbl.BackgroundTransparency = 1
statsLbl.Font = Enum.Font.Code
statsLbl.TextSize = 11
statsLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
statsLbl.TextXAlignment = Enum.TextXAlignment.Left
statsLbl.TextYAlignment = Enum.TextYAlignment.Top
statsLbl.RichText = true

Store.subscribe("StatsEnabled", function(v)
    statsFrame.Visible = v and true or false
end)

local sessionStart = os.time()

Scheduler.add("statsHud", 1, 92, function()
    if not Store.get("StatsEnabled") then return end
    local uptime = os.time() - sessionStart
    local grabs = StealSM.totalGrabs
    local best = StealSM.bestStreak
    local gpm = uptime > 0 and (grabs / (uptime / 60)) or 0
    local mins = math.floor(uptime / 60)
    local hrs = math.floor(mins / 60)
    local dur = hrs > 0 and string.format("%dh%dm", hrs, mins % 60)
                or string.format("%dm%ds", mins, uptime % 60)
    statsLbl.Text = string.format(
        "Grabs <font color='rgb(0,220,120)'>%d</font> | " ..
        "Streak <font color='rgb(255,200,80)'>%d</font>\n" ..
        "Best: <font color='rgb(255,215,0)'>%d</font> | " ..
        "Uptime: <font color='rgb(150,200,255)'>%s</font>\n" ..
        "Rate: <font color='rgb(180,180,220)'>%.1f</font>/min",
        grabs, StealSM.streak, best, dur, gpm)
end)

-- [CHAT LOGGER]
local chatLog = {}
task.spawn(function()
    pcall(function()
        local TCS = game:GetService("TextChatService")
        if TCS and TCS.MessageReceived then
            TCS.MessageReceived:Connect(function(msg)
                if not Store.get("ChatLogger") then return end
                local src = msg.TextSource
                local plr = src and Players:GetPlayerByUserId(src.UserId)
                table.insert(chatLog, {
                    name = plr and plr.DisplayName or "?",
                    text = msg.Text, t = os.clock(),
                })
                if #chatLog > 200 then table.remove(chatLog, 1) end
            end)
        end
    end)
end)
Hub.chatLog = chatLog

-- [WEBHOOK]
local webhookState = {lastSent = 0}

local function sendWebhook(embed)
    if not Store.get("WebhookEnabled") then return end
    local url = Store.get("WebhookURL")
    if not url or url == "" then return end
    pcall(function()
        local body = HttpService:JSONEncode(embed)
        local req = http_request or request or (syn and syn.request)
        if not req then return end
        req({
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body,
        })
    end)
end

Scheduler.add("webhookScan", 0.5, 55, function()
    if not Store.get("WebhookEnabled") then return end
    local minVal = (Store.get("WebhookMinMillions") or 100) * 1e6
    local now = os.clock()
    if now - webhookState.lastSent
       < (Store.get("WebhookCooldownSec") or 30) then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, pet in ipairs(scanAllPets(minVal)) do
        if pet.part and pet.part.Parent then
            if (root.Position - pet.part.Position).Magnitude < 200 then
                if Hub.ownerPassesFilters(pet.owner) then
                    webhookState.lastSent = now
                    local fmtVal = pet.value >= 1e9
                        and string.format("%.2fB", pet.value / 1e9)
                        or pet.value >= 1e6
                        and string.format("%.1fM", pet.value / 1e6)
                        or tostring(pet.value)
                    sendWebhook({
                        username = "Chronos Hub",
                        content = "**High value detected**",
                        embeds = {{
                            title = tostring(pet.name),
                            description = "Mutation: **"
                                .. tostring(pet.mutation or "None")
                                .. "**\nValue: **$" .. fmtVal .. "/s**"
                                .. "\nOwner: " .. tostring(pet.owner or "?"),
                            color = 0x00c873,
                        }},
                    })
                    return
                end
            end
        end
    end
end)

-- [INCOMING PREDICTOR]
Scheduler.add("incomingPredict", 1.5, 62, function()
    if not Store.get("IncomingPredictor") then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local stealing = p:GetAttribute("Stealing")
            local idx = p:GetAttribute("StealingIndex")
            if stealing and idx then
                local bb = p.Character:FindFirstChild(
                    "ChronosIncomingPredictor")
                if not bb then
                    bb = Instance.new("BillboardGui")
                    bb.Name = "ChronosIncomingPredictor"
                    bb.Size = UDim2.new(0, 200, 0, 50)
                    bb.StudsOffset = Vector3.new(0, 5, 0)
                    bb.AlwaysOnTop = true
                    bb.Parent = p.Character
                    local l = Instance.new("TextLabel", bb)
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.BackgroundTransparency = 1
                    l.Font = Enum.Font.GothamBlack
                    l.TextSize = 14
                    l.TextColor3 = Color3.fromRGB(255, 90, 90)
                    l.TextStrokeTransparency = 0.5
                    l.RichText = true
                    l.Name = "PredictLabel"
                end
                local l = bb:FindFirstChild("PredictLabel")
                if l then l.Text = "⚡ INCOMING: " .. tostring(idx) end
            else
                local bb = p.Character
                    and p.Character:FindFirstChild(
                        "ChronosIncomingPredictor")
                if bb then bb:Destroy() end
            end
        end
    end
end)

-- [SERVER HOP]
local function serverHop()
    Hub.notify("Server Hop", "Searching...",
        Color3.fromRGB(255, 190, 80))
    local visited = {}
    local cursor = nil
    for page = 1, 4 do
        local url = string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public" ..
            "?sortOrder=Asc&limit=100", PlaceId)
        if cursor then url = url .. "&cursor=" .. cursor end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if ok and data and data.data then
            for _, srv in ipairs(data.data) do
                if srv.id ~= JobId and not visited[srv.id]
                   and (srv.playing or 0) < (srv.maxPlayers or 999) then
                    visited[srv.id] = true
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(
                            PlaceId, srv.id, LocalPlayer)
                    end)
                    return true
                end
            end
            cursor = data.nextPageCursor
            if not cursor then break end
        else break end
    end
    Hub.notify("Server Hop", "No suitable server found",
        Color3.fromRGB(255, 100, 100))
    return false
end

-- [REJOIN]
local function rejoin()
    Hub.notify("Rejoin", "Rejoining...",
        Color3.fromRGB(255, 190, 80))
    pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    end)
end

Hub.serverHop = serverHop
Hub.rejoin = rejoin

-- [JOB ID SPAM]
local jobIdSpamActive = false

function Hub.toggleJobIdSpam()
    jobIdSpamActive = not jobIdSpamActive
    if jobIdSpamActive then
        Hub.notify("JobID Spam", "Enabled",
            Color3.fromRGB(0, 200, 115))
        task.spawn(function()
            while jobIdSpamActive do
                pcall(function()
                    for i = 1, 8 do
                        TeleportService:TeleportToPlaceInstance(
                            PlaceId, JobId)
                    end
                end)
                task.wait(0.1)
            end
        end)
    else
        Hub.notify("JobID Spam", "Disabled",
            Color3.fromRGB(255, 100, 100))
    end
end

-- [PANIC KEY]
local DANGEROUS = {
    "AutoGrab", "HoldSteal", "InstantSteal", "AutoLockBase",
    "AutoUnlockDoors", "AutoStealPriority", "AutoBuyCarpet",
    "RoamProtection", "AutoInvisDuringSteal",
}

function Hub.panicButton()
    local saved = {}
    for _, k in ipairs(DANGEROUS) do
        if Store.get(k) then
            saved[k] = true
            Store.set(k, false)
        end
    end
    Store.set("PanicLastEnabled", saved)
    Hub.notify("PANIC", "All features disabled",
        Color3.fromRGB(255, 90, 90))
end

function Hub.unpanic()
    local saved = Store.get("PanicLastEnabled") or {}
    for k in pairs(saved) do Store.set(k, true) end
    Store.set("PanicLastEnabled", {})
    Hub.notify("PANIC", "Features restored",
        Color3.fromRGB(0, 200, 115))
end

trackConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = Store.get("PanicKey") or "End"
    if input.KeyCode.Name == key then
        local saved = Store.get("PanicLastEnabled") or {}
        if next(saved) then Hub.unpanic() else Hub.panicButton() end
    end
end))

-- [IDLE DETECTION]
local lastMoveTime = os.clock()
local lastPos = nil
Scheduler.add("idleDetect", 2, 55, function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not lastPos then
        lastPos = root.Position
        lastMoveTime = os.clock()
        return
    end
    if (root.Position - lastPos).Magnitude > 1 then
        lastMoveTime = os.clock()
    end
    lastPos = root.Position

    if Store.get("IdleDetection") then
        local timeout = Store.get("IdleTimeoutSec") or 300
        if os.clock() - lastMoveTime > timeout
           and not Store.get("_idlePaused") then
            Store.set("_idlePaused", true)
            local snap = {}
            for _, k in ipairs({"AutoGrab", "HoldSteal"}) do
                if Store.get(k) then
                    snap[k] = true
                    Store.set(k, false)
                end
            end
            Store.set("_idleSnapshot", snap)
            Hub.notify("Idle", "Auto-paused",
                Color3.fromRGB(255, 190, 80))
        end
    end
    if Store.get("_idlePaused")
       and os.clock() - lastMoveTime < 5 then
        local snap = Store.get("_idleSnapshot") or {}
        for k in pairs(snap) do Store.set(k, true) end
        Store.set("_idlePaused", false)
        Hub.notify("Idle", "Resumed",
            Color3.fromRGB(0, 200, 115))
    end
end)

-- [ANTI-TP]
local lastGoodPos = nil
Scheduler.add("antiTP", 0.5, 50, function()
    if not Store.get("AntiIdleTeleport") then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not lastGoodPos then lastGoodPos = root.Position return end
    local jump = (root.Position - lastGoodPos).Magnitude
    if jump > 150 then
        pcall(function() root.CFrame = CFrame.new(lastGoodPos) end)
        Hub.notify("Anti-TP", "Blocked unexpected teleport",
            Color3.fromRGB(255, 190, 80))
    else
        lastGoodPos = root.Position
    end
end)

-- [ROAM PROTECTION]
Scheduler.add("roamProtect", 2, 42, function()
    if not Store.get("RoamProtection") then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local plot = Hub.findMyPlot()
    if not plot then return end
    local plotPos = plot:GetPivot().Position
    if (root.Position - plotPos).Magnitude
       > (Store.get("RoamMaxDistance") or 300) then
        pcall(function()
            root.CFrame = CFrame.new(plotPos + Vector3.new(0, 5, 0))
            root.AssemblyLinearVelocity = Vector3.zero
        end)
        Hub.notify("Roam", "Teleported back to base",
            Color3.fromRGB(255, 190, 80))
    end
end)

end
warn("=== CHRONOS_1C-4A END ===")
--[[
    CHRONOS HUB — File 1, Part C
    Chunk 1C-4B: Perf Overlay, Protections, Render/Visual Cleanup,
                 FPS Boost, Character Lifecycle, AP Suite, Final Boot
]]

warn("=== CHRONOS_1C-4B START ===")
do

local Hub = getgenv().ChronosHub
local Players      = Hub.Players
local Workspace    = Hub.Workspace
local RunService   = Hub.RunService
local LocalPlayer  = Hub.LocalPlayer
local Log          = Hub.Log
local Store        = Hub.Store
local HUI          = Hub.HUI
local Scheduler    = Hub.Scheduler
local StealSM      = Hub.StealSM
local trackConn    = Hub.trackConn

-- [PERF OVERLAY]
local perfGui = HUI:FindFirstChild("ChronosPerf")
if not perfGui then
    perfGui = Instance.new("ScreenGui")
    perfGui.Name = "ChronosPerf"
    perfGui.ResetOnSpawn = false
    perfGui.DisplayOrder = 7
    perfGui.Parent = HUI
end

local perfFrame = Instance.new("Frame", perfGui)
perfFrame.Size = UDim2.new(0, 240, 0, 100)
perfFrame.Position = UDim2.new(0, 20, 0, 20)
perfFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
perfFrame.BackgroundTransparency = 0.15
perfFrame.BorderSizePixel = 0
perfFrame.Visible = false
Instance.new("UICorner", perfFrame).CornerRadius = UDim.new(0, 8)

local perfLbl = Instance.new("TextLabel", perfFrame)
perfLbl.Size = UDim2.new(1, -12, 1, -8)
perfLbl.Position = UDim2.new(0, 6, 0, 4)
perfLbl.BackgroundTransparency = 1
perfLbl.Font = Enum.Font.Code
perfLbl.TextSize = 11
perfLbl.TextColor3 = Color3.fromRGB(200, 220, 200)
perfLbl.TextXAlignment = Enum.TextXAlignment.Left
perfLbl.TextYAlignment = Enum.TextYAlignment.Top
perfLbl.RichText = true

Scheduler.add("perfSample", 2, 95, function()
    if not Store.get("PerfOverlay") then
        perfFrame.Visible = false
        return
    end
    perfFrame.Visible = true
    local fps = math.floor(1 / math.max(
        RunService.Heartbeat:Wait() or 0.016, 0.001))
    local ping = 0
    pcall(function()
        ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
    end)
    perfLbl.Text = string.format(
        "FPS: %d | Ping: %dms\nThrottle: %d%%\nJobs: %d\nStreak: %d",
        fps, ping, math.floor((Scheduler.throttleMult or 1) * 100),
        #Scheduler.jobs, StealSM.streak)
end)

-- [ANTI RAGDOLL]
Scheduler.add("antiRagdoll", 5, 30, function()
    if not Store.get("AntiRagdoll") then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local s = hum:GetState()
        if s == Enum.HumanoidStateType.Physics
        or s == Enum.HumanoidStateType.Ragdoll
        or s == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
        hum.PlatformStand = false
    end
    for _, m in ipairs(char:GetDescendants()) do
        if m:IsA("Motor6D") and not m.Enabled then m.Enabled = true end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.Anchored then hrp.Anchored = false end
end)

-- [ANTI DIE]
Scheduler.add("antiDie", 10, 30, function()
    if not Store.get("AntiDie") then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.BreakJointsOnDeath = false
        if hum.Health <= 0 then hum.Health = hum.MaxHealth end
    end
end)

-- [INFINITE JUMP]
trackConn(Hub.UserInputService.JumpRequest:Connect(function()
    if not Store.get("InfiniteJump") then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.new(
            root.AssemblyLinearVelocity.X, 48,
            root.AssemblyLinearVelocity.Z)
    end
end))

-- [WALK SPEED]
Scheduler.add("walkSpeed", 2, 70, function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local v = Store.get("WalkSpeedValue")
        if type(v) == "number" and v > 0 then
            hum.WalkSpeed = v
        end
    end
end)

-- [RENDER CLEANUP]
Scheduler.add("renderCleanup", 1, 75, function()
    local removeAcc  = Store.get("RemoveAccessories")
    local removeAnim = Store.get("RemoveAnimations")
    if not (removeAcc or removeAnim) then return end
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if char then
            if removeAcc then
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("Accessory") or d:IsA("Hat") then
                        pcall(function() d:Destroy() end)
                    end
                end
            end
            if removeAnim then
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("Animator")
                    or d:IsA("AnimationController") then
                        pcall(function() d:Destroy() end)
                    end
                end
            end
        end
    end
end)

-- [VISUAL CLEANUP]
task.spawn(function()
    local function nuke(inst)
        if inst:IsA("BlurEffect")
        or inst:IsA("ColorCorrectionEffect")
        or inst:IsA("DepthOfFieldEffect") then
            if Store.get("VisualCleanup") then
                pcall(function() inst:Destroy() end)
            end
        end
    end
    for _, c in ipairs(Hub.Lighting:GetChildren()) do nuke(c) end
    trackConn(Hub.Lighting.ChildAdded:Connect(function(c)
        task.defer(nuke, c)
    end))
end)

-- [FPS BOOST]
local fpsBoostActive = false
function Hub.enableFPSBoost()
    if fpsBoostActive then return end
    fpsBoostActive = true
    Hub.Lighting.GlobalShadows = false
    Hub.Lighting.FogEnd = 1000000
    Hub.Lighting.FogStart = 0
    Hub.Lighting.EnvironmentDiffuseScale = 0
    Hub.Lighting.EnvironmentSpecularScale = 0
    for _, c in ipairs(Hub.Lighting:GetChildren()) do
        if c:IsA("BloomEffect") or c:IsA("BlurEffect")
        or c:IsA("ColorCorrectionEffect") then
            c:Destroy()
        end
    end
    pcall(function() if setfpscap then setfpscap(999) end end)
end

function Hub.disableFPSBoost()
    fpsBoostActive = false
end

-- [CHARACTER LIFECYCLE]
trackConn(LocalPlayer.CharacterAdded:Connect(function()
    if Hub.SegmentCache and Hub.SegmentCache.clear then
        Hub.SegmentCache.clear()
    end
    if Hub.invalidateMyPlot then Hub.invalidateMyPlot() end
    if Hub.markScanDirty then Hub.markScanDirty() end
    if Hub.setState then Hub.setState("IDLE") end
    StealSM.currentTarget = nil
    StealSM.streak = 0
end))

-- ============================================================
-- [AP SUITE]
-- ============================================================
local ReplicatedStorage = Hub.ReplicatedStorage

local APCommands = {
    "jail", "rocket", "inverse", "ragdoll", "jumpscare",
    "tiny", "balloon", "morph", "nightvision", "freeze",
}
local APLog = {}

local function apPush(entry)
    table.insert(APLog, entry)
    if #APLog > 200 then table.remove(APLog, 1) end
end

function Hub.hasAP()
    for _, name in ipairs({
        "AdminPanel", "AP", "AdminGui", "CommandPanel",
    }) do
        if Hub.PlayerGui:FindFirstChild(name) then return true end
        if HUI:FindFirstChild(name) then return true end
    end
    return false
end

local function isAPBlacklisted(player)
    if not Store.get("APBlacklistEnabled") then return false end
    local bl = Store.get("APBlacklistNames") or {}
    local name = player.Name:lower()
    for _, n in ipairs(bl) do
        if name == tostring(n):lower() then return true end
    end
    return false
end

function Hub.fireAP(target, command)
    if not target or not command then return false end
    if type(target) == "Instance" and target:IsA("Player") then
        if isAPBlacklisted(target) then
            Hub.notify("AP", "Blocked (blacklist): " .. target.Name,
                Color3.fromRGB(255, 190, 80))
            return false
        end
    end
    local targetName = type(target) == "Instance"
        and target.Name or tostring(target)
    local success = false

    for _, name in ipairs({
        "AdminCommand", "RE/AdminCommand", "RE/Admin",
        "ExecuteCommand", "RE/ExecuteCommand",
        "AdminService/Command",
    }) do
        pcall(function()
            local remote = ReplicatedStorage:FindFirstChild(name, true)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer(targetName, command)
                success = true
            end
        end)
        if success then
            apPush({t = os.time(), target = targetName,
                cmd = command, ok = true})
            return true
        end
    end

    pcall(function()
        local candidates = {}
        local function scan(parent)
            for _, c in ipairs(parent:GetDescendants()) do
                if c:IsA("TextButton") or c:IsA("ImageButton") then
                    local label = (c.Text or "") .. (c.Name or "")
                    if label:lower():find(command:lower(), 1, true) then
                        table.insert(candidates, c)
                    end
                end
            end
        end
        scan(Hub.PlayerGui)
        for _, btn in ipairs(candidates) do
            pcall(function()
                if firesignal then firesignal(btn.MouseButton1Click)
                else btn.MouseButton1Click:Fire() end
            end)
        end
        if #candidates > 0 then success = true end
    end)
    if success then
        apPush({t = os.time(), target = targetName,
            cmd = command, ok = true})
        return true
    end

    apPush({t = os.time(), target = targetName,
        cmd = command, ok = false, reason = "no_method"})
    return false
end

function Hub.fireAPAll(command)
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if Hub.fireAP(p, command) then count = count + 1 end
            task.wait(0.05)
        end
    end
    Hub.notify("AP All",
        "Fired " .. command .. " on " .. count .. " players",
        Color3.fromRGB(0, 200, 115))
    return count
end

-- [PROXIMITY AP]
local proxAPRotator = 0
Scheduler.add("proximityAP", 3, 12, function()
    if not Store.get("ProximityAP") then return end
    local radius = Store.get("ProximityAPRadius") or 15
    local cmd = Store.get("ProximityAPCommand") or "balloon"
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local nearby = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - myRoot.Position).Magnitude
                        <= radius then
                table.insert(nearby, p)
            end
        end
    end
    if #nearby == 0 then return end
    proxAPRotator = proxAPRotator % #nearby + 1
    Hub.fireAP(nearby[proxAPRotator], cmd)
end)

-- [CLICK TO AP]
local clickAPActive = false
local clickHighlight = Instance.new("Highlight")
clickHighlight.FillColor = Color3.fromRGB(255, 90, 90)
clickHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
clickHighlight.FillTransparency = 0.5
clickHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
clickHighlight.Enabled = false
clickHighlight.Parent = HUI

function Hub.toggleClickAP()
    clickAPActive = not clickAPActive
    Hub.notify("Click to AP",
        clickAPActive and "ON" or "OFF",
        clickAPActive and Color3.fromRGB(0, 200, 115)
        or Color3.fromRGB(255, 100, 100))
    if not clickAPActive then
        clickHighlight.Enabled = false
        clickHighlight.Adornee = nil
    end
end

trackConn(Hub.UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not clickAPActive then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end
    if not clickHighlight.Adornee then return end
    local char = clickHighlight.Adornee
    local target = Players:GetPlayerFromCharacter(char)
    if target and target ~= LocalPlayer then
        local cmd = Store.get("ClickAPCommand") or "balloon"
        Hub.fireAP(target, cmd)
    end
end))

Scheduler.add("clickAPDetect", 0.1, 90, function()
    if not clickAPActive then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local mousePos = Hub.UserInputService:GetMouseLocation()
    local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local hit = Workspace:Raycast(
        ray.Origin, ray.Direction * 500, params)
    local newTarget = nil
    if hit and hit.Instance then
        local model = hit.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local player = Players:GetPlayerFromCharacter(model)
            if player and player ~= LocalPlayer then
                newTarget = model
            end
        end
    end
    if newTarget then
        clickHighlight.Adornee = newTarget
        clickHighlight.Enabled = true
    else
        clickHighlight.Adornee = nil
        clickHighlight.Enabled = false
    end
end)

-- [SPAM BASE OWNER]
function Hub.spamBaseOwner()
    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        Hub.notify("Spam Base", "No character",
            Color3.fromRGB(255, 100, 100))
        return
    end
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    local nearest, nearestDist = nil, math.huge
    for _, plot in ipairs(plots:GetChildren()) do
        local isMine = false
        local sign = plot:FindFirstChild("PlotSign")
        local sGui = sign
            and sign:FindFirstChildWhichIsA("SurfaceGui", true)
        local lbl = sGui
            and sGui:FindFirstChildWhichIsA("TextLabel", true)
        if lbl then
            local t = lbl.Text:lower()
            if t:find(LocalPlayer.Name:lower(), 1, true) then
                isMine = true
            end
        end
        if not isMine and sign and sign:IsA("BasePart") then
            local d = (myRoot.Position - sign.Position).Magnitude
            if d < nearestDist then
                nearest = plot
                nearestDist = d
            end
        end
    end

    if not nearest or nearestDist > 100 then
        Hub.notify("Spam Base", "No nearby base",
            Color3.fromRGB(255, 100, 100))
        return
    end

    local owner = nil
    local sign = nearest:FindFirstChild("PlotSign")
    local sGui = sign and sign:FindFirstChildWhichIsA(
        "SurfaceGui", true)
    local lbl = sGui and sGui:FindFirstChildWhichIsA(
        "TextLabel", true)
    if lbl then
        local name = (lbl.Text or ""):match("^([^']+)'s")
        if name then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower() == name:lower()
                or p.DisplayName:lower() == name:lower() then
                    owner = p
                    break
                end
            end
        end
    end

    if not owner or owner == LocalPlayer then
        Hub.notify("Spam Base", "Owner not found",
            Color3.fromRGB(255, 100, 100))
        return
    end

    Hub.notify("Spam Base", "Spamming " .. owner.DisplayName,
        Color3.fromRGB(0, 200, 115))
    task.spawn(function()
        for _, cmd in ipairs(APCommands) do
            Hub.fireAP(owner, cmd)
            task.wait(0.15)
        end
    end)
end

-- [AP STATUS MONITOR]
Scheduler.add("apStatusMonitor", 1, 60, function()
    local has = Hub.hasAP()
    if has ~= Store.get("_apDetected") then
        Store.set("_apDetected", has)
        if has then
            Hub.notify("AP Detected", "Admin panel found!",
                Color3.fromRGB(0, 200, 115))
        end
    end
end)

Hub.APCommands = APCommands
Hub.APLog = APLog

-- ============================================================
-- [FINAL BOOT]
-- ============================================================
Log.info("Part 1C loaded ✔")
Log.info("Steal: 12 | Tracking: 10 | Utility: 13 | AP: 12")
Log.info("Total jobs:", #Scheduler.jobs)

task.defer(function()
    Hub.notify("Chronos Hub",
        "Chronos_1 fully loaded. Run Chronos_2 for UI.",
        Color3.fromRGB(0, 200, 115))
end)

end
warn("=== CHRONOS_1C-4B END ===")
warn("=== CHRONOS_1 COMPLETE — RUN CHRONOS_2 ===")