--[[
    OrionPainel.lua

    Painel de UI completo para executors / ambientes Roblox.
    Arquivo único, pronto para colar em um LocalScript, ModuleScript ou loadstring.

    Recursos:
    - Janela arrastável
    - Abas
    - Botões
    - Toggles
    - Sliders
    - Dropdowns
    - Inputs
    - Keybinds
    - Color pickers
    - Notificações
    - Watermark com FPS
    - Sistema de config/save/load
    - API simples

    Se quiser usar só como biblioteca sem abrir a demo automaticamente:
    _G.OrionNoDemo = true
    antes de carregar o arquivo.
]]

local OrionPainel = {}

OrionPainel.Version = "1.0.0"
OrionPainel.Flags = {}
OrionPainel.Controls = {}
OrionPainel.Connections = {}
OrionPainel.Windows = {}
OrionPainel.Themes = {}
OrionPainel.ConfigFolder = "OrionPainel"
OrionPainel.ToggleKey = Enum.KeyCode.RightShift
OrionPainel.UseWatermark = true
OrionPainel.UseNotifications = true
OrionPainel.WatermarkText = "Orion | {fps} FPS | {player}"

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local function Warn(message)
    if warn then
        warn(message)
    else
        print(message)
    end
end

local function TypeOf(value)
    if typeof then
        return typeof(value)
    end
    return type(value)
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return false
    end

    local ok, err = pcall(fn, ...)

    if not ok then
        Warn("[OrionPainel] Erro em callback: " .. tostring(err))
    end

    return ok
end

function OrionPainel.AddConnection(connection)
    table.insert(OrionPainel.Connections, connection)
    return connection
end

function OrionPainel.DisconnectAll()
    for _, connection in ipairs(OrionPainel.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    OrionPainel.Connections = {}
end

local function Clamp(value, min, max)
    if value < min then
        return min
    end

    if value > max then
        return max
    end

    return value
end

local function Round(value, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

local function TableFind(list, value)
    for index, item in ipairs(list) do
        if item == value then
            return index
        end
    end

    return nil
end

local function MakeFlag(prefix)
    local ok, guid = pcall(function()
        return HttpService:GenerateGUID(false)
    end)

    if ok and guid then
        return prefix .. "_" .. tostring(guid):sub(1, 8)
    end

    return prefix .. "_" .. tostring(math.random(100000, 99999999))
end

local function IsTyping()
    local ok, textBox = pcall(function()
        return UserInputService:GetFocusedTextBox()
    end)

    return ok and textBox ~= nil
end

local function GetDisplayParent()
    if gethui then
        local ok, hui = pcall(gethui)

        if ok and hui then
            return hui
        end
    end

    local okCore = pcall(function()
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
    end)

    if okCore then
        return CoreGui
    end

    return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

local function new(class, props, children)
    local instance = Instance.new(class)

    props = props or {}

    local parent = props.Parent
    props.Parent = nil

    for key, value in pairs(props) do
        pcall(function()
            instance[key] = value
        end)
    end

    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end

    if parent then
        instance.Parent = parent
    end

    return instance
end

OrionPainel.Theme = {
    Background = Color3.fromRGB(10, 10, 14),
    Sidebar = Color3.fromRGB(14, 14, 20),
    Content = Color3.fromRGB(12, 12, 17),
    Card = Color3.fromRGB(18, 18, 26),
    CardHover = Color3.fromRGB(26, 26, 38),
    CardDown = Color3.fromRGB(15, 15, 21),
    Accent = Color3.fromRGB(124, 92, 255),
    AccentSoft = Color3.fromRGB(88, 68, 180),
    Text = Color3.fromRGB(235, 235, 245),
    SubText = Color3.fromRGB(145, 148, 165),
    Stroke = Color3.fromRGB(35, 36, 48),
    Input = Color3.fromRGB(24, 25, 35),
    Success = Color3.fromRGB(70, 200, 120),
    Warning = Color3.fromRGB(240, 180, 70),
    Danger = Color3.fromRGB(240, 90, 90),
}

OrionPainel.Themes.Default = OrionPainel.Theme

OrionPainel.Themes.Purple = {
    Background = Color3.fromRGB(12, 10, 18),
    Sidebar = Color3.fromRGB(17, 14, 26),
    Content = Color3.fromRGB(14, 12, 21),
    Card = Color3.fromRGB(23, 19, 34),
    CardHover = Color3.fromRGB(32, 26, 48),
    CardDown = Color3.fromRGB(19, 16, 28),
    Accent = Color3.fromRGB(168, 85, 247),
    AccentSoft = Color3.fromRGB(112, 58, 170),
    Text = Color3.fromRGB(240, 238, 250),
    SubText = Color3.fromRGB(155, 148, 175),
    Stroke = Color3.fromRGB(43, 35, 62),
    Input = Color3.fromRGB(29, 24, 43),
    Success = Color3.fromRGB(74, 222, 128),
    Warning = Color3.fromRGB(250, 204, 21),
    Danger = Color3.fromRGB(248, 113, 113),
}

OrionPainel.Themes.Ocean = {
    Background = Color3.fromRGB(8, 13, 18),
    Sidebar = Color3.fromRGB(11, 18, 25),
    Content = Color3.fromRGB(10, 15, 21),
    Card = Color3.fromRGB(15, 23, 32),
    CardHover = Color3.fromRGB(22, 33, 46),
    CardDown = Color3.fromRGB(12, 19, 26),
    Accent = Color3.fromRGB(56, 189, 248),
    AccentSoft = Color3.fromRGB(38, 127, 168),
    Text = Color3.fromRGB(230, 242, 250),
    SubText = Color3.fromRGB(138, 160, 175),
    Stroke = Color3.fromRGB(30, 45, 60),
    Input = Color3.fromRGB(18, 28, 39),
    Success = Color3.fromRGB(52, 211, 153),
    Warning = Color3.fromRGB(251, 191, 36),
    Danger = Color3.fromRGB(251, 113, 133),
}

OrionPainel.Themes.Blood = {
    Background = Color3.fromRGB(14, 8, 10),
    Sidebar = Color3.fromRGB(20, 11, 14),
    Content = Color3.fromRGB(16, 10, 12),
    Card = Color3.fromRGB(26, 15, 19),
    CardHover = Color3.fromRGB(38, 21, 27),
    CardDown = Color3.fromRGB(21, 12, 15),
    Accent = Color3.fromRGB(239, 68, 68),
    AccentSoft = Color3.fromRGB(160, 44, 44),
    Text = Color3.fromRGB(250, 235, 238),
    SubText = Color3.fromRGB(175, 135, 142),
    Stroke = Color3.fromRGB(55, 28, 34),
    Input = Color3.fromRGB(32, 18, 23),
    Success = Color3.fromRGB(74, 222, 128),
    Warning = Color3.fromRGB(250, 204, 21),
    Danger = Color3.fromRGB(248, 113, 113),
}

OrionPainel.Themes.Matrix = {
    Background = Color3.fromRGB(6, 12, 8),
    Sidebar = Color3.fromRGB(9, 17, 12),
    Content = Color3.fromRGB(8, 14, 10),
    Card = Color3.fromRGB(13, 22, 16),
    CardHover = Color3.fromRGB(19, 32, 23),
    CardDown = Color3.fromRGB(10, 17, 12),
    Accent = Color3.fromRGB(34, 197, 94),
    AccentSoft = Color3.fromRGB(24, 130, 64),
    Text = Color3.fromRGB(225, 250, 235),
    SubText = Color3.fromRGB(120, 165, 138),
    Stroke = Color3.fromRGB(24, 48, 34),
    Input = Color3.fromRGB(15, 26, 19),
    Success = Color3.fromRGB(74, 222, 128),
    Warning = Color3.fromRGB(250, 204, 21),
    Danger = Color3.fromRGB(248, 113, 113),
}

function OrionPainel:SetTheme(themeName)
    local theme = self.Themes[themeName]

    if not theme then
        Warn("[OrionPainel] Tema não encontrado: " .. tostring(themeName))
        return false
    end

    self.Theme = theme
    return true
end

local function Tween(object, time, properties, easingStyle, easingDirection)
    local info = TweenInfo.new(
        time or 0.15,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(object, info, properties)
    tween:Play()

    return tween
end

local function MakeCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = object
    return corner
end

local function MakeStroke(object, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or OrionPainel.Theme.Stroke
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = object
    return stroke
end

local function MakePadding(object, top, bottom, left, right)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or 0)
    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or 0)
    padding.Parent = object
    return padding
end

local function MakeListLayout(object, padding)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, padding or 6)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = object
    return layout
end

local function AddButtonEffects(button, normal, hover, down)
    button.BackgroundColor3 = normal

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hover
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = normal
    end)

    button.MouseButton1Down:Connect(function()
        button.BackgroundColor3 = down
    end)

    button.MouseButton1Up:Connect(function()
        button.BackgroundColor3 = hover
    end)
