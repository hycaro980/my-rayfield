--[[
	Rayfield UI Library
	Modern, lightweight interface system for Roblox scripts.
	Drop this into a ModuleScript named "Rayfield".
]]

local Rayfield = {}
Rayfield.__index = Rayfield

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Theme Defaults
local THEME = {
	Main = Color3.fromRGB(25, 25, 30),
	Accent = Color3.fromRGB(90, 120, 255),
	Text = Color3.fromRGB(240, 240, 240),
	DimText = Color3.fromRGB(160, 160, 170),
	ElementBg = Color3.fromRGB(35, 35, 42),
	Hover = Color3.fromRGB(45, 45, 55),
	Border = Color3.fromRGB(50, 50, 60)
}

-- Utility: Smooth Tween Wrapper
local function tween(instance, props, duration, style, direction)
	local info = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local t = TweenService:Create(instance, info, props)
	t:Play()
	return t
end

-- Utility: Create Instance Shorthand
local function create(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k == "Parent" then continue end
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

-----------------------------------------------------------
-- ELEMENT CONSTRUCTORS
-----------------------------------------------------------

local Elements = {}

function Elements.Button(parent, config)
	local frame = create("Frame", {
		Size = UDim2.new(1, -20, 0, 36),
		BackgroundColor3 = THEME.ElementBg,
		Position = UDim2.new(0, 10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y
	}, parent)
	
	create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
	
	local btn = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = config.Name or "Button",
		TextColor3 = THEME.Text,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		Parent = frame
	})
	
	btn.MouseEnter:Connect(function() tween(frame, {BackgroundColor3 = THEME.Hover}, 0.15) end)
	btn.MouseLeave:Connect(function() tween(frame, {BackgroundColor3 = THEME.ElementBg}, 0.15) end)
	btn.MouseButton1Click:Connect(function() 
		tween(frame, {BackgroundColor3 = THEME.Accent}, 0.1)
		task.delay(0.1, function() tween(frame, {BackgroundColor3 = THEME.ElementBg}, 0.2) end)
		if config.Callback then config.Callback() end
	end)
	
	return { Instance = frame }
end

function Elements.Toggle(parent, config)
	local state = config.CurrentValue or false
	
	local frame = create("Frame", {
		Size = UDim2.new(1, -20, 0, 36),
		BackgroundColor3 = THEME.ElementBg,
		Position = UDim2.new(0, 10, 0, 0)
	}, parent)
	create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
	
	local label = create("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = config.Name or "Toggle",
		TextColor3 = THEME.Text,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame
	})
	
	local indicator = create("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -24, 0.5, 0),
		BackgroundColor3 = state and THEME.Accent or THEME.DimText,
		Parent = frame
	})
	create("UICorner", {CornerRadius = UDim.new(1, 0)}, indicator)
	
	local btn = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = frame
	})
	
	local function updateVisual()
		tween(indicator, {BackgroundColor3 = state and THEME.Accent or THEME.DimText}, 0.2)
	end
	
	btn.MouseButton1Click:Connect(function()
		state = not state
		updateVisual()
		if config.Callback then config.Callback(state) end
	end)
	
	return { 
		Instance = frame,
		Set = function(val) state = val; updateVisual() end,
		Get = function() return state end
	}
end

