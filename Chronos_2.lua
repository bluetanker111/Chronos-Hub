--[[
    CHRONOS HUB — File 2, Part A
    Chunk 2A: Themes, Main Window, Tab Bar
]]

warn("=== CHRONOS_2A START ===")

local Hub = getgenv().ChronosHub
if not Hub or not Hub._booted then
    error("[CHRONOS_2A] Chronos_1 not loaded. Run it first.")
end

local Players          = Hub.Players
local RunService       = Hub.RunService
local TweenService     = Hub.TweenService
local UserInputService = Hub.UserInputService
local LocalPlayer      = Hub.LocalPlayer
local IsMobile         = Hub.IsMobile
local Log              = Hub.Log
local Store            = Hub.Store
local HUI              = Hub.HUI
local Scheduler        = Hub.Scheduler
local MutColor         = Hub.MutColor
local fmtMutation      = Hub.fmtMutation

-- ============================================================
-- [THEMES]
-- ============================================================
local Themes = {
    dark = {
        bg        = Color3.fromRGB(10, 12, 16),
        panel     = Color3.fromRGB(16, 18, 24),
        panelHi   = Color3.fromRGB(22, 25, 34),
        stroke    = Color3.fromRGB(38, 44, 58),
        accent    = Color3.fromRGB(0, 200, 115),
        accentHi  = Color3.fromRGB(0, 240, 140),
        text      = Color3.fromRGB(230, 235, 245),
        textDim   = Color3.fromRGB(140, 145, 165),
        danger    = Color3.fromRGB(255, 90, 90),
        warn      = Color3.fromRGB(255, 190, 80),
    },
    light = {
        bg        = Color3.fromRGB(240, 242, 248),
        panel     = Color3.fromRGB(255, 255, 255),
        panelHi   = Color3.fromRGB(245, 247, 252),
        stroke    = Color3.fromRGB(210, 216, 226),
        accent    = Color3.fromRGB(20, 140, 90),
        accentHi  = Color3.fromRGB(25, 170, 110),
        text      = Color3.fromRGB(30, 34, 44),
        textDim   = Color3.fromRGB(120, 126, 140),
        danger    = Color3.fromRGB(210, 70, 70),
        warn      = Color3.fromRGB(210, 150, 40),
    },
    contrast = {
        bg        = Color3.fromRGB(0, 0, 0),
        panel     = Color3.fromRGB(15, 15, 15),
        panelHi   = Color3.fromRGB(25, 25, 25),
        stroke    = Color3.fromRGB(255, 255, 0),
        accent    = Color3.fromRGB(255, 255, 0),
        accentHi  = Color3.fromRGB(255, 255, 255),
        text      = Color3.fromRGB(255, 255, 255),
        textDim   = Color3.fromRGB(200, 200, 200),
        danger    = Color3.fromRGB(255, 0, 0),
        warn      = Color3.fromRGB(255, 200, 0),
    },
}

local function theme()
    return Themes[Store.get("UITheme") or "dark"] or Themes.dark
end

-- ============================================================
-- [CLEANUP OLD UI]
-- ============================================================
local old = HUI:FindFirstChild("ChronosHubUI")
if old then old:Destroy() end
local oldToggle = HUI:FindFirstChild("ChronosHubToggle")
if oldToggle then oldToggle:Destroy() end

-- ============================================================
-- [MAIN SCREEN GUI]
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChronosHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = HUI

-- ============================================================
-- [MAIN FRAME]
-- ============================================================
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 520, 0, 420)
Main.Position = UDim2.new(0.5, -260, 0.5, -210)
Main.BackgroundColor3 = theme().bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = false
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Thickness = 1
mainStroke.Color = theme().stroke

-- Drag bar (top of window)
local DragBar = Instance.new("Frame", Main)
DragBar.Size = UDim2.new(1, 0, 0, 32)
DragBar.Position = UDim2.new(0, 0, 0, 0)
DragBar.BackgroundTransparency = 1
DragBar.Active = true
DragBar.Draggable = true

-- Title
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -80, 0, 32)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "CHRONOS HUB"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.TextColor3 = theme().text
Title.TextXAlignment = Enum.TextXAlignment.Left

local VersionLbl = Instance.new("TextLabel", Main)
VersionLbl.Size = UDim2.new(1, -80, 0, 14)
VersionLbl.Position = UDim2.new(0, 14, 0, 18)
VersionLbl.BackgroundTransparency = 1
VersionLbl.Text = "MOST POWERFUL HUB IN STEAL A BRAINROT"
VersionLbl.Font = Enum.Font.Gotham
VersionLbl.TextSize = 10
VersionLbl.TextColor3 = theme().textDim
VersionLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Palette button
local PaletteBtn = Instance.new("TextButton", Main)
PaletteBtn.Size = UDim2.new(0, 24, 0, 24)
PaletteBtn.Position = UDim2.new(1, -64, 0, 8)
PaletteBtn.BackgroundColor3 = theme().panel
PaletteBtn.BorderSizePixel = 0
PaletteBtn.Text = "⌘"
PaletteBtn.Font = Enum.Font.GothamBold
PaletteBtn.TextSize = 14
PaletteBtn.TextColor3 = theme().textDim
PaletteBtn.AutoButtonColor = false
Instance.new("UICorner", PaletteBtn).CornerRadius = UDim.new(0, 6)

-- Close button
local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.BackgroundColor3 = theme().panel
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = theme().textDim
CloseBtn.AutoButtonColor = false
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- ============================================================
-- [TAB BAR]
-- ============================================================
local TabBar = Instance.new("ScrollingFrame", Main)
TabBar.Size = UDim2.new(1, -20, 0, 30)
TabBar.Position = UDim2.new(0, 10, 0, 44)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.ScrollingDirection = Enum.ScrollingDirection.X
TabBar.ScrollBarThickness = 0

local tabLayout = Instance.new("UIListLayout", TabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)

-- Content area
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -20, 1, -88)
Content.Position = UDim2.new(0, 10, 0, 82)
Content.BackgroundTransparency = 1