end

local function MakeDraggable(frame, handle)
    handle = handle or frame

    local dragging = false
    local dragStart = nil
    local startPos = nil

    OrionPainel.AddConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    OrionPainel.AddConnection(handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    OrionPainel.AddConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if not dragStart or not startPos then
            return
        end

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)
end

local NotifyGui = nil
local NotifyHolder = nil
local NotifyLayout = nil

local function GetNotifyGui()
    if NotifyGui and NotifyGui.Parent then
        return NotifyGui
    end

    NotifyGui = new("ScreenGui", {
        Name = "OrionPainel_Notifications",
        ResetOnSpawn = false,
        DisplayOrder = 999998,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = GetDisplayParent(),
    })

    NotifyHolder = new("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -14, 1, -14),
        Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = NotifyGui,
    })

    NotifyLayout = MakeListLayout(NotifyHolder, 8)
    NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

    return NotifyGui
end

function OrionPainel:Notify(options)
    if not self.UseNotifications then
        return
    end

    if type(options) == "string" then
        options = {
            Text = options
        }
    end

    options = options or {}

    local title = options.Title or "Orion"
    local text = options.Text or ""
    local duration = options.Duration or 3.5
    local kind = options.Type or options.Kind or "Info"

    local theme = self.Theme
    GetNotifyGui()

    local color = theme.Accent

    if kind == "Success" then
        color = theme.Success
    elseif kind == "Warning" then
        color = theme.Warning
    elseif kind == "Error" or kind == "Danger" then
        color = theme.Danger
    end

    local card = new("Frame", {
        Name = "Notification",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = theme.Card,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        LayoutOrder = #NotifyHolder:GetChildren() + 1,
        Parent = NotifyHolder,
    })

    MakeCorner(card, 10)
    MakeStroke(card, theme.Stroke, 1)

    local accent = new("Frame", {
        Position = UDim2.new(0, 0, 0, 10),
        Size = UDim2.new(0, 3, 1, -20),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = card,
    })

    MakeCorner(accent, 2)

    local titleLabel = new("TextLabel", {
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -44, 0, 18),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        Parent = card,
    })

    local textLabel = new("TextLabel", {
        Position = UDim2.new(0, 14, 0, 28),
        Size = UDim2.new(1, -44, 0, 28),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTransparency = 1,
        Parent = card,
    })

    local closeButton = new("TextButton", {
        Position = UDim2.new(1, -28, 0, 8),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        Text = "x",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = theme.SubText,
        Parent = card,
    })

    local progress = new("Frame", {
        Position = UDim2.new(0, 14, 1, -10),
        Size = UDim2.new(1, -28, 0, 2),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Parent = card,
    })

    MakeCorner(progress, 2)

    local progressFill = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = progress,
    })

    MakeCorner(progressFill, 2)

    Tween(card, 0.18, {
        BackgroundTransparency = 0
    })

    Tween(titleLabel, 0.18, {
        TextTransparency = 0
    })

    Tween(textLabel, 0.18, {
        TextTransparency = 0
    })

    Tween(progressFill, duration, {
        Size = UDim2.new(0, 0, 1, 0)
    }, Enum.EasingStyle.Linear)

    local closed = false

    local function close()
        if closed then
            return
        end

        closed = true

        Tween(card, 0.18, {
            BackgroundTransparency = 1
        })

        Tween(titleLabel, 0.18, {
            TextTransparency = 1
        })

        Tween(textLabel, 0.18, {
            TextTransparency = 1
        })

        task.delay(0.2, function()
            card:Destroy()
        end)
    end

    closeButton.MouseButton1Click:Connect(close)

    task.delay(duration, close)

    return card
end

local WatermarkGui = nil
local WatermarkLabel = nil
local WatermarkFrames = 0
local WatermarkLast = tick()
local WatermarkFps = 60

local function FormatWatermark()
    local text = OrionPainel.WatermarkText or "Orion"

    text = text:gsub("{fps}", tostring(WatermarkFps))
    text = text:gsub("{player}", LocalPlayer and LocalPlayer.Name or "Player")
    text = text:gsub("{version}", OrionPainel.Version)
    text = text:gsub("{time}", os.date("%H:%M:%S"))

    return text
end

local function UpdateWatermark()
    if not WatermarkLabel or not WatermarkLabel.Parent then
        return
    end

    WatermarkLabel.Text = FormatWatermark()
end

