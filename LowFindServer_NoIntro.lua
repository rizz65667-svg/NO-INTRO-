local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Detector handler untuk queue_on_teleport
local queueOnTeleport = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

-- Helper Global Sound
local function playSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(soundId)
    sound.Volume = volume or 1
    sound.Parent = CoreGui
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local TeleportService = game:GetService("TeleportService")
    local UserInputService = game:GetService("UserInputService")

    -- ============================================================
    -- HTTP REQUEST HANDLER
    -- ============================================================
    local requestFunc = nil
    if syn and syn.request then
        requestFunc = syn.request
    elseif http and http.request then
        requestFunc = http.request
    elseif http_request then
        requestFunc = http_request
    elseif fluxus and fluxus.request then
        requestFunc = fluxus.request
    elseif request then
        requestFunc = request
    else
        error("No supported HTTP request function found!")
    end

    -- ============================================================
    -- CONFIGURATION & COMPACT RED-BLACK THEME
    -- ============================================================
    local CONFIG = {
        Colors = {
            Base1 = Color3.fromRGB(12, 10, 10),
            Base2 = Color3.fromRGB(38, 12, 15),
            Panel = Color3.fromRGB(18, 14, 14),
            Row = Color3.fromRGB(26, 18, 20),
            Red = Color3.fromRGB(255, 30, 50),
            RedDim = Color3.fromRGB(130, 50, 60),
            Glow = Color3.fromRGB(255, 0, 40),
            TextPrimary = Color3.fromRGB(245, 240, 240),
            TextSecondary = Color3.fromRGB(170, 150, 155),
            Danger = Color3.fromRGB(235, 50, 50),
            Success = Color3.fromRGB(60, 210, 120),
            Verified = Color3.fromRGB(0, 200, 255),
        },

        IslandSize = UDim2.new(0, 80, 0, 30),
        PanelSize = UDim2.new(0, 320, 0, 400),
        TopOffset = 14,

        AnimTime = 0.32,
        EasingStyle = Enum.EasingStyle.Quint,
        EasingDirection = Enum.EasingDirection.Out,
    }

    -- ============================================================
    -- CLEANUP OLD INSTANCE
    -- ============================================================
    local targetParent = CoreGui
    if targetParent:FindFirstChild("ServerFinderDynamicUI") then
        targetParent.ServerFinderDynamicUI:Destroy()
    end

    -- ============================================================
    -- SHARED STATE & HELPERS
    -- ============================================================
    _G.ServerFinderUI = _G.ServerFinderUI or {}
    _G.ServerFinderUI.Settings = {
        UIScale = 0.9,
    }

    local filterMode = "ALL"

    local function tween(obj, props, time, style, direction)
        local t = TweenService:Create(obj, TweenInfo.new(
            time or CONFIG.AnimTime,
            style or CONFIG.EasingStyle,
            direction or CONFIG.EasingDirection
        ), props)
        t:Play()
        return t
    end

    local function corner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 12)
        c.Parent = parent
        return c
    end

    local function stroke(parent, color, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = color or CONFIG.Colors.Red
        s.Thickness = thickness or 1.8
        s.Transparency = transparency or 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = parent
        return s
    end

    local function gradient(parent, c1, c2, rotation)
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new(c1, c2)
        g.Rotation = rotation or 55
        g.Parent = parent
        return g
    end

    local function pad(parent, l, r, t, b)
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, l or 10)
        p.PaddingRight = UDim.new(0, r or 10)
        p.PaddingTop = UDim.new(0, t or 6)
        p.PaddingBottom = UDim.new(0, b or 6)
        p.Parent = parent
        return p
    end

    local function clearContainer(container)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end

    -- ============================================================
    -- ROOT GUI
    -- ============================================================
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ServerFinderDynamicUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = targetParent

    local RootScale = Instance.new("UIScale")
    RootScale.Scale = _G.ServerFinderUI.Settings.UIScale
    RootScale.Parent = ScreenGui

    -- ============================================================
    -- TELEPORT OVERLAY
    -- ============================================================
    local TeleportOverlay = Instance.new("Frame")
    TeleportOverlay.Name = "TeleportOverlay"
    TeleportOverlay.Size = UDim2.new(1, 0, 1, 0)
    TeleportOverlay.Position = UDim2.new(0, 0, 0, 0)
    TeleportOverlay.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    TeleportOverlay.BackgroundTransparency = 1
    TeleportOverlay.Visible = false
    TeleportOverlay.ZIndex = 100
    TeleportOverlay.Parent = ScreenGui

    local OverlayGlow = Instance.new("ImageLabel")
    OverlayGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    OverlayGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    OverlayGlow.Size = UDim2.new(0, 320, 0, 120)
    OverlayGlow.BackgroundTransparency = 1
    OverlayGlow.Image = "rbxassetid://5028857484"
    OverlayGlow.ImageColor3 = CONFIG.Colors.Glow
    OverlayGlow.ImageTransparency = 1
    OverlayGlow.ZIndex = 101
    OverlayGlow.Parent = TeleportOverlay

    local TeleportText = Instance.new("TextLabel")
    TeleportText.AnchorPoint = Vector2.new(0.5, 0.5)
    TeleportText.Position = UDim2.new(0.5, 0, 0.5, 0)
    TeleportText.Size = UDim2.new(1, 0, 0, 60)
    TeleportText.BackgroundTransparency = 1
    TeleportText.Font = Enum.Font.GothamBlack
    TeleportText.Text = "TELEPORTING..."
    TeleportText.TextColor3 = CONFIG.Colors.Red
    TeleportText.TextSize = 24
    TeleportText.TextTransparency = 1
    TeleportText.ZIndex = 102
    TeleportText.Parent = TeleportOverlay

    local TeleportStroke = stroke(TeleportText, CONFIG.Colors.Red, 1.5, 1)

    local function triggerTeleport(serverId)
        playSound(18202483174, 1.2)
        TeleportOverlay.Visible = true
        TeleportText.Text = "TELEPORTING..."
        TeleportText.TextColor3 = CONFIG.Colors.Red
        TeleportStroke.Color = CONFIG.Colors.Red

        tween(TeleportOverlay, {BackgroundTransparency = 0.05}, 0.3)
        tween(TeleportText, {TextTransparency = 0}, 0.3)
        tween(TeleportStroke, {Transparency = 0}, 0.3)
        tween(OverlayGlow, {ImageTransparency = 0.3}, 0.3)

        task.wait(0.4)

        -- Mendaftarkan eksekusi otomatis ke server berikutnya
        if queueOnTeleport then
            pcall(function()
                queueOnTeleport([[
                    repeat task.wait() until game:IsLoaded()
                    -- Ganti string di bawah ini dengan link raw script kamu jika menggunakan loadstring online
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/rizz65667-svg/NO-INTRO-/refs/heads/main/LowFindServer_NoIntro.lua"))()
                ]])
            end)
        end

        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
        end)

        if not success then
            TeleportText.Text = "SERVER FULL..."
            TeleportText.TextColor3 = CONFIG.Colors.Danger
            TeleportStroke.Color = CONFIG.Colors.Danger

            task.wait(2)

            local t1 = tween(TeleportOverlay, {BackgroundTransparency = 1}, 0.5)
            tween(TeleportText, {TextTransparency = 1}, 0.5)
            tween(TeleportStroke, {Transparency = 1}, 0.5)
            tween(OverlayGlow, {ImageTransparency = 1}, 0.5)

            t1.Completed:Wait()
            TeleportOverlay.Visible = false
        end
    end

    -- ============================================================
    -- DYNAMIC ISLAND & MAIN UI
    -- ============================================================
    local Island = Instance.new("Frame")
    Island.Name = "Island"
    Island.AnchorPoint = Vector2.new(0.5, 0)
    Island.Position = UDim2.new(0.5, 0, 0, CONFIG.TopOffset)
    Island.Size = CONFIG.IslandSize
    Island.BackgroundColor3 = CONFIG.Colors.Base1
    Island.ClipsDescendants = true
    Island.Parent = ScreenGui

    corner(Island, 16)
    stroke(Island, CONFIG.Colors.Red, 2, 0)
    gradient(Island, CONFIG.Colors.Base1, CONFIG.Colors.Base2, 60)

    local RedGlow = Instance.new("ImageLabel")
    RedGlow.Name = "RedGlow"
    RedGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    RedGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    RedGlow.Size = UDim2.new(1, 30, 1, 30)
    RedGlow.BackgroundTransparency = 1
    RedGlow.Image = "rbxassetid://5028857484"
    RedGlow.ImageColor3 = CONFIG.Colors.Glow
    RedGlow.ImageTransparency = 0.25
    RedGlow.ScaleType = Enum.ScaleType.Slice
    RedGlow.SliceCenter = Rect.new(24, 24, 276, 276)
    RedGlow.ZIndex = 0
    RedGlow.Parent = Island

    -- DRAG SYSTEM
    local dragging = false
    local dragInput, dragStart, startPos

    local function updateDrag(input)
        local delta = input.Position - dragStart
        Island.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end

    local function makeDraggable(frame)
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Island.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
    end

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateDrag(input)
        end
    end)

    makeDraggable(Island)

    -- COLLAPSED STATE
    local CollapsedContent = Instance.new("Frame")
    CollapsedContent.Name = "CollapsedContent"
    CollapsedContent.BackgroundTransparency = 1
    CollapsedContent.Size = UDim2.new(1, 0, 1, 0)
    CollapsedContent.Active = true
    CollapsedContent.ZIndex = 2
    CollapsedContent.Parent = Island

    makeDraggable(CollapsedContent)

    local IconLabel = Instance.new("TextLabel")
    IconLabel.BackgroundTransparency = 1
    IconLabel.Size = UDim2.new(1, 0, 1, 0)
    IconLabel.Font = Enum.Font.GothamBlack
    IconLabel.Text = "SF"
    IconLabel.TextColor3 = CONFIG.Colors.Red
    IconLabel.TextSize = 13
    IconLabel.TextXAlignment = Enum.TextXAlignment.Center
    IconLabel.TextYAlignment = Enum.TextYAlignment.Center
    IconLabel.ZIndex = 2
    IconLabel.Parent = CollapsedContent

    -- EXPANDED PANEL CONTENT
    local PanelContent = Instance.new("Frame")
    PanelContent.Name = "PanelContent"
    PanelContent.BackgroundTransparency = 1
    PanelContent.Size = UDim2.new(1, 0, 1, 0)
    PanelContent.Visible = false
    PanelContent.ZIndex = 2
    PanelContent.Parent = Island

    -- Header
    local Header = Instance.new("Frame")
    Header.BackgroundTransparency = 1
    Header.Size = UDim2.new(1, 0, 0, 38)
    Header.Active = true
    Header.ZIndex = 2
    Header.Parent = PanelContent
    pad(Header, 10, 8, 0, 0)

    makeDraggable(Header)

    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.Name = "HeaderTitle"
    HeaderTitle.AnchorPoint = Vector2.new(0, 0.5)
    HeaderTitle.Position = UDim2.new(0, 4, 0.5, 0)
    HeaderTitle.Size = UDim2.new(1, -40, 1, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Font = Enum.Font.GothamBold
    HeaderTitle.Text = "Server Finder | By RIZZXD"
    HeaderTitle.TextColor3 = CONFIG.Colors.TextPrimary
    HeaderTitle.TextSize = 12
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.ZIndex = 2
    HeaderTitle.Parent = Header

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.Position = UDim2.new(1, 0, 0.5, 0)
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.BackgroundColor3 = CONFIG.Colors.Row
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = CONFIG.Colors.TextSecondary
    CloseBtn.TextSize = 14
    CloseBtn.ZIndex = 3
    CloseBtn.Parent = Header
    corner(CloseBtn, 6)

    -- Divider
    local Divider = Instance.new("Frame")
    Divider.Position = UDim2.new(0, 10, 0, 38)
    Divider.Size = UDim2.new(1, -20, 0, 1)
    Divider.BackgroundColor3 = CONFIG.Colors.Row
    Divider.BorderSizePixel = 0
    Divider.ZIndex = 2
    Divider.Parent = PanelContent

    -- Page Container
    local PageContainer = Instance.new("CanvasGroup")
    PageContainer.BackgroundTransparency = 1
    PageContainer.GroupTransparency = 0
    PageContainer.Position = UDim2.new(0, 0, 0, 42)
    PageContainer.Size = UDim2.new(1, 0, 1, -42)
    PageContainer.ZIndex = 2
    PageContainer.Parent = PanelContent

    -- HomePage (Server List)
    local HomePage = Instance.new("Frame")
    HomePage.BackgroundTransparency = 1
    HomePage.Size = UDim2.new(1, 0, 1, 0)
    HomePage.ZIndex = 2
    HomePage.Parent = PageContainer
    pad(HomePage, 10, 10, 2, 6)

    -- Controls Row
    local ControlsRow = Instance.new("Frame")
    ControlsRow.Size = UDim2.new(1, 0, 0, 28)
    ControlsRow.BackgroundTransparency = 1
    ControlsRow.ZIndex = 2
    ControlsRow.Parent = HomePage

    local RefreshBtn = Instance.new("TextButton")
    RefreshBtn.Size = UDim2.new(1, -36, 1, 0)
    RefreshBtn.BackgroundColor3 = CONFIG.Colors.Row
    RefreshBtn.Font = Enum.Font.GothamBold
    RefreshBtn.Text = "🔄 Refresh"
    RefreshBtn.TextColor3 = CONFIG.Colors.Red
    RefreshBtn.TextSize = 11
    RefreshBtn.ZIndex = 3
    RefreshBtn.Parent = ControlsRow
    corner(RefreshBtn, 6)

    local ScriptBloxNavBtn = Instance.new("TextButton")
    ScriptBloxNavBtn.AnchorPoint = Vector2.new(1, 0)
    ScriptBloxNavBtn.Position = UDim2.new(1, 0, 0, 0)
    ScriptBloxNavBtn.Size = UDim2.new(0, 30, 1, 0)
    ScriptBloxNavBtn.BackgroundColor3 = CONFIG.Colors.Row
    ScriptBloxNavBtn.Font = Enum.Font.GothamBold
    ScriptBloxNavBtn.Text = "🌐"
    ScriptBloxNavBtn.TextColor3 = CONFIG.Colors.TextPrimary
    ScriptBloxNavBtn.TextSize = 14
    ScriptBloxNavBtn.ZIndex = 3
    ScriptBloxNavBtn.Parent = ControlsRow
    corner(ScriptBloxNavBtn, 6)

    -- Server List Frame
    local ServerListFrame = Instance.new("ScrollingFrame")
    ServerListFrame.BackgroundTransparency = 1
    ServerListFrame.Position = UDim2.new(0, 0, 0, 34)
    ServerListFrame.Size = UDim2.new(1, 0, 1, -68)
    ServerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ServerListFrame.ScrollBarThickness = 2
    ServerListFrame.ScrollBarImageColor3 = CONFIG.Colors.Red
    ServerListFrame.ZIndex = 2
    ServerListFrame.Parent = HomePage

    local ServerListLayout = Instance.new("UIListLayout")
    ServerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ServerListLayout.Padding = UDim.new(0, 5)
    ServerListLayout.Parent = ServerListFrame

    ServerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ServerListFrame.CanvasSize = UDim2.new(0, 0, 0, ServerListLayout.AbsoluteContentSize.Y + 10)
    end)

    -- SERVER PAGINATION BAR
    local PaginationBar = Instance.new("Frame")
    PaginationBar.AnchorPoint = Vector2.new(0.5, 1)
    PaginationBar.Position = UDim2.new(0.5, 0, 1, -2)
    PaginationBar.Size = UDim2.new(1, 0, 0, 28)
    PaginationBar.BackgroundTransparency = 1
    PaginationBar.ZIndex = 2
    PaginationBar.Parent = HomePage

    local PrevBtn = Instance.new("TextButton")
    PrevBtn.Position = UDim2.new(0, 0, 0, 0)
    PrevBtn.Size = UDim2.new(0, 65, 1, 0)
    PrevBtn.BackgroundColor3 = CONFIG.Colors.Row
    PrevBtn.Font = Enum.Font.GothamBold
    PrevBtn.Text = "< Prev"
    PrevBtn.TextColor3 = CONFIG.Colors.TextSecondary
    PrevBtn.TextSize = 11
    PrevBtn.ZIndex = 3
    PrevBtn.Parent = PaginationBar
    corner(PrevBtn, 6)

    local PageIndicator = Instance.new("TextLabel")
    PageIndicator.AnchorPoint = Vector2.new(0.5, 0)
    PageIndicator.Position = UDim2.new(0.5, 0, 0, 0)
    PageIndicator.Size = UDim2.new(0, 100, 1, 0)
    PageIndicator.BackgroundTransparency = 1
    PageIndicator.Font = Enum.Font.GothamBold
    PageIndicator.Text = "Page 1 / 1"
    PageIndicator.TextColor3 = CONFIG.Colors.TextPrimary
    PageIndicator.TextSize = 11
    PageIndicator.ZIndex = 2
    PageIndicator.Parent = PaginationBar

    local NextBtn = Instance.new("TextButton")
    NextBtn.AnchorPoint = Vector2.new(1, 0)
    NextBtn.Position = UDim2.new(1, 0, 0, 0)
    NextBtn.Size = UDim2.new(0, 65, 1, 0)
    NextBtn.BackgroundColor3 = CONFIG.Colors.Row
    NextBtn.Font = Enum.Font.GothamBold
    NextBtn.Text = "Next >"
    NextBtn.TextColor3 = CONFIG.Colors.TextSecondary
    NextBtn.TextSize = 11
    NextBtn.ZIndex = 3
    NextBtn.Parent = PaginationBar
    corner(NextBtn, 6)

    -- ============================================================
    -- SCRIPT SEARCH PAGE (DENGAN PAGINASI)
    -- ============================================================
    local ScriptSearchPage = Instance.new("Frame")
    ScriptSearchPage.BackgroundTransparency = 1
    ScriptSearchPage.Size = UDim2.new(1, 0, 1, 0)
    ScriptSearchPage.Visible = false
    ScriptSearchPage.ZIndex = 2
    ScriptSearchPage.Parent = PageContainer
    pad(ScriptSearchPage, 10, 10, 2, 6)

    local SearchContainer = Instance.new("Frame")
    SearchContainer.Size = UDim2.new(1, 0, 0, 28)
    SearchContainer.BackgroundTransparency = 1
    SearchContainer.ZIndex = 2
    SearchContainer.Parent = ScriptSearchPage

    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(1, -120, 1, 0)
    SearchBox.BackgroundColor3 = CONFIG.Colors.Row
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.PlaceholderText = "Search script..."
    SearchBox.PlaceholderColor3 = CONFIG.Colors.TextSecondary
    SearchBox.Text = ""
    SearchBox.TextColor3 = CONFIG.Colors.TextPrimary
    SearchBox.TextSize = 11
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.ZIndex = 3
    SearchBox.Parent = SearchContainer
    corner(SearchBox, 6)
    pad(SearchBox, 6, 6, 0, 0)

    local KeylessToggleBtn = Instance.new("TextButton")
    KeylessToggleBtn.AnchorPoint = Vector2.new(1, 0)
    KeylessToggleBtn.Position = UDim2.new(1, -55, 0, 0)
    KeylessToggleBtn.Size = UDim2.new(0, 60, 1, 0)
    KeylessToggleBtn.BackgroundColor3 = CONFIG.Colors.Row
    KeylessToggleBtn.Font = Enum.Font.GothamBold
    KeylessToggleBtn.Text = "🌏ALL"
    KeylessToggleBtn.TextColor3 = CONFIG.Colors.TextSecondary
    KeylessToggleBtn.TextSize = 9
    KeylessToggleBtn.ZIndex = 3
    KeylessToggleBtn.Parent = SearchContainer
    corner(KeylessToggleBtn, 6)

    local SearchBtn = Instance.new("TextButton")
    SearchBtn.AnchorPoint = Vector2.new(1, 0)
    SearchBtn.Position = UDim2.new(1, 0, 0, 0)
    SearchBtn.Size = UDim2.new(0, 50, 1, 0)
    SearchBtn.BackgroundColor3 = CONFIG.Colors.Red
    SearchBtn.Font = Enum.Font.GothamBold
    SearchBtn.Text = "Search"
    SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchBtn.TextSize = 10
    SearchBtn.ZIndex = 3
    SearchBtn.Parent = SearchContainer
    corner(SearchBtn, 6)

    local ScriptListFrame = Instance.new("ScrollingFrame")
    ScriptListFrame.BackgroundTransparency = 1
    ScriptListFrame.Position = UDim2.new(0, 0, 0, 34)
    ScriptListFrame.Size = UDim2.new(1, 0, 1, -68)
    ScriptListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScriptListFrame.ScrollBarThickness = 2
    ScriptListFrame.ScrollBarImageColor3 = CONFIG.Colors.Red
    ScriptListFrame.ZIndex = 2
    ScriptListFrame.Parent = ScriptSearchPage

    local ScriptListLayout = Instance.new("UIListLayout")
    ScriptListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ScriptListLayout.Padding = UDim.new(0, 6)
    ScriptListLayout.Parent = ScriptListFrame

    ScriptListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScriptListFrame.CanvasSize = UDim2.new(0, 0, 0, ScriptListLayout.AbsoluteContentSize.Y + 10)
    end)

    -- SCRIPT PAGINATION BAR
    local ScriptPaginationBar = Instance.new("Frame")
    ScriptPaginationBar.AnchorPoint = Vector2.new(0.5, 1)
    ScriptPaginationBar.Position = UDim2.new(0.5, 0, 1, -2)
    ScriptPaginationBar.Size = UDim2.new(1, 0, 0, 28)
    ScriptPaginationBar.BackgroundTransparency = 1
    ScriptPaginationBar.ZIndex = 2
    ScriptPaginationBar.Parent = ScriptSearchPage

    local ScriptPrevBtn = Instance.new("TextButton")
    ScriptPrevBtn.Position = UDim2.new(0, 0, 0, 0)
    ScriptPrevBtn.Size = UDim2.new(0, 65, 1, 0)
    ScriptPrevBtn.BackgroundColor3 = CONFIG.Colors.Row
    ScriptPrevBtn.Font = Enum.Font.GothamBold
    ScriptPrevBtn.Text = "< Prev"
    ScriptPrevBtn.TextColor3 = CONFIG.Colors.TextSecondary
    ScriptPrevBtn.TextSize = 11
    ScriptPrevBtn.ZIndex = 3
    ScriptPrevBtn.Parent = ScriptPaginationBar
    corner(ScriptPrevBtn, 6)

    local ScriptPageIndicator = Instance.new("TextLabel")
    ScriptPageIndicator.AnchorPoint = Vector2.new(0.5, 0)
    ScriptPageIndicator.Position = UDim2.new(0.5, 0, 0, 0)
    ScriptPageIndicator.Size = UDim2.new(0, 100, 1, 0)
    ScriptPageIndicator.BackgroundTransparency = 1
    ScriptPageIndicator.Font = Enum.Font.GothamBold
    ScriptPageIndicator.Text = "Page 1 / 1"
    ScriptPageIndicator.TextColor3 = CONFIG.Colors.TextPrimary
    ScriptPageIndicator.TextSize = 11
    ScriptPageIndicator.ZIndex = 2
    ScriptPageIndicator.Parent = ScriptPaginationBar

    local ScriptNextBtn = Instance.new("TextButton")
    ScriptNextBtn.AnchorPoint = Vector2.new(1, 0)
    ScriptNextBtn.Position = UDim2.new(1, 0, 0, 0)
    ScriptNextBtn.Size = UDim2.new(0, 65, 1, 0)
    ScriptNextBtn.BackgroundColor3 = CONFIG.Colors.Row
    ScriptNextBtn.Font = Enum.Font.GothamBold
    ScriptNextBtn.Text = "Next >"
    ScriptNextBtn.TextColor3 = CONFIG.Colors.TextSecondary
    ScriptNextBtn.TextSize = 11
    ScriptNextBtn.ZIndex = 3
    ScriptNextBtn.Parent = ScriptPaginationBar
    corner(ScriptNextBtn, 6)

    -- LOGIKA PAGINASI SCRIPT
    local cachedScripts = {}
    local currentScriptPage = 1
    local scriptItemsPerPage = 6

    local function displayScriptPage(pageNum)
        clearContainer(ScriptListFrame)

        local totalScripts = #cachedScripts
        local maxPages = math.ceil(totalScripts / scriptItemsPerPage)
        if maxPages < 1 then maxPages = 1 end

        if pageNum < 1 then pageNum = 1 end
        if pageNum > maxPages then pageNum = maxPages end
        currentScriptPage = pageNum

        ScriptPageIndicator.Text = string.format("Page %d / %d", currentScriptPage, maxPages)

        if totalScripts == 0 then
            local emptyMsg = Instance.new("TextLabel")
            emptyMsg.Size = UDim2.new(1, 0, 0, 35)
            emptyMsg.BackgroundTransparency = 1
            emptyMsg.Font = Enum.Font.Gotham
            emptyMsg.Text = "No matching scripts found."
            emptyMsg.TextColor3 = CONFIG.Colors.TextSecondary
            emptyMsg.TextSize = 11
            emptyMsg.ZIndex = 2
            emptyMsg.Parent = ScriptListFrame
            return
        end

        local startIndex = (currentScriptPage - 1) * scriptItemsPerPage + 1
        local endIndex = math.min(startIndex + scriptItemsPerPage - 1, totalScripts)

        for i = startIndex, endIndex do
            local itemData = cachedScripts[i]
            local item = itemData.rawItem
            local titleText = itemData.titleText
            local gameName = itemData.gameName
            local isVerified = itemData.isVerified
            local hasKey = itemData.hasKey
            local sourceLabel = itemData.sourceLabel

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 48)
            card.BackgroundColor3 = CONFIG.Colors.Row
            card.ZIndex = 2
            card.Parent = ScriptListFrame
            corner(card, 8)
            pad(card, 8, 8, 4, 4)

            local scriptTitle = Instance.new("TextLabel")
            scriptTitle.Size = UDim2.new(1, -70, 0, 18)
            scriptTitle.BackgroundTransparency = 1
            scriptTitle.Font = Enum.Font.GothamBold
            scriptTitle.Text = (isVerified and "✅ " or "") .. titleText
            scriptTitle.TextColor3 = CONFIG.Colors.TextPrimary
            scriptTitle.TextSize = 10
            scriptTitle.TextXAlignment = Enum.TextXAlignment.Left
            scriptTitle.TextTruncate = Enum.TextTruncate.AtEnd
            scriptTitle.ZIndex = 3
            scriptTitle.Parent = card

            local keyTag = isVerified and "✅VRF" or (hasKey and "🔐KEY" or "🔓NOKEY")

            local gameTitle = Instance.new("TextLabel")
            gameTitle.Position = UDim2.new(0, 0, 0, 20)
            gameTitle.Size = UDim2.new(1, -70, 0, 16)
            gameTitle.BackgroundTransparency = 1
            gameTitle.Font = Enum.Font.Gotham
            gameTitle.Text = string.format("🎮 %s • %s • %s", gameName, sourceLabel, keyTag)
            gameTitle.TextColor3 = isVerified and CONFIG.Colors.Verified or (hasKey and CONFIG.Colors.Red or CONFIG.Colors.Success)
            gameTitle.TextSize = 9
            gameTitle.TextXAlignment = Enum.TextXAlignment.Left
            gameTitle.TextTruncate = Enum.TextTruncate.AtEnd
            gameTitle.ZIndex = 3
            gameTitle.Parent = card

            local execBtn = Instance.new("TextButton")
            execBtn.AnchorPoint = Vector2.new(1, 0.5)
            execBtn.Position = UDim2.new(1, 0, 0.5, 0)
            execBtn.Size = UDim2.new(0, 60, 0, 26)
            execBtn.BackgroundColor3 = CONFIG.Colors.Red
            execBtn.Font = Enum.Font.GothamBold
            execBtn.Text = "Run ▶"
            execBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            execBtn.TextSize = 10
            execBtn.ZIndex = 3
            execBtn.Parent = card
            corner(execBtn, 6)

            execBtn.MouseButton1Click:Connect(function()
                playSound(18202483174, 1.2)
                local code = item.script or item.code or item.rawScript or item.scriptUrl or item.downloadUrl
                if code and code ~= "" then
                    execBtn.Text = "..."
                    task.spawn(function()
                        local success, err = pcall(function()
                            if string.match(code, "^https?://") then
                                loadstring(game:HttpGet(code))()
                            else
                                loadstring(code)()
                            end
                        end)

                        if success then
                            execBtn.Text = "Done! ✓"
                        else
                            execBtn.Text = "Error ❌"
                        end

                        task.delay(1.5, function()
                            execBtn.Text = "Run ▶"
                        end)
                    end)
                else
                    execBtn.Text = "No Code"
                    task.delay(1.5, function()
                        execBtn.Text = "Run ▶"
                    end)
                end
            end)
        end
    end

    ScriptPrevBtn.MouseButton1Click:Connect(function()
        playSound(17667885385, 1)
        if currentScriptPage > 1 then
            displayScriptPage(currentScriptPage - 1)
        end
    end)

    ScriptNextBtn.MouseButton1Click:Connect(function()
        playSound(17667885385, 1)
        local maxPages = math.ceil(#cachedScripts / scriptItemsPerPage)
        if currentScriptPage < maxPages then
            displayScriptPage(currentScriptPage + 1)
        end
    end)

    local isSearching = false
    local function fetchScripts(query)
        if isSearching then return end
        isSearching = true
        SearchBtn.Text = "..."

        clearContainer(ScriptListFrame)

        task.spawn(function()
            local rawQuery = query or ""
            local combinedScripts = {}

            local function fetchFrom(url, sourceTag, parser)
                local success, response = pcall(function()
                    return requestFunc({ Url = url, Method = "GET" })
                end)
                if success and response and response.Body then
                    local decodeSuccess, data = pcall(function()
                        return HttpService:JSONDecode(response.Body)
                    end)
                    if decodeSuccess and data then
                        local list = parser(data)
                        if list then
                            for _, item in ipairs(list) do
                                item._fromSource = sourceTag
                                table.insert(combinedScripts, item)
                            end
                        end
                    end
                end
            end

            local sbUrl = rawQuery == "" and "https://scriptblox.com/api/script/fetch?page=1" or ("https://scriptblox.com/api/script/search?q=" .. HttpService:UrlEncode(rawQuery) .. "&page=1")
            fetchFrom(sbUrl, "From SB", function(d) return d.result and d.result.scripts end)

            local rsUrl = "https://rscripts.net/api/v2/scripts"
            if rawQuery ~= "" then rsUrl = rsUrl .. "?q=" .. HttpService:UrlEncode(rawQuery) end
            fetchFrom(rsUrl, "From RS", function(d) return d.scripts or d.data or (type(d) == "table" and d or nil) end)

            local filteredList = {}
            local queryLower = rawQuery:lower()

            for _, item in ipairs(combinedScripts) do
                local titleText = item.title or item.name or "Untitled"
                local titleLower = titleText:lower()

                local gameName = "Universal"
                if type(item.game) == "table" then
                    gameName = item.game.name or item.game.title or "Universal"
                elseif type(item.game) == "string" and item.game ~= "" then
                    gameName = item.game
                elseif item.gameName then
                    gameName = tostring(item.gameName)
                end
                local gameLower = gameName:lower()

                local isRelevant = true
                if queryLower ~= "" then
                    if not (string.find(titleLower, queryLower, 1, true) or string.find(gameLower, queryLower, 1, true)) then
                        isRelevant = false
                    end
                end

                local hasKey = false
                if item.key ~= nil then
                    if type(item.key) == "boolean" then
                        hasKey = item.key
                    elseif type(item.key) == "string" then
                        hasKey = (item.key:lower() == "true")
                    end
                elseif item.keyless ~= nil then
                    if type(item.keyless) == "boolean" then
                        hasKey = not item.keyless
                    end
                elseif item.isKeyless ~= nil then
                    if type(item.isKeyless) == "boolean" then
                        hasKey = not item.isKeyless
                    end
                elseif item.keySystem ~= nil then
                    if type(item.keySystem) == "boolean" then
                        hasKey = item.keySystem
                    end
                else
                    if string.find(titleLower, "keyless") or string.find(titleLower, "no key") or string.find(titleLower, "nokey") then
                        hasKey = false
                    elseif string.find(titleLower, "key system") or string.find(titleLower, "get key") or string.find(titleLower, " key") then
                        hasKey = true
                    end
                end

                local isVerified = false
                if item.verified ~= nil then
                    if type(item.verified) == "boolean" then
                        isVerified = item.verified
                    elseif type(item.verified) == "string" then
                        isVerified = (item.verified:lower() == "true")
                    end
                elseif item.isVerified ~= nil then
                    if type(item.isVerified) == "boolean" then
                        isVerified = item.isVerified
                    end
                elseif item.verifiedType ~= nil or item.verifiedOnly ~= nil then
                    isVerified = true
                end

                local allowShow = isRelevant
                if filterMode == "KEY" and not hasKey then allowShow = false end
                if filterMode == "NOKEY" and hasKey then allowShow = false end
                if filterMode == "VRF" and not isVerified then allowShow = false end

                if allowShow then
                    table.insert(filteredList, {
                        rawItem = item,
                        titleText = titleText,
                        gameName = gameName,
                        isVerified = isVerified,
                        hasKey = hasKey,
                        sourceLabel = item._fromSource or "From SB"
                    })
                end
            end

            cachedScripts = filteredList
            displayScriptPage(1)

            SearchBtn.Text = "Search"
            isSearching = false
        end)
    end

    KeylessToggleBtn.MouseButton1Click:Connect(function()
        playSound(17667885385, 1)
        if filterMode == "ALL" then
            filterMode = "KEY"
            KeylessToggleBtn.Text = "🔐KEY"
            KeylessToggleBtn.TextColor3 = CONFIG.Colors.Red
        elseif filterMode == "KEY" then
            filterMode = "NOKEY"
            KeylessToggleBtn.Text = "🔓NOKEY"
            KeylessToggleBtn.TextColor3 = CONFIG.Colors.Success
        elseif filterMode == "NOKEY" then
            filterMode = "VRF"
            KeylessToggleBtn.Text = "✅VRF"
            KeylessToggleBtn.TextColor3 = CONFIG.Colors.Verified
        else
            filterMode = "ALL"
            KeylessToggleBtn.Text = "🌏ALL"
            KeylessToggleBtn.TextColor3 = CONFIG.Colors.TextSecondary
        end
        fetchScripts(SearchBox.Text)
    end)

    SearchBtn.MouseButton1Click:Connect(function()
        playSound(17667885385, 1)
        fetchScripts(SearchBox.Text)
    end)

    SearchBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            fetchScripts(SearchBox.Text)
        end
    end)

    -- ============================================================
    -- PAGINATION & SERVER LOGIC
    -- ============================================================
    local cachedServers = {}
    local currentPage = 1
    local itemsPerPage = 10

    local function displayPage(pageNum)
        clearContainer(ServerListFrame)

        local totalServers = #cachedServers
        local maxPages = math.ceil(totalServers / itemsPerPage)
        if maxPages < 1 then maxPages = 1 end

        if pageNum < 1 then pageNum = 1 end
        if pageNum > maxPages then pageNum = maxPages end
        currentPage = pageNum

        PageIndicator.Text = string.format("Page %d / %d", currentPage, maxPages)

        local startIndex = (currentPage - 1) * itemsPerPage + 1
        local endIndex = math.min(startIndex + itemsPerPage - 1, totalServers)

        if totalServers == 0 then
            local emptyMsg = Instance.new("TextLabel")
            emptyMsg.Size = UDim2.new(1, 0, 0, 35)
            emptyMsg.BackgroundTransparency = 1
            emptyMsg.Font = Enum.Font.Gotham
            emptyMsg.Text = "No servers found."
            emptyMsg.TextColor3 = CONFIG.Colors.TextSecondary
            emptyMsg.TextSize = 11
            emptyMsg.ZIndex = 2
            emptyMsg.Parent = ServerListFrame
            return
        end

        for i = startIndex, endIndex do
            local serverData = cachedServers[i]
            local card = Instance.new("Frame")
            card.Name = "ServerCard"
            card.Size = UDim2.new(1, 0, 0, 38)
            card.BackgroundColor3 = CONFIG.Colors.Row
            card.ZIndex = 2
            card.Parent = ServerListFrame
            corner(card, 8)
            pad(card, 8, 8, 2, 2)

            local infoText = Instance.new("TextLabel")
            infoText.Size = UDim2.new(1, -65, 1, 0)
            infoText.BackgroundTransparency = 1
            infoText.Font = Enum.Font.Gotham
            infoText.Text = string.format("👥 Players: %d/%d\nID: %s", serverData.playing, serverData.maxPlayers, string.sub(tostring(serverData.id), 1, 10) .. "..")
            infoText.TextColor3 = CONFIG.Colors.TextPrimary
            infoText.TextSize = 10
            infoText.TextXAlignment = Enum.TextXAlignment.Left
            infoText.ZIndex = 3
            infoText.Parent = card

            local joinBtn = Instance.new("TextButton")
            joinBtn.AnchorPoint = Vector2.new(1, 0.5)
            joinBtn.Position = UDim2.new(1, 0, 0.5, 0)
            joinBtn.Size = UDim2.new(0, 55, 0, 24)
            joinBtn.BackgroundColor3 = CONFIG.Colors.Red
            joinBtn.Font = Enum.Font.GothamBold
            joinBtn.Text = "Join 🚀"
            joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            joinBtn.TextSize = 10
            joinBtn.ZIndex = 3
            joinBtn.Parent = card
            corner(joinBtn, 6)

            joinBtn.MouseButton1Click:Connect(function()
                triggerTeleport(serverData.id)
            end)
        end
    end

    PrevBtn.MouseButton1Click:Connect(function()
        playSound(17667885385, 1)
        if currentPage > 1 then
            displayPage(currentPage - 1)
        end
    end)

    NextBtn.MouseButton1Click:Connect(function()
        playSound(17667885385, 1)
        local maxPages = math.ceil(#cachedServers / itemsPerPage)
        if currentPage < maxPages then
            displayPage(currentPage + 1)
        end
    end)

    local function fetchServers(cursor)
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
        if cursor then
            url = url .. "&cursor=" .. cursor
        end
        
        local success, response = pcall(function()
            return requestFunc({
                Url = url,
                Method = "GET"
            })
        end)
        
        if success and response and response.Body then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)
            if decodeSuccess then
                return data
            end
        end
        return nil
    end

    local isLoading = false
    local function loadServers()
        if isLoading then return end
        isLoading = true
        RefreshBtn.Text = "⏳ Fetching..."

        clearContainer(ServerListFrame)
        local loadingMsg = Instance.new("TextLabel")
        loadingMsg.Size = UDim2.new(1, 0, 0, 35)
        loadingMsg.BackgroundTransparency = 1
        loadingMsg.Font = Enum.Font.Gotham
        loadingMsg.Text = "Mencari server..."
        loadingMsg.TextColor3 = CONFIG.Colors.TextSecondary
        loadingMsg.TextSize = 11
        loadingMsg.ZIndex = 2
        loadingMsg.Parent = ServerListFrame

        task.spawn(function()
            local success, err = pcall(function()
                local servers = {}
                local cursor = nil

                repeat
                    local data = fetchServers(cursor)
                    if data and data.data then
                        for _, server in ipairs(data.data) do
                            table.insert(servers, server)
                        end
                        cursor = data.nextPageCursor
                    else
                        break
                    end
                until not cursor or #servers > 500

                table.sort(servers, function(a, b)
                    return a.playing < b.playing
                end)

                cachedServers = servers
                displayPage(1)
                playSound(14521739798, 1)
            end)

            if not success then
                clearContainer(ServerListFrame)
                local errorMsg = Instance.new("TextLabel")
                errorMsg.Size = UDim2.new(1, 0, 0, 35)
                errorMsg.BackgroundTransparency = 1
                errorMsg.Font = Enum.Font.Gotham
                errorMsg.Text = "Gagal memuat server! Coba refresh lagi."
                errorMsg.TextColor3 = CONFIG.Colors.Danger
                errorMsg.TextSize = 11
                errorMsg.ZIndex = 2
                errorMsg.Parent = ServerListFrame

                RefreshBtn.Text = "❌ Failed, Retry"
                task.delay(1.5, function()
                    if RefreshBtn.Text == "❌ Failed, Retry" then
                        RefreshBtn.Text = "🔄 Refresh"
                    end
                end)
            else
                RefreshBtn.Text = "🔄 Refresh"
            end
            isLoading = false
        end)
    end

    RefreshBtn.MouseButton1Click:Connect(function()
        playSound(17667885385, 1)
        loadServers()
    end)

    -- ============================================================
    -- BUTTERY SMOOTH PAGE NAVIGATION (WITH FADE EFFECT)
    -- ============================================================
    local isSwapping = false
    local function SwapPage(showHome)
        if isSwapping then return end
        isSwapping = true

        tween(PageContainer, {GroupTransparency = 1}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Wait()

        HomePage.Visible = showHome
        ScriptSearchPage.Visible = not showHome
        HeaderTitle.Text = showHome and "Server Finder | By RIZZXD" or "Script Search | By RIZZXD"

        if not showHome and #cachedScripts == 0 then
            fetchScripts("")
        end

        tween(PageContainer, {GroupTransparency = 0}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Wait()
        isSwapping = false
    end

    ScriptBloxNavBtn.MouseButton1Click:Connect(function()
        playSound(17667885385, 1)
        SwapPage(not HomePage.Visible)
    end)

    -- ============================================================
    -- BUTTERY SMOOTH EXPAND / COLLAPSE ANIMATIONS
    -- ============================================================
    local expanded = false

    local function Expand()
        if expanded then return end
        expanded = true
        playSound(140207837688369, 1.5)
        
        tween(IconLabel, {TextTransparency = 1}, 0.15)
        tween(Island, {Size = CONFIG.PanelSize}, CONFIG.AnimTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        
        task.delay(CONFIG.AnimTime * 0.3, function()
            PanelContent.Visible = true
            PanelContent.Position = UDim2.new(0, 0, 0, 0)
            if #cachedServers == 0 then
                loadServers()
            end
        end)
    end

    local function Collapse()
        if not expanded then return end
        expanded = false
        playSound(140207837688369, 1.5)
        
        PanelContent.Visible = false
        SwapPage(true)
        
        tween(Island, {Size = CONFIG.IslandSize}, CONFIG.AnimTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        
        task.delay(0.1, function()
            tween(IconLabel, {TextTransparency = 0}, 0.2)
            CollapsedContent.Visible = true
        end)
    end

    CloseBtn.MouseButton1Click:Connect(function()
        playSound(17667885385, 1)
        if ScriptSearchPage.Visible then
            SwapPage(true)
        else
            Collapse()
        end
    end)

    -- ============================================================
    -- TAP HANDLING
    -- ============================================================
    CollapsedContent.InputBegan:Connect(function(input)
        if not dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            Expand()
        end
    end)