-- ============================================================
-- [UI STATE TABLE]
-- ============================================================
local UI = {
    Pages = {},
    TabButtons = {},
    Main = Main,
    Content = Content,
    TabBar = TabBar,
    ScreenGui = ScreenGui,
    theme = theme,
    Themes = Themes,
}

function UI.applyTheme()
    local t = theme()
    for _, d in ipairs(ScreenGui:GetDescendants()) do
        local role = d:GetAttribute("themeRole")
        if role and t[role] then
            if d:IsA("GuiObject") and role ~= "stroke" then
                d.BackgroundColor3 = t[role]
            end
        end
        local textRole = d:GetAttribute("themeTextRole")
        if textRole and t[textRole]
        and (d:IsA("TextLabel")
        or d:IsA("TextButton")
        or d:IsA("TextBox")) then
            d.TextColor3 = t[textRole]
        end
        local strokeRole = d:GetAttribute("themeStrokeRole")
        if strokeRole and t[strokeRole] and d:IsA("UIStroke") then
            d.Color = t[strokeRole]
        end
    end
end

-- ============================================================
-- [BUILD PAGE]
-- ============================================================
function UI.buildPage(name)
    local page = Instance.new("ScrollingFrame", Content)
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = theme().accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 2

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 78, 1, 0)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = theme().textDim
    btn.BackgroundColor3 = theme().panel
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local s = Instance.new("UIStroke", btn)
    s.Thickness = 1
    s.Color = theme().stroke

    btn.MouseButton1Click:Connect(function()
        Store.set("CurrentTab", name)
    end)

    UI.Pages[name] = page
    UI.TabButtons[name] = btn
    return page
end

Store.subscribe("CurrentTab", function(name)
    for tabName, page in pairs(UI.Pages) do
        page.Visible = (tabName == name)
    end
    for tabName, btn in pairs(UI.TabButtons) do
        local active = (tabName == name)
        local t = theme()
        btn.BackgroundColor3 = active and t.accent or t.panel
        btn.TextColor3 = active and Color3.fromRGB(255, 255, 255)
                        or t.textDim
    end
end)

Hub.UI = UI
Hub.Themes = Themes
Hub.theme = theme
Hub.Main = Main
Hub.ScreenGui = ScreenGui
Hub.PaletteBtn = PaletteBtn
Hub.CloseBtn = CloseBtn
Hub.TabBar = TabBar
Hub.Title = Title
Hub.VersionLbl = VersionLbl
Hub.mainStroke = mainStroke

UI.applyTheme()
Log.info("Part 6A loaded ✔")
warn("=== CHRONOS_2A END ===")
--[[
    CHRONOS HUB — File 2, Part B
    Chunk 2B: makeToggle, makeSlider, makeButton, makeDropdown
]]

warn("=== CHRONOS_2B START ===")

local Hub = getgenv().ChronosHub
local TweenService     = Hub.TweenService
local UserInputService = Hub.UserInputService
local Log              = Hub.Log
local Store            = Hub.Store
local UI               = Hub.UI
local theme            = Hub.theme

-- ============================================================
-- [makeToggle]
-- ============================================================
function UI.makeToggle(page, key, label)
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl:SetAttribute("themeTextRole", "text")
    lbl:SetAttribute("themeRole", nil)

    local sw = Instance.new("TextButton", row)
    sw.Size = UDim2.new(0, 34, 0, 18)
    sw.Position = UDim2.new(1, -36, 0.5, -9)
    sw.BorderSizePixel = 0
    sw.Text = ""
    sw.AutoButtonColor = false
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", sw)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    Store.subscribe(key, function(value)
        local t = theme()
        local targetColor = value and t.accent or t.stroke
        local targetPos = value
            and UDim2.new(1, -14, 0.5, -6)
            or UDim2.new(0, 2, 0.5, -6)
        TweenService:Create(sw, TweenInfo.new(0.15),
            {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(dot, TweenInfo.new(0.15),
            {Position = targetPos}):Play()
        sw.BackgroundColor3 = targetColor
    end)

    sw.MouseButton1Click:Connect(function()
        Store.set(key, not Store.get(key))
    end)
    return sw
end

-- ============================================================
-- [makeSlider]
-- ============================================================
function UI.makeSlider(page, key, label, minVal, maxVal, suffix)
    suffix = suffix or ""
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl:SetAttribute("themeTextRole", "text")

    local bar = Instance.new("Frame", row)
    bar.Size = UDim2.new(1, -8, 0, 6)
    bar.Position = UDim2.new(0, 4, 0, 26)
    bar.BorderSizePixel = 0
    bar.BackgroundColor3 = theme().stroke
    bar:SetAttribute("themeRole", "stroke")
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BorderSizePixel = 0
    fill.BackgroundColor3 = theme().accent
    fill:SetAttribute("themeRole", "accent")
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function refresh(value)
        local range = maxVal - minVal
        local pct = range > 0 and (value - minVal) / range or 0
        pct = math.clamp(pct, 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        fill.BackgroundColor3 = theme().accent
        lbl.Text = label .. ": " .. tostring(value) .. suffix
    end
    Store.subscribe(key, refresh)

    local dragging = false
    local function setFromX(x)
        local absX = bar.AbsolutePosition.X
        local w = bar.AbsoluteSize.X
        if w <= 0 then return end
        local rel = math.clamp((x - absX) / w, 0, 1)
        local v = math.floor(minVal + (maxVal - minVal) * rel + 0.5)
        Store.set(key, v)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
-- [makeButton]
-- ============================================================
function UI.makeButton(page, label, callback)
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = theme().panel
    btn.TextColor3 = theme().text
    btn:SetAttribute("themeRole", "panel")
    btn:SetAttribute("themeTextRole", "text")
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local s = Instance.new("UIStroke", btn)
    s.Thickness = 1
    s.Color = theme().stroke
    s:SetAttribute("themeStrokeRole", "stroke")

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12),
            {BackgroundColor3 = theme().panelHi}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12),
            {BackgroundColor3 = theme().panel}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ============================================================