OrionPainel.AddConnection(RunService.RenderStepped:Connect(function()
    WatermarkFrames = WatermarkFrames + 1

    local now = tick()

    if now - WatermarkLast >= 0.25 then
        WatermarkFps = math.floor(WatermarkFrames / (now - WatermarkLast))
        WatermarkFrames = 0
        WatermarkLast = now
        UpdateWatermark()
    end
end)

function OrionPainel:SetWatermark(text)
    if text == false or text == nil then
        if WatermarkLabel then
            WatermarkLabel.Visible = false
        end

        return
    end

    self.WatermarkText = tostring(text)

    if not WatermarkGui or not WatermarkGui.Parent then
        WatermarkGui = new("ScreenGui", {
            Name = "OrionPainel_Watermark",
            ResetOnSpawn = false,
            DisplayOrder = 999997,
            Parent = GetDisplayParent(),
        })

        WatermarkLabel = new("TextLabel", {
            Position = UDim2.new(0, 10, 0, 10),
            Size = UDim2.new(0, 0, 0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = self.Theme.Background,
            BorderSizePixel = 0,
            Text = FormatWatermark(),
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = self.Theme.Text,
            Parent = WatermarkGui,
        })

        MakeCorner(WatermarkLabel, 8)
        MakeStroke(WatermarkLabel, self.Theme.Stroke, 1)
        MakePadding(WatermarkLabel, 0, 0, 8, 8)
    end

    WatermarkLabel.Visible = true
    UpdateWatermark()
end

OrionPainel.Window = {}
OrionPainel.Tab = {}

function OrionPainel:CreateWindow(options)
    options = options or {}

    local theme = self.Theme

    local gui = new("ScreenGui", {
        Name = "OrionPainel_Window",
        ResetOnSpawn = false,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = GetDisplayParent(),
    })

    local main = new("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(options.Width or 700, options.Height or 460),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Parent = gui,
    })

    MakeCorner(main, 12)
    MakeStroke(main, theme.Stroke, 1)

    local topBar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local title = new("TextLabel", {
        Position = UDim2.new(0, 16, 0, 7),
        Size = UDim2.new(1, -120, 0, 18),
        BackgroundTransparency = 1,
        Text = options.Title or "Orion Painel",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })

    local subtitle = new("TextLabel", {
        Position = UDim2.new(0, 16, 0, 26),
        Size = UDim2.new(1, -120, 0, 14),
        BackgroundTransparency = 1,
        Text = options.Subtitle or "UI completa em um único arquivo",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })

    local closeButton = new("TextButton", {
        Position = UDim2.new(1, -38, 0, 8),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = theme.Danger,
        BorderSizePixel = 0,
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Parent = topBar,
    })

    MakeCorner(closeButton, 8)
    AddButtonEffects(closeButton, theme.Danger, Color3.fromRGB(255, 110, 110), Color3.fromRGB(190, 55, 55))

    local minimizeButton = new("TextButton", {
        Position = UDim2.new(1, -74, 0, 8),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Text = "-",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = theme.Text,
        Parent = topBar,
    })

    MakeCorner(minimizeButton, 8)
    AddButtonEffects(minimizeButton, theme.Input, theme.CardHover, theme.CardDown)

    local sidebar = new("Frame", {
        Name = "Sidebar",
        Position = UDim2.new(0, 0, 0, 46),
        Size = UDim2.new(0, 170, 1, -46),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Parent = main,
    })

    local tabList = new("ScrollingFrame", {
        Name = "TabList",
        Position = UDim2.new(0, 8, 0, 10),
        Size = UDim2.new(1, -16, 1, -54),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.new(),
        Parent = sidebar,
    })

    local tabLayout = MakeListLayout(tabList, 6)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    pcall(function()
        tabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end)

    local brand = new("TextLabel", {
        Position = UDim2.new(0, 0, 1, -30),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = "ORION",
        Font = Enum.Font.GothamBlack,
        TextSize = 12,
        TextColor3 = theme.Accent,
        TextTransparency = 0.25,
        Parent = sidebar,
    })

    local content = new("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 170, 0, 46),
        Size = UDim2.new(1, -170, 1, -46),
        BackgroundColor3 = theme.Content,
        BorderSizePixel = 0,
        Parent = main,
    })

    local window = setmetatable({
        Gui = gui,
        Main = main,
        TopBar = topBar,
        Sidebar = sidebar,
        TabList = tabList,
        Content = content,
        TitleLabel = title,
        SubtitleLabel = subtitle,
        Tabs = {},
        ActiveTab = nil,
        Minimized = false,
        OriginalSize = main.Size,
        Theme = theme,
    }, {
        __index = OrionPainel.Window
    })

    table.insert(self.Windows, window)

    MakeDraggable(main, topBar)

    closeButton.MouseButton1Click:Connect(function()
        window:Toggle(false)
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        window:ToggleMinimize()
    end)

    return window
end

function OrionPainel.Window:SetTitle(titleText, subtitleText)
    if titleText then
        self.TitleLabel.Text = tostring(titleText)
    end

    if subtitleText then
        self.SubtitleLabel.Text = tostring(subtitleText)
    end
end

function OrionPainel.Window:Toggle(visible)
    if visible == nil then
        visible = not self.Main.Visible
    end

    self.Main.Visible = visible

    return visible
end

function OrionPainel.Window:ToggleMinimize()
    self.Minimized = not self.Minimized

    if self.Minimized then
        self.OriginalSize = self.Main.Size
        self.Main.Size = UDim2.new(0, self.Main.AbsoluteSize.X, 0, 46)
        self.Sidebar.Visible = false
        self.Content.Visible = false
    else
        self.Main.Size = self.OriginalSize
        self.Sidebar.Visible = true
        self.Content.Visible = true
    end
end

function OrionPainel.Window:AddTab(name, icon)
    local theme = self.Theme

    local tab = setmetatable({
        Name = name,
        Window = self,
        ElementOrder = 0,
    }, {
        __index = OrionPainel.Tab
    })

    tab.Button = new("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = self.TabList,
    })

    MakeCorner(tab.Button, 8)

    tab.IconLabel = new("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 22, 1, 0),
        BackgroundTransparency = 1,
        Text = icon or "•",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab.Button,
    })

    tab.ButtonLabel = new("TextLabel", {
        Position = UDim2.new(0, 36, 0, 0),
        Size = UDim2.new(1, -44, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab.Button,
    })

    tab.Page = new("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.new(),
        Visible = false,
        Parent = self.Content,
    })

    MakePadding(tab.Page, 12, 12, 12, 12)

    tab.PageLayout = MakeListLayout(tab.Page, 8)
    tab.PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    pcall(function()
        tab.Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end)

    OrionPainel.AddConnection(tab.PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tab.Page.CanvasSize = UDim2.fromOffset(0, tab.PageLayout.AbsoluteContentSize.Y + 24)
    end)

    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    tab.Button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tab.Button.BackgroundColor3 = theme.Card
        end
    end)

    tab.Button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tab.Button.BackgroundColor3 = theme.Sidebar
        end
    end)

    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    return tab