function Elements.Slider(parent, config)
	local min = config.Min or 0
	local max = config.Max or 100
	local current = config.CurrentValue or min
	
	local frame = create("Frame", {
		Size = UDim2.new(1, -20, 0, 46),
		BackgroundColor3 = THEME.ElementBg,
		Position = UDim2.new(0, 10, 0, 0)
	}, parent)
	create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
	
	local label = create("TextLabel", {
		Size = UDim2.new(1, -60, 0, 20),
		Position = UDim2.new(0, 12, 0, 6),
		BackgroundTransparency = 1,
		Text = config.Name or "Slider",
		TextColor3 = THEME.Text,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame
	})
	
	local valLabel = create("TextLabel", {
		Size = UDim2.new(0, 50, 0, 20),
		Position = UDim2.new(1, -12, 0, 6),
		BackgroundTransparency = 1,
		Text = tostring(current),
		TextColor3 = THEME.Accent,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame
	})
	
	local track = create("Frame", {
		Size = UDim2.new(1, -24, 0, 6),
		Position = UDim2.new(0, 12, 0, 32),
		BackgroundColor3 = THEME.Main,
		Parent = frame
	})
	create("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
	
	local fill = create("Frame", {
		Size = UDim2.new((current - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = THEME.Accent,
		Parent = track
	})
	create("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
	
	local dragging = false
	local inputBtn = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = frame
	})
	
	local function update(val)
		current = math.clamp(val, min, max)
		local pct = (current - min) / (max - min)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		valLabel.Text = string.format("%.1f", current)
		if config.Callback then config.Callback(current) end
	end
	
	inputBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	
	RunService.RenderStepped:Connect(function()
		if dragging then
			local mousePos = UserInputService:GetMouseLocation().X
			local rel = (mousePos - track.AbsolutePosition.X) / track.AbsoluteSize.X
			update(min + (max - min) * math.clamp(rel, 0, 1))
		end
	end)
	
	return { Instance = frame, Set = update, Get = function() return current end }
end

-----------------------------------------------------------
-- TAB & WINDOW SYSTEM
-----------------------------------------------------------

function Rayfield.CreateWindow(config)
	local window = {}
	window.Tabs = {}
	window.ActiveTab = nil
	
	-- ScreenGui Container
	local screen = create("ScreenGui", {
		Name = "Rayfield_UI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = game:GetService("CoreGui")
	})
	
	-- Main Frame
	local main = create("Frame", {
		Name = "MainWindow",
		Size = UDim2.new(0, config.Size and config.Size.X or 500, 0, config.Size and config.Size.Y or 400),
		Position = UDim2.new(0.5, -(config.Size and config.Size.X or 500)/2, 0.5, -(config.Size and config.Size.Y or 400)/2),
		BackgroundColor3 = THEME.Main,
		ClipsDescendants = true,
		Parent = screen
	})
	create("UICorner", {CornerRadius = UDim.new(0, 10)}, main)
	create("UIStroke", {Color = THEME.Border, Thickness = 1}, main)
	
	-- Title Bar
	local titleBar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = THEME.Main,
		Parent = main
	})
	
	create("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = config.Name or "Rayfield Window",
		TextColor3 = THEME.Text,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleBar
	})
	
	-- Tab Bar Container
	local tabBar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 36),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		Parent = main
	})
	local tabLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = tabBar
	})
	
	-- Content Area
	local contentArea = create("Frame", {
		Size = UDim2.new(1, -20, 1, -80),
		Position = UDim2.new(0, 10, 0, 72),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = main
	})
	
	-- Dragging Logic
	local dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragStart = nil end
			end)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragStart and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	
	-- Tab Creator
	function window:CreateTab(tabConfig)
		local tab = {}
		tab.Elements = {}
		
		local tabBtn = create("TextButton", {
			Size = UDim2.new(0, 80, 1, 0),
			BackgroundTransparency = 1,
			Text = tabConfig.Name or "Tab",
			TextColor3 = THEME.DimText,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,
			Parent = tabBar
		})
		
		local scroll = create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = THEME.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Visible = false,
			Parent = contentArea
		})
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = scroll
		})
		
		-- Auto-resize canvas
		scroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scroll.CanvasSize = UDim2.new(0, 0, 0, scroll.UIListLayout.AbsoluteContentSize.Y + 10)
		end)
		
		local function activate()
			for _, t in pairs(window.Tabs) do
				t.Scroll.Visible = false
				t.Button.TextColor3 = THEME.DimText
			end
			scroll.Visible = true
			tabBtn.TextColor3 = THEME.Accent
			window.ActiveTab = tab
		end
		
		tabBtn.MouseButton1Click:Connect(activate)
		
		tab.Scroll = scroll
		tab.Button = tabBtn
		
		-- Element Adders
		function tab:AddButton(cfg) local e = Elements.Button(scroll, cfg); table.insert(tab.Elements, e); return e end
		function tab:AddToggle(cfg) local e = Elements.Toggle(scroll, cfg); table.insert(tab.Elements, e); return e end
		function tab:AddSlider(cfg) local e = Elements.Slider(scroll, cfg); table.insert(tab.Elements, e); return e end
		
		table.insert(window.Tabs, tab)
		if #window.Tabs == 1 then activate() end
		
		return tab
	end
	
	-- Notification System
	function window:Notify(notifConfig)
		local notif = create("Frame", {
			Size = UDim2.new(0, 260, 0, 50),
			BackgroundColor3 = THEME.ElementBg,
			Position = UDim2.new(1, 10, 1, -60),
			AnchorPoint = Vector2.new(1, 1),
			Parent = screen
		})
		create("UICorner", {CornerRadius = UDim.new(0, 8)}, notif)
		create("UIStroke", {Color = THEME.Accent, Thickness = 1}, notif)
		
		create("TextLabel", {
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = notifConfig.Content or "Notification",
			TextColor3 = THEME.Text,
			TextSize = 13,
			Font = Enum.Font.GothamMedium,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = notif
		})
		
		tween(notif, {Position = UDim2.new(1, -10, 1, -60)}, 0.3, Enum.EasingStyle.Back)
		task.delay(notifConfig.Duration or 3, function()
			tween(notif, {Position = UDim2.new(1, 10, 1, -60), BackgroundTransparency = 1}, 0.3)
			task.delay(0.3, function() notif:Destroy() end)
		end)
	end
	
	return window
end

return Rayfield