-- [makeDropdown]
-- ============================================================
function UI.makeDropdown(page, key, label, options)
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl:SetAttribute("themeTextRole", "text")

    local current = Instance.new("TextButton", row)
    current.Size = UDim2.new(0, 140, 0, 22)
    current.Position = UDim2.new(1, -140, 0.5, -11)
    current.BorderSizePixel = 0
    current.Font = Enum.Font.GothamBold
    current.TextSize = 10
    current.AutoButtonColor = false
    current.BackgroundColor3 = theme().panel
    current.TextColor3 = theme().text
    current:SetAttribute("themeRole", "panel")
    current:SetAttribute("themeTextRole", "text")
    Instance.new("UICorner", current).CornerRadius = UDim.new(0, 4)

    local listFrame
    local expanded = false

    local function collapse()
        if listFrame then
            listFrame:Destroy()
            listFrame = nil
        end
        expanded = false
    end

    local function expand()
        if expanded then return end
        expanded = true
        listFrame = Instance.new("Frame", page)
        listFrame.Size = UDim2.new(0, 140, 0, #options * 22)
        listFrame.Position = UDim2.new(
            1, -140, 0,
            (row.AbsolutePosition.Y - page.AbsolutePosition.Y + 24)
        )
        listFrame.BackgroundColor3 = theme().panelHi
        listFrame.BorderSizePixel = 0
        listFrame.ZIndex = 9999
        listFrame.ClipsDescendants = false
        listFrame:SetAttribute("themeRole", "panelHi")
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 4)

        local ls = Instance.new("UIStroke", listFrame)
        ls.Thickness = 1
        ls.Color = theme().stroke
        ls:SetAttribute("themeStrokeRole", "stroke")

        for i, opt in ipairs(options) do
            local ob = Instance.new("TextButton", listFrame)
            ob.Size = UDim2.new(1, 0, 0, 22)
            ob.Position = UDim2.new(0, 0, 0, (i - 1) * 22)
            ob.BackgroundTransparency = 1
            ob.Text = opt
            ob.Font = Enum.Font.GothamSemibold
            ob.TextSize = 10
            ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.TextColor3 = theme().text
            ob.ZIndex = 10000
            ob:SetAttribute("themeTextRole", "text")

            local pad = Instance.new("UIPadding", ob)
            pad.PaddingLeft = UDim.new(0, 8)

            ob.MouseButton1Click:Connect(function()
                Store.set(key, opt)
                collapse()
            end)
            ob.MouseEnter:Connect(function()
                ob.BackgroundTransparency = 0.85
                ob.BackgroundColor3 = theme().accent
            end)
            ob.MouseLeave:Connect(function()
                ob.BackgroundTransparency = 1
            end)
        end
    end

    Store.subscribe(key, function(v)
        current.Text = tostring(v)
    end)
    current.MouseButton1Click:Connect(function()
        if expanded then collapse() else expand() end
    end)
end

Log.info("Part 6B loaded ✔")
warn("=== CHRONOS_2B END ===")
--[[
    CHRONOS HUB — File 2, Part C
    Chunk 2C: Floating toggle button, Theme re-apply, UI scale,
              Drag handler, Command palette opener
]]

warn("=== CHRONOS_2C START ===")

local Hub = getgenv().ChronosHub
local TweenService     = Hub.TweenService
local UserInputService = Hub.UserInputService
local Log              = Hub.Log
local Store            = Hub.Store
local HUI              = Hub.HUI
local Scheduler        = Hub.Scheduler
local UI               = Hub.UI
local theme            = Hub.theme
local Main             = Hub.Main
local ScreenGui        = Hub.ScreenGui
local PaletteBtn       = Hub.PaletteBtn
local CloseBtn         = Hub.CloseBtn
local Title            = Hub.Title
local VersionLbl       = Hub.VersionLbl
local mainStroke       = Hub.mainStroke

-- ============================================================
-- [FLOATING TOGGLE BUTTON]
-- ============================================================
local ToggleGui = HUI:FindFirstChild("ChronosHubToggle")
if not ToggleGui then
    ToggleGui = Instance.new("ScreenGui")
    ToggleGui.Name = "ChronosHubToggle"
    ToggleGui.ResetOnSpawn = false
    ToggleGui.DisplayOrder = 999999
    ToggleGui.IgnoreGuiInset = true
    ToggleGui.Parent = HUI
end

local Float = Instance.new("TextButton", ToggleGui)
Float.Size = UDim2.new(0, 46, 0, 46)
Float.Position = UDim2.new(0, 20, 0.3, 0)
Float.BackgroundColor3 = theme().panel
Float.BorderSizePixel = 0
Float.Text = "C"
Float.Font = Enum.Font.GothamBlack
Float.TextSize = 18
Float.TextColor3 = theme().accent
Float.AutoButtonColor = false
Instance.new("UICorner", Float).CornerRadius = UDim.new(1, 0)

local fs = Instance.new("UIStroke", Float)
fs.Thickness = 1
fs.Color = theme().stroke

local dragging, dragStart, startPos, moved = false, nil, nil, false

Float.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        dragStart = input.Position
        startPos = Float.Position
    end
end)

Float.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        if delta.Magnitude > 4 then moved = true end
        Float.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

Float.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        if not moved then
            Main.Visible = not Main.Visible
        end
    end
end)

-- ============================================================
-- [MAIN WINDOW DRAG HANDLER]
-- ============================================================
local mainDragging, mainDragStart, mainStartPos = false, nil, nil

local dragHandle = Main:FindFirstChild("DragBar")

if dragHandle then
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            mainDragging = true
            mainDragStart = input.Position
            mainStartPos = Main.Position
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if not mainDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - mainDragStart
            Main.Position = UDim2.new(
                mainStartPos.X.Scale,
                mainStartPos.X.Offset + delta.X,
                mainStartPos.Y.Scale,
                mainStartPos.Y.Offset + delta.Y
            )
        end
    end)

    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            mainDragging = false
        end
    end)
end