end

function OrionPainel.Window:SelectTab(targetTab)
    for _, tab in ipairs(self.Tabs) do
        local active = tab == targetTab

        tab.Page.Visible = active
        tab.Button.BackgroundColor3 = active and self.Theme.Card or self.Theme.Sidebar
        tab.ButtonLabel.TextColor3 = active and self.Theme.Text or self.Theme.SubText
        tab.IconLabel.TextColor3 = active and self.Theme.Accent or self.Theme.SubText
    end

    self.ActiveTab = targetTab
end

function OrionPainel.Window:Destroy()
    if self.Gui then
        self.Gui:Destroy()
    end
end

function OrionPainel.Tab:NextOrder()
    self.ElementOrder = self.ElementOrder + 1
    return self.ElementOrder
end

local function CreateElementBase(tab, height)
    local base = new("Frame", {
        Name = "Element",
        Size = UDim2.new(1, -4, 0, height or 42),
        BackgroundTransparency = 1,
        LayoutOrder = tab:NextOrder(),
        Parent = tab.Page,
    })

    return base
end

local function CreateCard(base, theme)
    local card = new("Frame", {
        Name = "Card",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme.Card,
        BorderSizePixel = 0,
        Parent = base,
    })

    MakeCorner(card, 10)
    MakeStroke(card, theme.Stroke, 1)

    return card
end

function OrionPainel.Tab:AddSection(text)
    local theme = self.Window.Theme
    local base = CreateElementBase(self, 30)

    local label = new("TextLabel", {
        Position = UDim2.new(0, 2, 1, -18),
        Size = UDim2.new(1, -4, 0, 14),
        BackgroundTransparency = 1,
        Text = string.upper(tostring(text or "Seção")),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = base,
    })

    local line = new("Frame", {
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.Stroke,
        BorderSizePixel = 0,
        Parent = base,
    })

    local control = {
        Base = base,
        Type = "Section",
    }

    function control:Set(newText)
        label.Text = string.upper(tostring(newText))
    end

    return control
end

function OrionPainel.Tab:AddLabel(options)
    options = options or {}

    local theme = self.Window.Theme
    local base = CreateElementBase(self, options.Height or 26)

    local label = new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Text or "",
        Font = Enum.Font.Gotham,
        TextSize = options.TextSize or 13,
        TextColor3 = options.Color or theme.SubText,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = base,
    })

    local control = {
        Base = base,
        Type = "Label",
    }

    function control:Set(newText)
        label.Text = tostring(newText)
    end

    return control
end

function OrionPainel.Tab:AddButton(options)
    options = options or {}

    local theme = self.Window.Theme
    local base = CreateElementBase(self, options.Height or 42)
    local card = CreateCard(base, theme)

    local button = new("TextButton", {
        Position = UDim2.new(0, 8, 0, 6),
        Size = UDim2.new(1, -16, 1, -12),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Text = options.Name or "Botão",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = theme.Text,
        Parent = card,
    })

    MakeCorner(button, 8)
    AddButtonEffects(button, theme.Input, theme.CardHover, theme.CardDown)

    button.MouseButton1Click:Connect(function()
        SafeCall(options.Callback, button)
    end)

    local control = {
        Base = base,
        Button = button,
        Type = "Button",
    }

    function control:Fire()
        SafeCall(options.Callback, button)
    end

    function control:SetText(newText)
        button.Text = tostring(newText)
    end

    return control
end

function OrionPainel.Tab:AddToggle(options)
    options = options or {}

    local theme = self.Window.Theme
    local flag = options.Flag or MakeFlag("Toggle")
    local default = options.Default or false

    OrionPainel.Flags[flag] = default and true or false

    local base = CreateElementBase(self, 42)
    local card = CreateCard(base, theme)

    local label = new("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -88, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Toggle",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local switch = new("TextButton", {
        Position = UDim2.new(1, -56, 0.5, -11),
        Size = UDim2.fromOffset(42, 22),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = card,
    })

    MakeCorner(switch, 12)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = theme.SubText,
        BorderSizePixel = 0,
        Parent = switch,
    })

    MakeCorner(knob, 8)

    local function SetState(value, skip)
        value = value and true or false

        OrionPainel.Flags[flag] = value

        Tween(knob, 0.16, {
            Position = value and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        })

        Tween(switch, 0.16, {
            BackgroundColor3 = value and theme.Accent or theme.Input
        })

        Tween(knob, 0.16, {
            BackgroundColor3 = value and Color3.fromRGB(250, 250, 255) or theme.SubText
        })

        if not skip then
            SafeCall(options.Callback, value)
        end
    end

    switch.MouseButton1Click:Connect(function()
        SetState(not OrionPainel.Flags[flag])
    end)

    SetState(default, true)

    local control = {
        Base = base,
        Flag = flag,
        Type = "Toggle",
    }

    function control:Set(value, skip)
        SetState(value, skip)
    end

    function control:Get()
        return OrionPainel.Flags[flag]
    end

    OrionPainel.Controls[flag] = control

    return control
end

function OrionPainel.Tab:AddSlider(options)
    options = options or {}

    local theme = self.Window.Theme
    local flag = options.Flag or MakeFlag("Slider")

    local min = tonumber(options.Min) or 0
    local max = tonumber(options.Max) or 100
    local default = tonumber(options.Default) or min
    local suffix = options.Suffix or ""
    local decimals = options.Decimals or 0

    if min > max then
        min, max = max, min
    end

    default = Clamp(default, min, max)
    OrionPainel.Flags[flag] = default

    local base = CreateElementBase(self, 64)
    local card = CreateCard(base, theme)

    local label = new("TextLabel", {
        Position = UDim2.new(0, 12, 0, 7),
        Size = UDim2.new(1, -96, 0, 16),
        BackgroundTransparency = 1,
        Text = options.Name or "Slider",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local valueLabel = new("TextLabel", {
        Position = UDim2.new(1, -80, 0, 7),
        Size = UDim2.new(0, 68, 0, 16),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = card,
    })

    local bar = new("TextButton", {
        Position = UDim2.new(0, 12, 0, 32),
        Size = UDim2.new(1, -24, 0, 18),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = card,
    })

    MakeCorner(bar, 8)

    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = bar,
    })

    MakeCorner(fill, 8)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.fromRGB(250, 250, 255),
        BorderSizePixel = 0,
        Parent = bar,
    })

    MakeCorner(knob, 6)

    local dragging = false

    local function SetValue(value, skip)
        value = Clamp(tonumber(value) or min, min, max)

        if decimals == 0 then
            value = math.floor(value + 0.5)
        else
            value = Round(value, decimals)
        end

        OrionPainel.Flags[flag] = value
        valueLabel.Text = tostring(value) .. suffix

        local ratio = 0

        if max ~= min then
            ratio = (value - min) / (max - min)
        end

        ratio = Clamp(ratio, 0, 1)

        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)

        if not skip then
            SafeCall(options.Callback, value)
        end
    end

    local function UpdateFromX(x)
        local absPos = bar.AbsolutePosition.X
        local absSize = math.max(1, bar.AbsoluteSize.X)
        local ratio = Clamp((x - absPos) / absSize, 0, 1)

        SetValue(min + (max - min) * ratio)
    end

    bar.MouseButton1Down:Connect(function()
        dragging = true
        UpdateFromX(UserInputService:GetMouseLocation().X)
    end)

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateFromX(input.Position.X)
        end
    end)

    OrionPainel.AddConnection(UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            UpdateFromX(input.Position.X)
        end
    end)

    OrionPainel.AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    SetValue(default, true)

    local control = {
        Base = base,
        Flag = flag,
        Type = "Slider",
    }

    function control:Set(value, skip)
        SetValue(value, skip)
    end

    function control:Get()
        return OrionPainel.Flags[flag]
    end

    OrionPainel.Controls[flag] = control

    return control
end