-- ============================================================
-- [THEME RE-APPLY]
-- ============================================================
Store.subscribe("UITheme", function()
    local t = theme()
    Main.BackgroundColor3 = t.bg
    mainStroke.Color = t.stroke
    Title.TextColor3 = t.text
    VersionLbl.TextColor3 = t.textDim
    PaletteBtn.BackgroundColor3 = t.panel
    PaletteBtn.TextColor3 = t.textDim
    CloseBtn.BackgroundColor3 = t.panel
    CloseBtn.TextColor3 = t.textDim
    Float.BackgroundColor3 = t.panel
    Float.TextColor3 = t.accent
    fs.Color = t.stroke
    UI.applyTheme()
end)

-- ============================================================
-- [UI SCALE]
-- ============================================================
Scheduler.add("uiScaleTick", 1, 90, function()
    local s = Store.get("UIScale") or 1.0
    local scale = Main:FindFirstChildOfClass("UIScale")
    if not scale then
        scale = Instance.new("UIScale", Main)
    end
    scale.Scale = s
end)

-- ============================================================
-- [UI OPACITY]
-- ============================================================
Store.subscribe("UIOpacity", function(v)
    if Main then
        Main.BackgroundTransparency =
            math.clamp(tonumber(v) or 0.05, 0, 1)
    end
end)

-- ============================================================
-- [EXPORT]
-- ============================================================
Hub.Float = Float
Hub.ToggleGui = ToggleGui

Log.info("Part 6C loaded ✔")
warn("=== CHRONOS_2C END ===")
--[[
    CHRONOS HUB — File 2, Part D
    Chunk 2D-1: All tabs (Steal, ESP, Protect, Render, Notify,
                Extras, AP, Advanced, Slots, Config)
]]

warn("=== CHRONOS_2D-1 START ===")

local Hub = getgenv().ChronosHub
local Players          = Hub.Players
local LocalPlayer      = Hub.LocalPlayer
local UserInputService = Hub.UserInputService
local HttpService      = Hub.HttpService
local Log              = Hub.Log
local Store            = Hub.Store
local UI               = Hub.UI
local theme            = Hub.theme
local notify           = Hub.notify
local serverHop        = Hub.serverHop
local rejoin           = Hub.rejoin
local APCommands       = Hub.APCommands

-- ============================================================
-- [BUILD ALL TABS]
-- ============================================================
local pSteal   = UI.buildPage("Steal")
local pESP     = UI.buildPage("ESP")
local pProtect = UI.buildPage("Protect")
local pRender  = UI.buildPage("Render")
local pNotify  = UI.buildPage("Notify")
local pExtras  = UI.buildPage("Extras")
local pAP      = UI.buildPage("AP")
local pAdv     = UI.buildPage("Advanced")
local pSlots   = UI.buildPage("Slots")
local pConfig  = UI.buildPage("Config")

-- ============================================================
-- [STEAL TAB]
-- ============================================================
UI.makeToggle(pSteal, "AutoGrab", "Auto Grab")
UI.makeToggle(pSteal, "InstantSteal", "Instant Grab (0s hold)")
UI.makeToggle(pSteal, "HoldSteal", "Hold Steal Loop")
UI.makeToggle(pSteal, "PredictiveGrab", "Predictive Grab")
UI.makeToggle(pSteal, "AutoInvisDuringSteal", "Auto-Invis During Steal")
UI.makeToggle(pSteal, "AutoUnlockDuringSteal", "Auto-Unlock During Steal")
UI.makeToggle(pSteal, "AutoWalkspeedOnSteal", "Auto-WS on Steal")
UI.makeToggle(pSteal, "AutoCloneAfterTP", "Auto-Clone After TP")
UI.makeToggle(pSteal, "ContinuousTP", "Continuous TP")
UI.makeToggle(pSteal, "AutoUnlockDoors", "Auto Unlock Doors")
UI.makeToggle(pSteal, "AutoLockBase", "Auto Lock Base")
UI.makeToggle(pSteal, "AutoBuyCarpet", "Auto-Buy Carpets")
UI.makeSlider(pSteal, "GrabRadius", "Grab Radius", 10, 150, " studs")
UI.makeSlider(pSteal, "MinValueMillions", "Min Value", 0, 500, "M/s")
UI.makeSlider(pSteal, "AutoBuyRadius", "Auto-Buy Radius", 10, 150, " studs")
UI.makeSlider(pSteal, "AutoSellThresholdM", "Auto-Sell Threshold", 0, 5000, "M/s")
UI.makeDropdown(pSteal, "SortMode", "Sort Mode", {"Nearest", "Highest", "Priority"})

-- ============================================================
-- [ESP TAB]
-- ============================================================
UI.makeToggle(pESP, "BrainrotESP", "Brainrot ESP")
UI.makeToggle(pESP, "StealerESP", "Stealer Highlight")
UI.makeToggle(pESP, "IncomingPredictor", "Incoming Slot Marker")
UI.makeToggle(pESP, "PlayerTrackerPanel", "Player Tracker Panel")
UI.makeToggle(pESP, "BaseOwnershipPanel", "Base Ownership Panel")
UI.makeToggle(pESP, "DistanceRadar", "Distance Radar")
UI.makeToggle(pESP, "PetMoveDetection", "Pet Move Detection")
UI.makeSlider(pESP, "ESPMaxDistance", "ESP Max Distance", 50, 2000, " studs")
UI.makeSlider(pESP, "ESPInterval", "ESP Refresh", 1, 50, " x10 ms")

-- Pet move watch name
local watchBox = Instance.new("TextBox", pESP)
watchBox.Size = UDim2.new(1, 0, 0, 28)
watchBox.BorderSizePixel = 0
watchBox.PlaceholderText = "Pet name to watch for movement..."
watchBox.Text = Store.get("PetMoveWatchName") or ""
watchBox.Font = Enum.Font.GothamSemibold
watchBox.TextSize = 11
watchBox.ClearTextOnFocus = false
watchBox.BackgroundColor3 = theme().panel
watchBox.TextColor3 = theme().text
watchBox:SetAttribute("themeRole", "panel")
watchBox:SetAttribute("themeTextRole", "text")
Instance.new("UICorner", watchBox).CornerRadius = UDim.new(0, 6)
watchBox.FocusLost:Connect(function()
    Store.set("PetMoveWatchName", watchBox.Text)
end)