function OrionPainel.Tab:AddDropdown(options)
    options = options or {}

    local theme = self.Window.Theme
    local flag = options.Flag or MakeFlag("Dropdown")

    local choices = options.Options or options.Choices or {}
    local default = options.Default or choices[1] or ""

    OrionPainel.Flags[flag] = default

    local open = false

    local base = CreateElementBase(self, 42)
    local card = CreateCard(base, theme)

    local label = new("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -210, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Dropdown",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local button = new("TextButton", {
        Position = UDim2.new(1, -186, 0.5, -13),
        Size = UDim2.new(0, 174, 0, 26),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Text = tostring(default),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = theme.Text,
        Parent = card,
    })

    MakeCorner(button, 8)

    local list = new("ScrollingFrame", {
        Position = UDim2.new(0, 8, 0, 40),
        Size = UDim2.new(1, -16, 0, 0),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.new(),
        Visible = false,
        Parent = card,
    })

    MakeCorner(list, 8)
    MakeStroke(list, theme.Stroke, 1)
    MakePadding(list, 4, 4, 4, 4)

    local listLayout = MakeListLayout(list, 2)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    pcall(function()
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end)

    local control = {
        Base = base,
        Flag = flag,
        Type = "Dropdown",
    }

    local function Resize()
        local count = #choices
        local height = math.min(count * 26 + 8, 150)

        if open then
            base.Size = UDim2.new(1, -4, 0, 42 + height + 8)
            list.Size = UDim2.new(1, -16, 0, height)
            list.Visible = true
            button.Text = "▲ " .. tostring(OrionPainel.Flags[flag])
        else
            base.Size = UDim2.new(1, -4, 0, 42)
            list.Visible = false
            button.Text = tostring(OrionPainel.Flags[flag])
        end
    end

    local function ClearOptions()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end

    local function SetSelected(value, skip)
        OrionPainel.Flags[flag] = value
        button.Text = tostring(value)

        if not skip then
            SafeCall(options.Callback, value)
        end
    end

    local function RefreshOptions()
        ClearOptions()

        for _, choice in ipairs(choices) do
            local item = new("TextButton", {
                Size = UDim2.new(1, -6, 0, 24),
                BackgroundColor3 = theme.Sidebar,
                BorderSizePixel = 0,
                Text = tostring(choice),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.SubText,
                Parent = list,
            })

            MakeCorner(item, 6)

            item.MouseEnter:Connect(function()
                item.BackgroundColor3 = theme.CardHover
            end)

            item.MouseLeave:Connect(function()
                item.BackgroundColor3 = theme.Sidebar
            end)

            item.MouseButton1Click:Connect(function()
                SetSelected(choice)
                open = false
                Resize()
            end)
        end

        Resize()
    end

    button.MouseButton1Click:Connect(function()
        open = not open
        Resize()
    end)

    function control:SetOptions(newOptions)
        choices = newOptions or {}
        RefreshOptions()
    end

    function control:SetSelected(value, skip)
        SetSelected(value, skip)
    end

    function control:Set(value, skip)
        SetSelected(value, skip)
    end

    function control:Get()
        return OrionPainel.Flags[flag]
    end

    RefreshOptions()
    SetSelected(default, true)

    OrionPainel.Controls[flag] = control

    return control
end

function OrionPainel.Tab:AddInput(options)
    options = options or {}

    local theme = self.Window.Theme
    local flag = options.Flag or MakeFlag("Input")
    local default = options.Default or ""

    OrionPainel.Flags[flag] = default

    local base = CreateElementBase(self, 42)
    local card = CreateCard(base, theme)

    local label = new("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -210, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Input",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local box = new("TextBox", {
        Position = UDim2.new(1, -186, 0.5, -13),
        Size = UDim2.new(0, 174, 0, 26),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Text = default,
        PlaceholderText = options.Placeholder or "Digite...",
        PlaceholderColor3 = theme.SubText,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = theme.Text,
        ClearTextOnFocus = false,
        Parent = card,
    })

    MakeCorner(box, 8)

    box.FocusLost:Connect(function(enterPressed)
        OrionPainel.Flags[flag] = box.Text
        SafeCall(options.Callback, box.Text, enterPressed)
    end)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        if options.Live then
            OrionPainel.Flags[flag] = box.Text
            SafeCall(options.Callback, box.Text, false)
        end
    end)

    local control = {
        Base = base,
        Flag = flag,
        Type = "Input",
    }

    function control:Set(text)
        box.Text = tostring(text)
        OrionPainel.Flags[flag] = box.Text
    end

    function control:Get()
        return OrionPainel.Flags[flag]
    end

    OrionPainel.Controls[flag] = control

    return control
end

function OrionPainel.Tab:AddKeybind(options)
    options = options or {}

    local theme = self.Window.Theme
    local flag = options.Flag or MakeFlag("Keybind")

    local key = options.Key or options.Default or Enum.KeyCode.Unknown
    local mode = options.Mode or "Toggle"
    local state = false
    local listening = false

    if mode ~= "Toggle" and mode ~= "Hold" then
        mode = "Toggle"
    end

    OrionPainel.Flags[flag] = {
        Key = key.Name,
        Mode = mode,
        State = state,
    }

    local base = CreateElementBase(self, 42)
    local card = CreateCard(base, theme)

    local label = new("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -220, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Keybind",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local modeButton = new("TextButton", {
        Position = UDim2.new(1, -186, 0.5, -13),
        Size = UDim2.new(0, 84, 0, 26),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Text = mode,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = theme.SubText,
        Parent = card,
    })

    MakeCorner(modeButton, 8)

    local keyButton = new("TextButton", {
        Position = UDim2.new(1, -96, 0.5, -13),
        Size = UDim2.new(0, 84, 0, 26),
        BackgroundColor3 = theme.Input,
        BorderSizePixel = 0,
        Text = key.Name,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = theme.Text,
        Parent = card,
    })

    MakeCorner(keyButton, 8)

    local function KeyName(value)
        if value == Enum.KeyCode.Unknown then
            return "None"
        end

        return value.Name
    end

    local function UpdateFlag()
        OrionPainel.Flags[flag] = {
            Key = key.Name,
            Mode = mode,
            State = state,
        }
    end

    local function SetKey(newKey, skip)
        if TypeOf(newKey) == "string" then
            local ok, found = pcall(function()
                return Enum.KeyCode[newKey]
            end)

            if ok then
                newKey = found
            else
                newKey = Enum.KeyCode.Unknown
            end
        end

        key = newKey or Enum.KeyCode.Unknown
        keyButton.Text = listening and "..." or KeyName(key)

        UpdateFlag()

        if not skip then
            SafeCall(options.OnKeyChanged, key)
        end
    end

    local function SetMode(newMode, skip)
        if newMode ~= "Toggle" and newMode ~= "Hold" then
            newMode = "Toggle"
        end

        mode = newMode
        modeButton.Text = mode

        UpdateFlag()

        if not skip then
            SafeCall(options.OnModeChanged, mode)
        end
    end

    keyButton.MouseButton1Click:Connect(function()
        listening = true
        keyButton.Text = "..."
    end)

    modeButton.MouseButton1Click:Connect(function()
        if mode == "Toggle" then
            SetMode("Hold")
        else
            SetMode("Toggle")
        end
    end)

    OrionPainel.AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                SetKey(input.KeyCode)
            end

            return
        end

        if gameProcessed or IsTyping() then
            return
        end

        if key ~= Enum.KeyCode.Unknown and input.KeyCode == key then
            if mode == "Toggle" then
                state = not state
                UpdateFlag()
                SafeCall(options.Callback, state, key)
            elseif mode == "Hold" then
                state = true
                UpdateFlag()
                SafeCall(options.Callback, true, key)
            end
        end
    end)

    OrionPainel.AddConnection(UserInputService.InputEnded:Connect(function(input)
        if key ~= Enum.KeyCode.Unknown and input.KeyCode == key and mode == "Hold" then
            state = false
            UpdateFlag()
            SafeCall(options.Callback, false, key)
        end
    end)

    SetKey(key, true)
    SetMode(mode, true)

    local control = {
        Base = base,
        Flag = flag,
        Type = "Keybind",
    }

    function control:Set(value)
        if TypeOf(value) == "table" then
            if value.Key then
                SetKey(value.Key, true)
            end

            if value.Mode then
                SetMode(value.Mode, true)
            end

            return
        end

        if TypeOf(value) == "EnumItem" or TypeOf(value) == "string" then
            SetKey(value, true)
        end
    end

    function control:Get()
        return OrionPainel.Flags[flag]
    end

    OrionPainel.Controls[flag] = control

    return control
end

function OrionPainel.Tab:AddColorPicker(options)
    options = options or {}

    local theme = self.Window.Theme
    local flag = options.Flag or MakeFlag("Color")

    local default = options.Color or options.Default or Color3.fromRGB(255, 255, 255)
    local h, s, v = Color3.toHSV(default)

    OrionPainel.Flags[flag] = default

    local open = false

    local base = CreateElementBase(self, 42)
    local card = CreateCard(base, theme)

    local label = new("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -96, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Cor",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local preview = new("TextButton", {
        Position = UDim2.new(1, -52, 0.5, -13),
        Size = UDim2.fromOffset(40, 26),
        BackgroundColor3 = default,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = card,
    })

    MakeCorner(preview, 8)
    MakeStroke(preview, theme.Stroke, 1)

    local picker = new("Frame", {
        Position = UDim2.new(0, 8, 0, 40),
        Size = UDim2.new(1, -16, 0, 170),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Visible = false,
        Parent = card,
    })

    MakeCorner(picker, 8)
    MakeStroke(picker, theme.Stroke, 1)

    local svArea = new("TextButton", {
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 110),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = picker,
    })

    MakeCorner(svArea, 8)

    local whiteGradient = Instance.new("UIGradient")
    whiteGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
    })
    whiteGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    whiteGradient.Parent = svArea

    local blackGradient = Instance.new("UIGradient")
    blackGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
    })
    blackGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    blackGradient.Rotation = 90
    blackGradient.Parent = svArea

    local svPointer = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(s, 0, 1 - v, 0),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = svArea,
    })

    MakeCorner(svPointer, 5)
    MakeStroke(svPointer, Color3.fromRGB(0, 0, 0), 1)

    local hueSlider = new("TextButton", {
        Position = UDim2.new(0, 8, 0, 126),
        Size = UDim2.new(1, -16, 0, 16),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = picker,
    })

    MakeCorner(hueSlider, 8)

    local hueGradient = Instance.new("UIGradient")
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
    })
    hueGradient.Parent = hueSlider

    local hueIndicator = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(h, 0, 0.5, 0),
        Size = UDim2.new(0, 8, 0, 18),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = hueSlider,
    })

    MakeCorner(hueIndicator, 4)
    MakeStroke(hueIndicator, Color3.fromRGB(0, 0, 0), 1)

    local rgbLabel = new("TextLabel", {
        Position = UDim2.new(0, 10, 0, 148),
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = picker,
    })

    local control = {
        Base = base,
        Flag = flag,
        Type = "ColorPicker",
    }

    local svDragging = false
    local hueDragging = false

    local function Resize()
        if open then
            base.Size = UDim2.new(1, -4, 0, 42 + 178)
            picker.Visible = true
        else
            base.Size = UDim2.new(1, -4, 0, 42)
            picker.Visible = false
        end
    end

    local function UpdateColor(skip)
        local color = Color3.fromHSV(h, s, v)

        OrionPainel.Flags[flag] = color
        preview.BackgroundColor3 = color
        svArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svPointer.Position = UDim2.new(s, 0, 1 - v, 0)
        hueIndicator.Position = UDim2.new(h, 0, 0.5, 0)

        rgbLabel.Text = string.format(
            "R:%d G:%d B:%d",
            math.floor(color.R * 255),
            math.floor(color.G * 255),
            math.floor(color.B * 255)
        )

        if not skip then
            SafeCall(options.Callback, color)
        end
    end

    local function UpdateSV(x, y)
        local pos = svArea.AbsolutePosition
        local size = svArea.AbsoluteSize

        s = Clamp((x - pos.X) / math.max(1, size.X), 0, 1)
        v = 1 - Clamp((y - pos.Y) / math.max(1, size.Y), 0, 1)

        UpdateColor()
    end

    local function UpdateHue(x)
        local pos = hueSlider.AbsolutePosition
        local size = hueSlider.AbsoluteSize

        h = Clamp((x - pos.X) / math.max(1, size.X), 0, 1)

        UpdateColor()
    end

    preview.MouseButton1Click:Connect(function()
        open = not open
        Resize()
    end)

    svArea.MouseButton1Down:Connect(function()
        svDragging = true
        local mouse = UserInputService:GetMouseLocation()
        UpdateSV(mouse.X, mouse.Y)
    end)

    svArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
            UpdateSV(input.Position.X, input.Position.Y)
        end
    end)

    hueSlider.MouseButton1Down:Connect(function()
        hueDragging = true
        UpdateHue(UserInputService:GetMouseLocation().X)
    end)

    hueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
            UpdateHue(input.Position.X)
        end
    end)

    OrionPainel.AddConnection(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        if svDragging then
            UpdateSV(input.Position.X, input.Position.Y)
        end

        if hueDragging then
            UpdateHue(input.Position.X)
        end
    end)

    OrionPainel.AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
            hueDragging = false
        end
    end)

    function control:Set(color)
        if TypeOf(color) ~= "Color3" then
            return
        end

        h, s, v = Color3.toHSV(color)
        UpdateColor(true)
    end

    function control:Get()
        return OrionPainel.Flags[flag]
    end

    Resize()
    UpdateColor(true)

    OrionPainel.Controls[flag] = control

    return control