-- ============================================================
-- [PROTECT TAB]
-- ============================================================
UI.makeToggle(pProtect, "AntiRagdoll", "Anti-Ragdoll")
UI.makeToggle(pProtect, "AntiDie", "Anti-Die")
UI.makeToggle(pProtect, "AntiFling", "Anti-Fling")
UI.makeToggle(pProtect, "AntiBodySwap", "Anti-Body-Swap")
UI.makeToggle(pProtect, "InfiniteJump", "Infinite Jump")
UI.makeToggle(pProtect, "IdleDetection", "Idle Detection")
UI.makeToggle(pProtect, "AntiIdleTeleport", "Anti-Teleport")
UI.makeToggle(pProtect, "RoamProtection", "Roam Protection")
UI.makeToggle(pProtect, "SafeMode", "Safe Mode")
UI.makeSlider(pProtect, "WalkSpeedValue", "Walk Speed", 16, 200)
UI.makeSlider(pProtect, "IdleTimeoutSec", "Idle Timeout", 30, 900, "s")
UI.makeSlider(pProtect, "RoamMaxDistance", "Roam Radius", 100, 1000, " studs")

-- ============================================================
-- [RENDER TAB]
-- ============================================================
UI.makeToggle(pRender, "RemoveAccessories", "Remove Accessories")
UI.makeToggle(pRender, "RemoveAnimations", "Remove Animators")
UI.makeToggle(pRender, "VisualCleanup", "Visual Cleanup")
UI.makeToggle(pRender, "FPSOptimizer", "FPS Boost")
UI.makeToggle(pRender, "FPSDarkMode", "Dark Mode")
UI.makeDropdown(pRender, "TPTool", "TP Tool",
    {"Flying Carpet", "Santa's Sleigh", "Witch's Broom",
     "Cupid's Wings", "Waverider"})

-- ============================================================
-- [NOTIFY TAB]
-- ============================================================
UI.makeToggle(pNotify, "NotifyEnabled", "Popup Notifications")
UI.makeToggle(pNotify, "SoundEnabled", "Sound Alert")
UI.makeToggle(pNotify, "AutoKickEnabled", "Auto-Kick on Steal")
UI.makeToggle(pNotify, "WebhookEnabled", "Discord Webhook")
UI.makeSlider(pNotify, "NotifyMinMillions", "Notify Threshold", 0, 500, "M/s")
UI.makeSlider(pNotify, "WebhookMinMillions", "Webhook Threshold", 0, 1000, "M/s")

-- Test notification buttons
UI.makeButton(pNotify, "Test Notification", function()
    notify("Test", "Notifications are working",
        Color3.fromRGB(0, 200, 115))
end)
UI.makeButton(pNotify, "Test Sound", function()
    local prev = Store.get("SoundEnabled")
    Store.set("SoundEnabled", true)
    Hub.playAlert()
    task.delay(0.5, function()
        Store.set("SoundEnabled", prev)
    end)
end)

-- Webhook URL box
local urlBox = Instance.new("TextBox", pNotify)
urlBox.Size = UDim2.new(1, 0, 0, 28)
urlBox.BorderSizePixel = 0
urlBox.PlaceholderText = "Paste Discord webhook URL..."
urlBox.Text = Store.get("WebhookURL") or ""
urlBox.Font = Enum.Font.Code
urlBox.TextSize = 10
urlBox.ClearTextOnFocus = false
urlBox.BackgroundColor3 = theme().panel
urlBox.TextColor3 = theme().text
urlBox:SetAttribute("themeRole", "panel")
urlBox:SetAttribute("themeTextRole", "text")
Instance.new("UICorner", urlBox).CornerRadius = UDim.new(0, 6)
urlBox.FocusLost:Connect(function()
    Store.set("WebhookURL", urlBox.Text)
end)
UI.makeButton(pNotify, "Test Webhook", function()
    if Hub.sendWebhook then
        Hub.sendWebhook({username = "Chronos Hub",
            content = "Test from Chronos Hub"})
        notify("Webhook", "Test sent", theme().accent)
    end
end)

-- ============================================================
-- [EXTRAS TAB]
-- ============================================================
UI.makeToggle(pExtras, "ChatLogger", "Chat Logger")
UI.makeToggle(pExtras, "StatsEnabled", "Show Stats HUD")
UI.makeToggle(pExtras, "PerfOverlay", "Performance Overlay")

UI.makeButton(pExtras, "Server Hop", function()
    if serverHop then serverHop() end
end)
UI.makeButton(pExtras, "Rejoin Same Server", function()
    if rejoin then rejoin() end
end)
UI.makeButton(pExtras, "Job ID Spammer", function()
    if Hub.toggleJobIdSpam then Hub.toggleJobIdSpam() end
end)
UI.makeButton(pExtras, "Panic (disable all dangerous)", function()
    if Hub.panicButton then Hub.panicButton() end
end)
UI.makeButton(pExtras, "Unpanic (restore)", function()
    if Hub.unpanic then Hub.unpanic() end
end)
UI.makeButton(pExtras, "Export Log to File", function()
    if Hub.exportLog then Hub.exportLog()
    else
        pcall(function()
            writefile("ChronosHub_Log.txt", Log.export())
        end)
        notify("Log", "Exported", theme().accent)
    end
end)

-- ============================================================
-- [AP TAB]
-- ============================================================
UI.makeToggle(pAP, "ProximityAP", "Proximity AP (auto on nearby)")
UI.makeToggle(pAP, "APBlacklistEnabled", "Use AP Blacklist")
UI.makeSlider(pAP, "ProximityAPRadius", "Proximity Range", 5, 50, " studs")
UI.makeDropdown(pAP, "ProximityAPCommand", "Proximity Command", APCommands)
UI.makeDropdown(pAP, "ClickAPCommand", "Click-to-AP Command", APCommands)