end

local function SerializeValue(value)
    local t = TypeOf(value)

    if t == "Color3" then
        return {
            __orion = "Color3",
            R = value.R,
            G = value.G,
            B = value.B,
        }
    end

    if t == "EnumItem" then
        return {
            __orion = "Enum",
            EnumType = value.EnumType.Name,
            Name = value.Name,
        }
    end

    if t == "table" then
        local out = {}

        for k, v in pairs(value) do
            out[k] = SerializeValue(v)
        end

        return out
    end

    return value
end

local function DeserializeValue(value)
    if type(value) ~= "table" then
        return value
    end

    if value.__orion == "Color3" then
        return Color3.new(value.R or 1, value.G or 1, value.B or 1)
    end

    if value.__orion == "Enum" then
        local ok, enumValue = pcall(function()
            return Enum[value.EnumType][value.Name]
        end)

        if ok then
            return enumValue
        end

        return nil
    end

    local out = {}

    for k, v in pairs(value) do
        out[k] = DeserializeValue(v)
    end

    return out
end

function OrionPainel:FileSupported()
    return type(writefile) == "function" and type(readfile) == "function"
end

function OrionPainel:GetIndexPath()
    return self.ConfigFolder .. "/index.json"
end

function OrionPainel:GetConfigPath(name)
    return self.ConfigFolder .. "/" .. name .. ".json"
end

function OrionPainel:EnsureConfigFolder()
    if makefolder then
        pcall(makefolder, self.ConfigFolder)
    end
end

function OrionPainel:ReadIndex()
    if not self:FileSupported() then
        return {}
    end

    local path = self:GetIndexPath()

    if isfile and not isfile(path) then
        return {}
    end

    local ok, result = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if ok and type(result) == "table" then
        return result
    end

    return {}
end

function OrionPainel:WriteIndex(list)
    if not self:FileSupported() then
        return false
    end

    self:EnsureConfigFolder()

    local ok = pcall(function()
        writefile(self:GetIndexPath(), HttpService:JSONEncode(list))
    end)

    return ok
end

function OrionPainel:GetConfigs()
    return self:ReadIndex()
end

function OrionPainel:SaveConfig(name)
    if not self:FileSupported() then
        return false, "Executor sem writefile/readfile"
    end

    if not name or name == "" then
        return false, "Nome inválido"
    end

    self:EnsureConfigFolder()

    local data = SerializeValue(self.Flags)
    local json = HttpService:JSONEncode(data)

    local ok = pcall(function()
        writefile(self:GetConfigPath(name), json)
    end)

    if not ok then
        return false, "Falha ao salvar arquivo"
    end

    local index = self:ReadIndex()

    if not TableFind(index, name) then
        table.insert(index, name)
        self:WriteIndex(index)
    end

    return true
end

function OrionPainel:LoadConfig(name)
    if not self:FileSupported() then
        return false, "Executor sem writefile/readfile"
    end

    if not name or name == "" then
        return false, "Nome inválido"
    end

    local path = self:GetConfigPath(name)

    if isfile and not isfile(path) then
        return false, "Config não existe"
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not ok then
        return false, "Config inválida"
    end

    local clean = DeserializeValue(decoded)

    for flag, value in pairs(clean) do
        self.Flags[flag] = value

        local control = self.Controls[flag]

        if control and control.Set then
            SafeCall(control.Set, control, value)
        end
    end

    return true
end

function OrionPainel:DeleteConfig(name)
    if not self:FileSupported() then
        return false, "Executor sem writefile/readfile"
    end

    if not name or name == "" then
        return false, "Nome inválido"
    end

    local path = self:GetConfigPath(name)

    if delfile then
        pcall(delfile, path)
    end

    local index = self:ReadIndex()
    local found = TableFind(index, name)

    if found then
        table.remove(index, found)
        self:WriteIndex(index)
    end

    return true
end

function OrionPainel.Window:AddConfigTab(name)
    local tab = self:AddTab(name or "Configs", "⚙")

    tab:AddSection("Configurações")

    tab:AddLabel({
        Text = "Digite um nome para salvar a config atual.",
    })

    local nameInput = tab:AddInput({
        Name = "Nome",
        Placeholder = "minha_config",
        Default = "default",
    })

    local configList = tab:AddDropdown({
        Name = "Configs salvas",
        Options = {},
        Default = "",
    })

    local status = tab:AddLabel({
        Text = "Status: pronto",
        Color = self.Theme.SubText,
    })

    local function RefreshConfigs()
        local configs = OrionPainel:GetConfigs()

        configList:SetOptions(configs)

        if #configs > 0 then
            configList:Set(configs[1], true)
        end

        status:Set("Status: " .. #configs .. " configs encontradas")
    end

    tab:AddButton({
        Name = "Salvar config",
        Callback = function()
            local nameText = nameInput:Get()
            local ok, err = OrionPainel:SaveConfig(nameText)

            if ok then
                status:Set("Status: config salva")
                RefreshConfigs()
                OrionPainel:Notify({
                    Title = "Config",
                    Text = "Config salva: " .. nameText,
                    Type = "Success",
                })
            else
                status:Set("Status: " .. tostring(err))
                OrionPainel:Notify({
                    Title = "Config",
                    Text = tostring(err),
                    Type = "Error",
                })
            end
        end,
    })

    tab:AddButton({
        Name = "Carregar config",
        Callback = function()
            local selected = configList:Get()

            if selected == "" then
                status:Set("Status: selecione uma config")
                return
            end

            local ok, err = OrionPainel:LoadConfig(selected)

            if ok then
                status:Set("Status: config carregada")
                OrionPainel:Notify({
                    Title = "Config",
                    Text = "Config carregada: " .. selected,
                    Type = "Success",
                })
            else
                status:Set("Status: " .. tostring(err))
                OrionPainel:Notify({
                    Title = "Config",
                    Text = tostring(err),
                    Type = "Error",
                })
            end
        end,
    })

    tab:AddButton({
        Name = "Deletar config",
        Callback = function()
            local selected = configList:Get()

            if selected == "" then
                status:Set("Status: selecione uma config")
                return
            end

            local ok, err = OrionPainel:DeleteConfig(selected)

            if ok then
                status:Set("Status: config deletada")
                RefreshConfigs()
                OrionPainel:Notify({
                    Title = "Config",
                    Text = "Config deletada: " .. selected,
                    Type = "Warning",
                })
            else
                status:Set("Status: " .. tostring(err))
            end
        end,
    })

    tab:AddButton({
        Name = "Atualizar lista",
        Callback = function()
            RefreshConfigs()
        end,
    })

    RefreshConfigs()

    return tab
end

function OrionPainel:ToggleAll()
    local anyVisible = false

    for _, window in ipairs(self.Windows) do
        if window.Main and window.Main.Visible then
            anyVisible = true
            break
        end
    end

    for _, window in ipairs(self.Windows) do
        window:Toggle(not anyVisible)
    end
end

function OrionPainel:SetToggleKey(keyCode)
    self.ToggleKey = keyCode
end

OrionPainel.AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if IsTyping() then
        return
    end

    if input.KeyCode == OrionPainel.ToggleKey then
        OrionPainel:ToggleAll()
    end
end)

function OrionPainel:DestroyAll()
    self.DisconnectAll()

    for _, window in ipairs(self.Windows) do
        pcall(function()
            window:Destroy()
        end)
    end

    self.Windows = {}

    if NotifyGui then
        NotifyGui:Destroy()
        NotifyGui = nil
    end

    if WatermarkGui then
        WatermarkGui:Destroy()
        WatermarkGui = nil
    end
end

function OrionPainel:Demo()
    local window = self:CreateWindow({
        Title = "Orion Painel",
        Subtitle = "Painel completo | v" .. self.Version,
        Width = 720,
        Height = 480,
    })

    local mainTab = window:AddTab("Principal", "⌂")

    mainTab:AddSection("Básico")

    mainTab:AddButton({
        Name = "Mostrar notificação",
        Callback = function()
            self:Notify({
                Title = "Orion",
                Text = "Botão clicado com sucesso.",
                Type = "Success",
            })
        end,
    })

    mainTab:AddToggle({
        Name = "Toggle de exemplo",
        Default = false,
        Callback = function(value)
            self:Notify({
                Title = "Toggle",
                Text = "Estado: " .. tostring(value),
                Type = "Info",
            })
        end,
    })

    mainTab:AddSlider({
        Name = "Velocidade",
        Min = 0,
        Max = 100,
        Default = 50,
        Suffix = "%",
        Callback = function(value)
            self.Flags.ExemploSlider = value
        end,
    })

    mainTab:AddDropdown({
        Name = "Modo",
        Options = {
            "Padrão",
            "Agressivo",
            "Suave",
            "Custom",
        },
        Default = "Padrão",
        Callback = function(value)
            self:Notify({
                Title = "Dropdown",
                Text = "Modo selecionado: " .. tostring(value),
                Type = "Info",
            })
        end,
    })

    mainTab:AddInput({
        Name = "Mensagem",
        Placeholder = "Digite algo...",
        Default = "",
        Callback = function(text)
            self.Flags.ExemploTexto = text
        end,
    })

    mainTab:AddKeybind({
        Name = "Tecla de teste",
        Key = Enum.KeyCode.RightShift,
        Mode = "Toggle",
        Callback = function(state)
            self:Notify({
                Title = "Keybind",
                Text = "Estado da tecla: " .. tostring(state),
                Type = "Warning",
            })
        end,
    })

    mainTab:AddColorPicker({
        Name = "Cor principal",
        Default = Color3.fromRGB(124, 92, 255),
        Callback = function(color)
            self.Flags.ExemploCor = color
        end,
    })

    local visualTab = window:AddTab("Visual", "✦")

    visualTab:AddSection("Exemplos visuais")

    visualTab:AddLabel({
        Text = "Essa aba serve para mostrar labels, seções e elementos simples.",
    })

    visualTab:AddButton({
        Name = "Botão 1",
        Callback = function()
            self:Notify({
                Title = "Visual",
                Text = "Botão 1",
                Type = "Info",
            })
        end,
    })

    visualTab:AddButton({
        Name = "Botão 2",
        Callback = function()
            self:Notify({
                Title = "Visual",
                Text = "Botão 2",
                Type = "Info",
            })
        end,
    })

    visualTab:AddSlider({
        Name = "Opacidade",
        Min = 0,
        Max = 1,
        Default = 1,
        Decimals = 2,
        Callback = function(value)
            self.Flags.ExemploOpacidade = value
        end,
    })

    window:AddConfigTab("Config")

    if self.UseWatermark then
        self:SetWatermark(self.WatermarkText)
    end

    self:Notify({
        Title = "Orion Painel",
        Text = "Painel carregado. Pressione RightShift para abrir/fechar.",
        Type = "Success",
        Duration = 5,
    })

    return window
end

local function Spawn(fn)
    if task and task.spawn then
        task.spawn(fn)
    else
        spawn(fn)
    end
end

if not _G.OrionNoDemo then
    Spawn(function()
        OrionPainel:Demo()
    end)
end

return OrionPainel