UI.makeButton(pAP, "Toggle Click-to-AP Mode", function()
    if Hub.toggleClickAP then Hub.toggleClickAP() end
end)
UI.makeButton(pAP, "Spam Nearest Base Owner", function()
    if Hub.spamBaseOwner then Hub.spamBaseOwner() end
end)
UI.makeButton(pAP, "Fire AP on All Players", function()
    if Hub.fireAPAll then
        local cmd = Store.get("ProximityAPCommand") or "balloon"
        Hub.fireAPAll(cmd)
    end
end)

local apStatusLbl = Instance.new("TextLabel", pAP)
apStatusLbl.Size = UDim2.new(1, 0, 0, 22)
apStatusLbl.BackgroundTransparency = 1
apStatusLbl.Font = Enum.Font.GothamSemibold
apStatusLbl.TextSize = 11
apStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
apStatusLbl.Text = "Checking AP panel..."
apStatusLbl.TextColor3 = theme().warn
apStatusLbl:SetAttribute("themeTextRole", "text")

Hub.Scheduler.add("apStatusUI", 1, 60, function()
    if Hub.hasAP and Hub.hasAP() then
        apStatusLbl.Text = "✓ AP panel detected"
        apStatusLbl.TextColor3 = theme().accent
    else
        apStatusLbl.Text = "No AP panel — using remote methods"
        apStatusLbl.TextColor3 = theme().warn
    end
end)

-- ============================================================
-- [ADVANCED TAB]
-- ============================================================
UI.makeToggle(pAdv, "HoldSteal", "Hold Steal (alt)")
UI.makeToggle(pAdv, "PredictiveGrab", "Predictive Grab (alt)")
UI.makeDropdown(pAdv, "UITheme", "Theme", {"dark", "light", "contrast"})
UI.makeSlider(pAdv, "UIScale", "UI Scale", 50, 200, "%")
UI.makeSlider(pAdv, "UIOpacity", "UI Opacity", 0, 95, "%")
UI.makeButton(pAdv, "Reset UI Position", function()
    if Hub.Main then
        Hub.Main.Position = UDim2.new(0.5, -260, 0.5, -210)
    end
end)

-- ============================================================
-- [SLOTS TAB]
-- ============================================================
local slotNameBox = Instance.new("TextBox", pSlots)
slotNameBox.Size = UDim2.new(1, 0, 0, 28)
slotNameBox.BorderSizePixel = 0
slotNameBox.PlaceholderText = "Slot name (e.g. farm, pvp)..."
slotNameBox.Text = ""
slotNameBox.Font = Enum.Font.GothamSemibold
slotNameBox.TextSize = 11
slotNameBox.ClearTextOnFocus = false
slotNameBox.BackgroundColor3 = theme().panel
slotNameBox.TextColor3 = theme().text
slotNameBox:SetAttribute("themeRole", "panel")
slotNameBox:SetAttribute("themeTextRole", "text")
Instance.new("UICorner", slotNameBox).CornerRadius = UDim.new(0, 6)

UI.makeButton(pSlots, "Save as Slot", function()
    local name = slotNameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        notify("Slot", "Enter a name first", theme().warn)
        return
    end
    local slots = Store.get("ConfigSlots") or {}
    slots[name] = Store.snapshot()
    Store.set("ConfigSlots", slots)
    notify("Slot", "Saved: " .. name, theme().accent)
end)

-- ============================================================
-- [CONFIG TAB]
-- ============================================================
local exportBox = Instance.new("TextBox", pConfig)
exportBox.Size = UDim2.new(1, 0, 0, 100)
exportBox.BorderSizePixel = 0
exportBox.Text = ""
exportBox.PlaceholderText = "Config JSON appears here..."
exportBox.Font = Enum.Font.Code
exportBox.TextSize = 10
exportBox.TextWrapped = true
exportBox.ClearTextOnFocus = false
exportBox.BackgroundColor3 = theme().panel
exportBox.TextColor3 = theme().text
exportBox:SetAttribute("themeRole", "panel")
exportBox:SetAttribute("themeTextRole", "text")
Instance.new("UICorner", exportBox).CornerRadius = UDim.new(0, 6)

UI.makeButton(pConfig, "Export to Box + Clipboard", function()
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(Store.snapshot())
    end)
    if not ok or not encoded then
        notify("Export", "Encoding failed", theme().danger)
        return
    end
    exportBox.Text = encoded
    pcall(function() setclipboard(encoded) end)
    notify("Export", "Config copied to clipboard", theme().accent)
end)

UI.makeButton(pConfig, "Import from Box", function()
    local raw = exportBox.Text
    if not raw or raw == "" then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok or type(data) ~= "table" then
        notify("Import", "Invalid JSON", theme().danger)
        return
    end
    for k, v in pairs(data) do
        if k ~= "_version" then Store.set(k, v) end
    end
    notify("Import", "Config applied", theme().accent)
end)

UI.makeButton(pConfig, "Reset All Settings", function()
    for k, v in pairs(Hub.DEFAULTS) do
        Store.set(k, v)
    end
    notify("Config", "Reset to defaults", theme().warn)
end)

Hub.pSteal   = pSteal
Hub.pESP     = pESP
Hub.pProtect = pProtect
Hub.pRender  = pRender
Hub.pNotify  = pNotify
Hub.pExtras  = pExtras
Hub.pAP      = pAP
Hub.pAdv     = pAdv
Hub.pSlots   = pSlots
Hub.pConfig  = pConfig

Log.info("All tabs built ✔")
warn("=== CHRONOS_2D-1 END ===")
--[[
    CHRONOS HUB — File 2, Part D
    Chunk 2D-2: Presets, Command Palette, ESP Pool, Final Boot
]]

warn("=== CHRONOS_2D-2 START ===")

local Hub = getgenv().ChronosHub
local Players          = Hub.Players
local LocalPlayer      = Hub.LocalPlayer
local UserInputService = Hub.UserInputService
local TweenService     = Hub.TweenService
local Log              = Hub.Log
local Store            = Hub.Store
local HUI              = Hub.HUI
local Scheduler        = Hub.Scheduler
local UI               = Hub.UI
local theme            = Hub.theme
local notify           = Hub.notify
local scanAllPets      = Hub.scanAllPets
local MutColor         = Hub.MutColor
local fmtMutation      = Hub.fmtMutation
local ScreenGui        = Hub.ScreenGui
local PaletteBtn       = Hub.PaletteBtn

-- ============================================================
-- [PRESETS]
-- ============================================================
local pPresets = UI.buildPage("Presets")

local Presets = {
    AFK = {
        AutoGrab = true, InstantSteal = false, HoldSteal = false,
        PredictiveGrab = true, SortMode = "Nearest",
        NotifyEnabled = true, SoundEnabled = true,
        AntiRagdoll = true, AntiDie = true, InfiniteJump = true,
        RemoveAccessories = true, RemoveAnimations = true,
        BrainrotESP = false, StealerESP = false,
    },
    Aggressive = {
        AutoGrab = true, InstantSteal = true, HoldSteal = true,
        PredictiveGrab = true, SortMode = "Priority",
        NotifyEnabled = true, SoundEnabled = true,
        AntiRagdoll = true, AntiDie = true, InfiniteJump = true,
        RemoveAccessories = true, RemoveAnimations = true,
        BrainrotESP = true, StealerESP = true,
        AutoInvisDuringSteal = true, AutoUnlockDuringSteal = true,
        AutoWalkspeedOnSteal = true, ContinuousTP = true,
    },
    Passive = {
        AutoGrab = false, InstantSteal = false, HoldSteal = false,
        PredictiveGrab = false, SortMode = "Nearest",
        NotifyEnabled = true, SoundEnabled = false,
        AntiRagdoll = true, AntiDie = false, InfiniteJump = false,
        RemoveAccessories = false, RemoveAnimations = false,
        BrainrotESP = true, StealerESP = true,
    },
}

local function applyPreset(name)
    local p = Presets[name]
    if not p then return end
    for k, v in pairs(p) do Store.set(k, v) end
    notify("Preset Applied", name, theme().accent)
end

for name in pairs(Presets) do
    UI.makeButton(pPresets, "Apply: " .. name, function()
        applyPreset(name)
    end)
end

UI.makeButton(pPresets, "Save Current as Custom", function()
    Presets.Custom = Store.snapshot()
    notify("Preset Saved", "Custom", theme().accent)
end)
UI.makeButton(pPresets, "Apply Custom", function()
    if not Presets.Custom then
        notify("Preset", "No custom preset saved yet", theme().warn)
        return
    end
    for k, v in pairs(Presets.Custom) do
        if k ~= "_version" then Store.set(k, v) end
    end
    notify("Preset Applied", "Custom", theme().accent)
end)

-- ============================================================
-- [COMMAND PALETTE]
-- ============================================================
local paletteGui = Instance.new("Frame", ScreenGui)
paletteGui.Size = UDim2.new(0, 400, 0, 320)
paletteGui.Position = UDim2.new(0.5, -200, 0.4, -160)
paletteGui.BackgroundColor3 = theme().bg
paletteGui.BorderSizePixel = 0
paletteGui.Visible = false
paletteGui.ZIndex = 100000
Instance.new("UICorner", paletteGui).CornerRadius = UDim.new(0, 10)

local palStroke = Instance.new("UIStroke", paletteGui)
palStroke.Thickness = 1.5
palStroke.Color = theme().accent

local palInput = Instance.new("TextBox", paletteGui)
palInput.Size = UDim2.new(1, -16, 0, 32)
palInput.Position = UDim2.new(0, 8, 0, 8)
palInput.BorderSizePixel = 0
palInput.PlaceholderText = "Type a command... (esc to close)"
palInput.Font = Enum.Font.GothamSemibold
palInput.TextSize = 12
palInput.Text = ""
palInput.ClearTextOnFocus = false
palInput.BackgroundColor3 = theme().panel
palInput.TextColor3 = theme().text
Instance.new("UICorner", palInput).CornerRadius = UDim.new(0, 6)

local palPad = Instance.new("UIPadding", palInput)
palPad.PaddingLeft = UDim.new(0, 10)

local palList = Instance.new("ScrollingFrame", paletteGui)
palList.Size = UDim2.new(1, -16, 1, -48)
palList.Position = UDim2.new(0, 8, 0, 44)
palList.BackgroundTransparency = 1
palList.BorderSizePixel = 0
palList.ScrollBarThickness = 2
palList.CanvasSize = UDim2.new(0, 0, 0, 0)
palList.AutomaticCanvasSize = Enum.AutomaticSize.Y

local paletteCatalog = {}

local function rebuildCatalog()
    paletteCatalog = {}
    for k, v in pairs(Store.snapshot()) do
        if type(v) == "boolean" then
            table.insert(paletteCatalog, {
                label = "Toggle: " .. k,
                action = function() Store.set(k, not Store.get(k)) end,
            })
        end
    end
    table.insert(paletteCatalog, {
        label = "Action: Server Hop",
        action = function()
            if Hub.serverHop then Hub.serverHop() end
        end,
    })
    table.insert(paletteCatalog, {
        label = "Action: Rejoin",
        action = function()
            if Hub.rejoin then Hub.rejoin() end
        end,
    })
    table.insert(paletteCatalog, {
        label = "Action: Panic",
        action = function()
            if Hub.panicButton then Hub.panicButton() end
        end,
    })
    for presetName in pairs(Presets) do
        table.insert(paletteCatalog, {
            label = "Preset: " .. presetName,
            action = function() applyPreset(presetName) end,
        })
    end
    for themeName in pairs(Hub.Themes) do
        table.insert(paletteCatalog, {
            label = "Theme: " .. themeName,
            action = function() Store.set("UITheme", themeName) end,
        })
    end
end
rebuildCatalog()

local function fuzzyMatch(query, target)
    query = query:lower()
    target = target:lower()
    if query == "" then return true end
    if target:find(query, 1, true) then return true end
    local qi = 1
    for i = 1, #target do
        if target:sub(i, i) == query:sub(qi, qi) then
            qi = qi + 1
            if qi > #query then return true end
        end
    end
    return false
end

local function refreshPalette()
    for _, c in ipairs(palList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local q = palInput.Text
    local shown = 0
    for _, item in ipairs(paletteCatalog) do
        if fuzzyMatch(q, item.label) and shown < 50 then
            shown = shown + 1
            local b = Instance.new("TextButton", palList)
            b.Size = UDim2.new(1, 0, 0, 26)
            b.BorderSizePixel = 0
            b.Text = item.label
            b.Font = Enum.Font.GothamSemibold
            b.TextSize = 11
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.BackgroundTransparency = 0.85
            b.BackgroundColor3 = theme().panel
            b.TextColor3 = theme().text
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

            local p = Instance.new("UIPadding", b)
            p.PaddingLeft = UDim.new(0, 8)

            b.MouseEnter:Connect(function()
                b.BackgroundTransparency = 0.5
                b.BackgroundColor3 = theme().accent
            end)
            b.MouseLeave:Connect(function()
                b.BackgroundTransparency = 0.85
                b.BackgroundColor3 = theme().panel
            end)
            b.MouseButton1Click:Connect(function()
                local ok, err = pcall(item.action)
                if not ok then
                    notify("Palette", "Failed: " .. tostring(err),
                        theme().danger)
                else
                    notify("Palette", "Ran: " .. item.label,
                        theme().accent)
                end
                paletteGui.Visible = false
                palInput.Text = ""
            end)
        end
    end
    palList.CanvasSize = UDim2.new(0, 0, 0, shown * 28 + 4)
end

palInput:GetPropertyChangedSignal("Text"):Connect(refreshPalette)

local function togglePalette()
    paletteGui.Visible = not paletteGui.Visible
    if paletteGui.Visible then
        palInput.Text = ""
        refreshPalette()
        palInput:CaptureFocus()
    else
        palInput:ReleaseFocus()
    end
end

Hub.togglePalette = togglePalette

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            togglePalette()
        end
    elseif input.KeyCode == Enum.KeyCode.Escape and paletteGui.Visible then
        paletteGui.Visible = false
    end
end)

PaletteBtn.MouseButton1Click:Connect(togglePalette)

-- ============================================================
-- [ESP POOL]
-- ============================================================
local ESP_POOL_SIZE = 40
local ESPPool = {available = {}, active = {}}

local function makePooledBillboard()
    local gui = Instance.new("BillboardGui")
    gui.Name = "ChronosEspPooled"
    gui.AlwaysOnTop = true
    gui.Size = UDim2.new(0, 170, 0, 40)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.MaxDistance = Store.get("ESPMaxDistance") or 500
    gui.Enabled = false
    gui.Parent = HUI

    local lbl = Instance.new("TextLabel", gui)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0.3
    lbl.RichText = true
    return {gui = gui, lbl = lbl}
end

for _ = 1, ESP_POOL_SIZE do
    table.insert(ESPPool.available, makePooledBillboard())
end

local function acquireBillboard()
    local entry = table.remove(ESPPool.available)
    if not entry then entry = makePooledBillboard() end
    entry.gui.Enabled = true
    return entry
end

local function releaseBillboard(entry)
    entry.gui.Enabled = false
    entry.gui.Adornee = nil
    entry.lbl.Text = ""
    table.insert(ESPPool.available, entry)
end

local function releaseAll()
    for part, entry in pairs(ESPPool.active) do
        releaseBillboard(entry)
        ESPPool.active[part] = nil
    end
end

Scheduler.add("espTick", 2, 20, function()
    if not Store.get("BrainrotESP") then
        if next(ESPPool.active) then releaseAll() end
        return
    end
    local maxDist = Store.get("ESPMaxDistance") or 500
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then releaseAll() return end

    local seen = {}
    local pets = scanAllPets(0)
    local spawned = 0

    for _, pet in ipairs(pets) do
        if spawned >= ESP_POOL_SIZE then break end
        local part = pet.part
        if part and part.Parent then
            local dist = (root.Position - part.Position).Magnitude
            if dist <= maxDist then
                seen[part] = true
                local entry = ESPPool.active[part]
                if not entry then
                    entry = acquireBillboard()
                    entry.gui.Adornee = part
                    entry.gui.MaxDistance = maxDist
                    ESPPool.active[part] = entry
                    spawned = spawned + 1
                end
                local mutColor = MutColor[pet.mutation]
                    or Color3.fromRGB(255, 215, 0)
                local fmtVal = pet.value >= 1e9
                    and string.format("%.2fB", pet.value / 1e9)
                    or pet.value >= 1e6
                    and string.format("%.1fM", pet.value / 1e6)
                    or tostring(pet.value)
                entry.lbl.Text = fmtMutation(pet.mutation,
                    tostring(pet.name):upper()) ..
                    "\n<font color='rgb(0,255,100)'>$"
                    .. fmtVal .. "/s</font>"
                entry.lbl.TextColor3 = mutColor
            end
        end
    end

    for part, entry in pairs(ESPPool.active) do
        if not seen[part] or not part.Parent then
            releaseBillboard(entry)
            ESPPool.active[part] = nil
        end
    end
end)

Store.subscribe("ESPInterval", function(v)
    v = math.clamp(tonumber(v) or 5, 1, 50)
    Scheduler.setRate("espTick", 10 / v)
end)

Scheduler.add("espOrphanSweep", 0.2, 95, function()
    for part, entry in pairs(ESPPool.active) do
        if not part.Parent then
            releaseBillboard(entry)
            ESPPool.active[part] = nil
        end
    end
end)

Hub.ESPPool = ESPPool
Hub.releaseAllESP = releaseAll

-- ============================================================
-- [FINAL BOOT]
-- ============================================================
Log.info("Part 6D loaded ✔")
Log.info("Tabs:", #(function()
    local n = 0
    for _ in pairs(UI.Pages) do n = n + 1 end
    return {n = n}
end)(), "pages registered")

task.defer(function()
    notify("Chronos Hub",
        "UI ready — press Ctrl+P for palette",
        Color3.fromRGB(0, 200, 115))
end)

Hub.Presets = Presets
Hub.applyPreset = applyPreset

warn("=== CHRONOS_2D-2 END ===")
warn("=== CHRONOS_2 COMPLETE — RUN CHRONOS_3 ===")