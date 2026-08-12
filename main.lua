--[[
	BTUI - Script Hub UI Library
	Draggable, floating minimize button, transparent glass background,
	left side Tabs, right side Elements, auto scroll frames, searchable dropdown.

	Usage:
		local BTUI = loadstring(game:HttpGet("<raw url>"))()
		local Window = BTUI:CreateWindow({...})
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--============================================================
-- ICONS (Lucide) -- with safe fallback
--============================================================
-- The Footagesus Icons module can come back in a few different shapes
-- depending on version: a plain table keyed by name, a table with a
-- :Get()/.Get()/.GetAsset() accessor, or a callable module. We probe for
-- all of them so icon lookup doesn't silently fail closed.
local IconsModule
local IconsLoadOk = false
do
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
			true
		))()
	end)
	if ok and result then
		IconsModule = result
		IconsLoadOk = true
	else
		warn("[BTUI] Failed to load Lucide icon library: " .. tostring(result))
	end
end

-- Normalizes whatever the icon lookup returns into {Image=, ImageRectOffset=, ImageRectSize=}
local function NormalizeIconData(icon)
	if not icon then return nil end

	if typeof(icon) == "string" then
		-- some builds return a bare asset id / rbxassetid string
		return { Image = icon, ImageRectOffset = Vector2.new(0,0), ImageRectSize = Vector2.new(0,0) }
	end

	if typeof(icon) == "table" then
		local image = icon.id or icon.Id or icon.image or icon.Image or icon.assetId or icon.AssetId
		local offset = icon.imageRectOffset or icon.ImageRectOffset
		local size = icon.imageRectSize or icon.ImageRectSize
		if image then
			if typeof(image) == "number" then
				image = "rbxassetid://" .. tostring(image)
			elseif typeof(image) == "string" and image:match("^%d+$") then
				image = "rbxassetid://" .. image
			end
			return {
				Image = image,
				ImageRectOffset = offset or Vector2.new(0,0),
				ImageRectSize = size or Vector2.new(0,0),
			}
		end
	end

	return nil
end

local function GetIcon(name)
	if not IconsLoadOk or not name or name == "" then return nil end

	-- try every plausible access pattern; return the first that yields data
	local attempts = {
		function() return IconsModule[name] end,
		function() return IconsModule.Get and IconsModule:Get(name) end,
		function() return IconsModule.Get and IconsModule.Get(name) end,
		function() return IconsModule.GetAsset and IconsModule:GetAsset(name) end,
		function() return typeof(IconsModule) == "function" and IconsModule(name) end,
	}

	for _, attempt in ipairs(attempts) do
		local ok, icon = pcall(attempt)
		if ok and icon then
			local normalized = NormalizeIconData(icon)
			if normalized then return normalized end
		end
	end

	return nil
end

-- Resolves ANY of: lucide icon name (string), numeric asset id (number),
-- numeric asset id (string of digits), full "rbxassetid://..." string,
-- or a full "http(s)://..." decal/image url. Falls back gracefully and
-- never throws, so a bad icon never blanks out unrelated UI.
local function ResolveImage(imgTarget, input)
	if not imgTarget then return end

	-- always reset rect first so a previous lucide sprite doesn't bleed through
	imgTarget.ImageRectOffset = Vector2.new(0, 0)
	imgTarget.ImageRectSize = Vector2.new(0, 0)

	if input == nil or input == "" then
		imgTarget.Image = ""
		imgTarget.Visible = false
		return
	end

	imgTarget.Visible = true

	if typeof(input) == "number" then
		imgTarget.Image = "rbxassetid://" .. tostring(math.floor(input))
		return
	end

	if typeof(input) == "string" then
		if input:match("^rbxassetid://") then
			imgTarget.Image = input
			return
		end
		if input:match("^https?://") then
			imgTarget.Image = input
			return
		end
		if input:match("^%d+$") then
			imgTarget.Image = "rbxassetid://" .. input
			return
		end

		-- treat as a lucide icon name
		local icon = GetIcon(input)
		if icon then
			imgTarget.Image = icon.Image
			imgTarget.ImageRectOffset = icon.ImageRectOffset
			imgTarget.ImageRectSize = icon.ImageRectSize
		else
			-- icon name not found: don't leave a broken/blank box invisible,
			-- just clear the image so layout stays intact, and warn so it's debuggable
			imgTarget.Image = ""
			if IconsLoadOk then
				warn(("[BTUI] Icon '%s' not found in Lucide icon set"):format(tostring(input)))
			end
		end
		return
	end
end

--============================================================
-- THEME
--============================================================
local Theme = {
	Background       = Color3.fromRGB(18, 18, 24),
	BackgroundTransparency = 0.35, -- "low" transparency value = you can see through it
	Panel            = Color3.fromRGB(26, 26, 34),
	PanelTransparency = 0.25,
	Stroke           = Color3.fromRGB(70, 70, 90),
	Accent           = Color3.fromRGB(120, 110, 255),
	AccentSecondary  = Color3.fromRGB(90, 200, 255),
	Text             = Color3.fromRGB(235, 235, 245),
	SubText          = Color3.fromRGB(160, 160, 175),
	Element          = Color3.fromRGB(32, 32, 42),
	ElementHover     = Color3.fromRGB(42, 42, 55),
	Font             = Enum.Font.GothamMedium,
	FontBold         = Enum.Font.GothamBold,
}

--============================================================
-- UTIL
--============================================================
local function Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	return inst
end

local function Tween(inst, info, props)
	local tw = TweenService:Create(inst, info, props)
	tw:Play()
	return tw
end

local QUICK = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local BOUNCE = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function MakeDraggable(handle, target)
	local dragging = false
	local dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		target.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)
end

-- Auto-manages CanvasSize + enables/disables ScrollBar visuals based on content fitting
local function AutoScroll(scrollFrame, listLayout, axis)
	axis = axis or "Y"
	local function update()
		if axis == "Y" then
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
			local fits = listLayout.AbsoluteContentSize.Y <= scrollFrame.AbsoluteSize.Y
			scrollFrame.ScrollBarThickness = fits and 0 or 4
			scrollFrame.ScrollingEnabled = not fits == false or true
		else
			scrollFrame.CanvasSize = UDim2.new(0, listLayout.AbsoluteContentSize.X + 8, 0, 0)
			local fits = listLayout.AbsoluteContentSize.X <= scrollFrame.AbsoluteSize.X
			scrollFrame.ScrollBarThickness = fits and 0 or 4
		end
	end
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	scrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	update()
	return update
end

local function Corner(radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function Stroke(color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0.5,
	})
end

local function Padding(t, r, b, l)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft = UDim.new(0, l or 0),
	})
end

--============================================================
-- ROOT GUI
--============================================================
local function GetGuiParent()
	local ok, gethui = pcall(function() return gethui() end)
	if ok and gethui then return gethui() end
	if RunService:IsStudio() then
		return LocalPlayer:WaitForChild("PlayerGui")
	end
	return CoreGui
end

local ScreenGui = Create("ScreenGui", {
	Name = "BTUI_" .. tostring(math.random(10000,99999)),
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
})
pcall(function() ScreenGui.Parent = GetGuiParent() end)
if not ScreenGui.Parent then
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--============================================================
-- LIBRARY
--============================================================
local BTUI = {}
BTUI.__index = BTUI

--============================================================
-- WINDOW
--============================================================
function BTUI:CreateWindow(config)
	config = config or {}
	local Window = {}
	Window.__index = Window
	Window.Tabs = {}
	Window.CurrentTab = nil

	local WIDTH, HEIGHT = 550, 340

	----------------------------------------------------------------
	-- Main frame (transparent glass background)
	----------------------------------------------------------------
	local Main = Create("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		Position = UDim2.new(0.5, -WIDTH/2, 0.5, -HEIGHT/2),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = Theme.BackgroundTransparency,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = ScreenGui,
	}, {
		Corner(14),
		Stroke(Theme.Stroke, 1, 0.4),
	})

	-- subtle blur-like gradient overlay to sell the "glass" look
	Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200,200,220)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.92),
			NumberSequenceKeypoint.new(1, 0.97),
		}),
		Rotation = 45,
		Parent = Main,
	})

	Main.Size = UDim2.fromOffset(WIDTH, 0)
	Main.Visible = true

	----------------------------------------------------------------
	-- Top bar
	----------------------------------------------------------------
	local TopBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Parent = Main,
	}, {
		Corner(14),
	})
	-- mask bottom corners of topbar square
	Create("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 1, -14),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Parent = TopBar,
	})

	local LogoImg = Create("ImageLabel", {
		Name = "Logo",
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromOffset(12, 9),
		BackgroundTransparency = 1,
		Parent = TopBar,
	})
	ResolveImage(LogoImg, config.Image)

	local TitleLabel = Create("TextLabel", {
		Name = "Title",
		Size = UDim2.fromOffset(300, 20),
		Position = UDim2.fromOffset(52, 6),
		BackgroundTransparency = 1,
		Font = Theme.FontBold,
		Text = config.Title or "Window",
		TextColor3 = Theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TopBar,
	})

	local SubtitleLabel = Create("TextLabel", {
		Name = "Subtitle",
		Size = UDim2.fromOffset(300, 16),
		Position = UDim2.fromOffset(52, 26),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		Text = config.Subtitle or "",
		TextColor3 = Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = (config.Subtitle ~= nil and config.Subtitle ~= ""),
		Parent = TopBar,
	})

	-- Close Button
	local CloseBtn = Create("ImageButton", {
		Name = "CloseBtn",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -38, 0, 11),
		BackgroundColor3 = Theme.Element,
		BackgroundTransparency = 0.2,
		AutoButtonColor = false,
		Parent = TopBar,
	}, { Corner(8) })
	local CloseIcon = Create("ImageLabel", {
		Size = UDim2.fromOffset(16,16),
		Position = UDim2.new(0.5,-8,0.5,-8),
		BackgroundTransparency = 1,
		ImageColor3 = Theme.Text,
		Parent = CloseBtn,
	})
	ResolveImage(CloseIcon, "x")

	CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, QUICK, {BackgroundColor3 = Color3.fromRGB(200,60,60)}) end)
	CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, QUICK, {BackgroundColor3 = Theme.Element}) end)

	-- Search bar (icon + textbox) - lives in topbar, right-aligned before close
	local SearchHolder = Create("Frame", {
		Name = "SearchHolder",
		Size = UDim2.fromOffset(150, 28),
		Position = UDim2.new(1, -196, 0, 11),
		BackgroundColor3 = Theme.Element,
		BackgroundTransparency = 0.2,
		Visible = config.SearchBar and true or false,
		Parent = TopBar,
	}, { Corner(8) })

	local SearchIcon = Create("ImageLabel", {
		Size = UDim2.fromOffset(14,14),
		Position = UDim2.fromOffset(8, 7),
		BackgroundTransparency = 1,
		ImageColor3 = Theme.SubText,
		Parent = SearchHolder,
	})
	ResolveImage(SearchIcon, "search")

	local SearchBox = Create("TextBox", {
		Size = UDim2.new(1, -32, 1, 0),
		Position = UDim2.fromOffset(28, 0),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Theme.SubText,
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = SearchHolder,
	})

	----------------------------------------------------------------
	-- Body: left tab column, right element panel
	----------------------------------------------------------------
	local Body = Create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, -16, 1, -58),
		Position = UDim2.fromOffset(8, 50),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	-- LEFT: Tab list box
	local TabBox = Create("Frame", {
		Name = "TabBox",
		Size = UDim2.fromOffset(140, 0),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Parent = Body,
	}, { Corner(10), Stroke(Theme.Stroke, 1, 0.55) })
	TabBox.Size = UDim2.new(0, 140, 1, 0)

	local TabList = Create("ScrollingFrame", {
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0,0,0,0),
		Parent = TabBox,
	}, { Padding(8,6,8,6) })

	local TabListLayout = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = TabList,
	})
	AutoScroll(TabList, TabListLayout, "Y")

	-- RIGHT: Elements box
	local ElementBox = Create("Frame", {
		Name = "ElementBox",
		Size = UDim2.new(1, -148, 1, 0),
		Position = UDim2.fromOffset(148, 0),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Parent = Body,
	}, { Corner(10), Stroke(Theme.Stroke, 1, 0.55) })

	local ElementList = Create("ScrollingFrame", {
		Name = "ElementList",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0,0,0,0),
		Parent = ElementBox,
	}, { Padding(10,10,10,10) })

	local ElementListLayout = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = ElementList,
	})
	AutoScroll(ElementList, ElementListLayout, "Y")

	----------------------------------------------------------------
	-- Dragging (top bar only)
	----------------------------------------------------------------
	MakeDraggable(TopBar, Main)

	----------------------------------------------------------------
	-- Open animation
	----------------------------------------------------------------
	Tween(Main, SMOOTH, { Size = UDim2.fromOffset(WIDTH, HEIGHT) })

	----------------------------------------------------------------
	-- Minimize / Restore state
	----------------------------------------------------------------
	Window._visible = true

	local function SetVisible(vis)
		Window._visible = vis
		if vis then
			Main.Visible = true
			Main.Size = UDim2.fromOffset(WIDTH, 0)
			Main.BackgroundTransparency = 1
			Tween(Main, SMOOTH, { Size = UDim2.fromOffset(WIDTH, HEIGHT), BackgroundTransparency = Theme.BackgroundTransparency })
		else
			local tw = Tween(Main, SMOOTH, { Size = UDim2.fromOffset(WIDTH, 0), BackgroundTransparency = 1 })
			tw.Completed:Connect(function()
				if not Window._visible then
					Main.Visible = false
				end
			end)
		end
	end

	CloseBtn.MouseButton1Click:Connect(function()
		local tw = Tween(Main, SMOOTH, { Size = UDim2.fromOffset(WIDTH, 0), BackgroundTransparency = 1 })
		tw.Completed:Connect(function()
			ScreenGui:Destroy()
		end)
	end)

	----------------------------------------------------------------
	-- Search filter across current tab elements
	----------------------------------------------------------------
	if config.SearchBar then
		SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local query = SearchBox.Text:lower()
			for _, child in ipairs(ElementList:GetChildren()) do
				if child:IsA("Frame") and child:GetAttribute("ElementTitle") then
					local title = tostring(child:GetAttribute("ElementTitle")):lower()
					child.Visible = (query == "" or title:find(query, 1, true) ~= nil)
				end
			end
		end)
	end

	----------------------------------------------------------------
	-- Internal refs
	----------------------------------------------------------------
	Window._Main = Main
	Window._TopBar = TopBar
	Window._TabList = TabList
	Window._TabListLayout = TabListLayout
	Window._ElementList = ElementList
	Window._ElementListLayout = ElementListLayout
	Window._SetVisible = SetVisible
	Window._Width = WIDTH
	Window._Height = HEIGHT

	setmetatable(Window, Window)

	--========================================================
	-- CreateMinimizeBtn -> single floating button that toggles
	-- the whole UI open/closed. Starts open (window visible,
	-- floating button hidden); clicking it closes the window
	-- and reveals itself as the way back in.
	--========================================================
	function Window:CreateMinimizeBtn(cfg)
		cfg = cfg or {}

		local Floating = Create("Frame", {
			Name = "FloatingMinimize",
			Size = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(20, 20),
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = Theme.BackgroundTransparency,
			BorderSizePixel = 0,
			Visible = false,
			Parent = ScreenGui,
		}, { Corner(23), Stroke(Theme.Stroke, 1, 0.4) })

		local Btn = Create("ImageButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Parent = Floating,
		})

		local Ico = Create("ImageLabel", {
			Size = UDim2.fromOffset(22, 22),
			Position = UDim2.new(0.5, -11, 0.5, -11),
			BackgroundTransparency = 1,
			ImageColor3 = Theme.Text,
			Parent = Floating,
		})
		ResolveImage(Ico, cfg.Image)
		if not cfg.Image then
			-- default icon if none supplied, so the button is never blank
			ResolveImage(Ico, "layout-grid")
		end

		local TitleTip
		if cfg.Title then
			TitleTip = Create("TextLabel", {
				Name = "Tip",
				Size = UDim2.fromOffset(0, 26),
				AutomaticSize = Enum.AutomaticSize.X,
				Position = UDim2.new(1, 10, 0.5, -13),
				BackgroundColor3 = Theme.Background,
				BackgroundTransparency = 0.1,
				Font = Theme.Font,
				Text = "  " .. cfg.Title .. "  ",
				TextColor3 = Theme.Text,
				TextSize = 12,
				Visible = false,
				Parent = Floating,
			}, { Corner(6) })
		end

		MakeDraggable(Btn, Floating)

		local moved = false
		Btn.MouseButton1Down:Connect(function() moved = false end)
		Btn.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				moved = true
			end
		end)

		local function OpenWindow()
			local tw = Tween(Floating, QUICK, { Size = UDim2.fromOffset(0, 0) })
			tw.Completed:Connect(function()
				Floating.Visible = false
			end)
			Window._SetVisible(true)
		end

		local function CloseWindow()
			Window._SetVisible(false)
			Floating.Visible = true
			Floating.Size = UDim2.fromOffset(0, 0)
			Tween(Floating, BOUNCE, { Size = UDim2.fromOffset(46, 46) })
		end

		Btn.MouseButton1Click:Connect(function()
			if moved then return end -- don't toggle if it was a drag, not a click
			if Window._visible then
				CloseWindow()
			else
				OpenWindow()
			end
		end)

		Btn.MouseEnter:Connect(function()
			Tween(Floating, QUICK, { BackgroundTransparency = 0.05 })
			if TitleTip then TitleTip.Visible = true end
		end)
		Btn.MouseLeave:Connect(function()
			Tween(Floating, QUICK, { BackgroundTransparency = Theme.BackgroundTransparency })
			if TitleTip then TitleTip.Visible = false end
		end)

		-- Wire the window's own close/minimize control (top bar "–") to
		-- reuse this exact floating button instead of maintaining two
		-- separate toggle paths.
		Window._MinimizeFloating = Floating
		Window._MinimizeShow = CloseWindow
		Window._MinimizeHide = OpenWindow

		return {
			Instance = Floating,
			Show = function() Floating.Visible = true end,
			Hide = function() Floating.Visible = false end,
		}
	end

	--========================================================
	-- CreateTab
	--========================================================
	function Window:CreateTab(cfg)
		-- supports both {Title="Main", Icon="home"} and {"Main","home"} shorthand
		local title, iconName
		if typeof(cfg) == "table" then
			if cfg.Title or cfg.Icon then
				title = cfg.Title or "Tab"
				iconName = cfg.Icon
			else
				title = cfg[1] or "Tab"
				iconName = cfg[2]
			end
		else
			title = tostring(cfg)
		end

		local Tab = {}
		Tab.__index = Tab
		Tab.Name = title

		local isFirst = (#Window.Tabs == 0)

		----------------------------------------------------------------
		-- Tab button (left column)
		----------------------------------------------------------------
		local TabBtn = Create("TextButton", {
			Name = "Tab_" .. title,
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = isFirst and Theme.Accent or Theme.Element,
			BackgroundTransparency = isFirst and 0.15 or 0.3,
			AutoButtonColor = false,
			Text = "",
			Parent = Window._TabList,
		}, { Corner(8) })

		local TabIcon = Create("ImageLabel", {
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.fromOffset(10, 9),
			BackgroundTransparency = 1,
			ImageColor3 = Theme.Text,
			Parent = TabBtn,
		})
		ResolveImage(TabIcon, iconName)

		local TabLabel = Create("TextLabel", {
			Size = UDim2.new(1, -38, 1, 0),
			Position = UDim2.fromOffset(34, 0),
			BackgroundTransparency = 1,
			Font = Theme.Font,
			Text = title,
			TextColor3 = Theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = TabBtn,
		})

		----------------------------------------------------------------
		-- Tab page (right column content holder)
		----------------------------------------------------------------
		local Page = Create("Frame", {
			Name = "Page_" .. title,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = isFirst,
			LayoutOrder = #Window.Tabs + 1,
			Parent = Window._ElementList,
		})
		local PageLayout = Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = Page,
		})

		Tab._Page = Page
		Tab._PageLayout = PageLayout
		Tab._Elements = {}

		if isFirst then
			Window.CurrentTab = Tab
		end

		----------------------------------------------------------------
		-- Switching logic w/ animation
		----------------------------------------------------------------
		TabBtn.MouseButton1Click:Connect(function()
			if Window.CurrentTab == Tab then return end

			-- deactivate old
			if Window.CurrentTab then
				local oldBtn = Window.CurrentTab._Btn
				Tween(oldBtn, QUICK, { BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.3 })
				Window.CurrentTab._Page.Visible = false
			end

			-- activate new w/ icon bounce animation
			Tween(TabBtn, QUICK, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.15 })
			TabIcon.Size = UDim2.fromOffset(12, 12)
			TabIcon.Position = UDim2.fromOffset(13, 12)
			Tween(TabIcon, BOUNCE, { Size = UDim2.fromOffset(18,18), Position = UDim2.fromOffset(10,9) })

			Page.Visible = true
			Page.Position = UDim2.fromOffset(12, 0)
			Page.BackgroundTransparency = 1
			Tween(Page, SMOOTH, { Position = UDim2.fromOffset(0,0) })

			Window.CurrentTab = Tab
		end)

		TabBtn.MouseEnter:Connect(function()
			if Window.CurrentTab ~= Tab then
				Tween(TabBtn, QUICK, { BackgroundColor3 = Theme.ElementHover })
			end
		end)
		TabBtn.MouseLeave:Connect(function()
			if Window.CurrentTab ~= Tab then
				Tween(TabBtn, QUICK, { BackgroundColor3 = Theme.Element })
			end
		end)

		Tab._Btn = TabBtn
		table.insert(Window.Tabs, Tab)

		----------------------------------------------------------------
		-- Helper to register + tag elements for search
		----------------------------------------------------------------
		local function registerElement(frame, elTitle)
			frame:SetAttribute("ElementTitle", elTitle or "")
			frame.LayoutOrder = #Page:GetChildren()
			table.insert(Tab._Elements, frame)
		end

		--========================================================
		-- CreateButton
		--========================================================
		function Tab:CreateButton(bcfg)
			bcfg = bcfg or {}
			local Holder = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Theme.Element,
				BackgroundTransparency = 0.15,
				Parent = Page,
			}, { Corner(8), Stroke(Theme.Stroke, 1, 0.6) })

			local Btn = Create("TextButton", {
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				Parent = Holder,
			})

			Create("TextLabel", {
				Size = UDim2.new(1, -20, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				BackgroundTransparency = 1,
				Font = Theme.Font,
				Text = bcfg.Title or "Button",
				TextColor3 = bcfg.Locked and Theme.SubText or Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Holder,
			})

			if bcfg.Locked then
				local LockIcon = Create("ImageLabel", {
					Size = UDim2.fromOffset(14,14),
					Position = UDim2.new(1,-26,0.5,-7),
					BackgroundTransparency = 1,
					ImageColor3 = Theme.SubText,
					Parent = Holder,
				})
				ResolveImage(LockIcon, "lock")
			end

			Btn.MouseEnter:Connect(function()
				if not bcfg.Locked then Tween(Holder, QUICK, {BackgroundColor3 = Theme.ElementHover}) end
			end)
			Btn.MouseLeave:Connect(function()
				Tween(Holder, QUICK, {BackgroundColor3 = Theme.Element})
			end)

			Btn.MouseButton1Click:Connect(function()
				if bcfg.Locked then return end
				-- click bounce animation
				Tween(Holder, TweenInfo.new(0.08), { Size = UDim2.new(1,0,0,35) })
				task.delay(0.08, function()
					Tween(Holder, BOUNCE, { Size = UDim2.new(1,0,0,38) })
				end)
				if bcfg.Callback then
					local ok, err = pcall(bcfg.Callback)
					if not ok then warn("[BTUI] Button callback error: " .. tostring(err)) end
				end
			end)

			registerElement(Holder, bcfg.Title)
			return Holder
		end

		--========================================================
		-- CreateToggle
		--========================================================
		function Tab:CreateToggle(tcfg)
			tcfg = tcfg or {}
			local state = tcfg.Value or false

			local hasDesc = tcfg.Desc ~= nil and tcfg.Desc ~= ""
			local Holder = Create("Frame", {
				Size = UDim2.new(1, 0, 0, hasDesc and 50 or 38),
				BackgroundColor3 = Theme.Element,
				BackgroundTransparency = 0.15,
				Parent = Page,
			}, { Corner(8), Stroke(Theme.Stroke, 1, 0.6) })

			Create("TextLabel", {
				Size = UDim2.new(1, -70, 0, 20),
				Position = UDim2.fromOffset(12, hasDesc and 6 or 9),
				BackgroundTransparency = 1,
				Font = Theme.Font,
				Text = tcfg.Title or "Toggle",
				TextColor3 = Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Holder,
			})

			if hasDesc then
				Create("TextLabel", {
					Size = UDim2.new(1, -70, 0, 16),
					Position = UDim2.fromOffset(12, 26),
					BackgroundTransparency = 1,
					Font = Theme.Font,
					Text = tcfg.Desc,
					TextColor3 = Theme.SubText,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Holder,
				})
			end

			local SwitchBG = Create("Frame", {
				Size = UDim2.fromOffset(40, 22),
				Position = UDim2.new(1, -52, 0.5, -11),
				BackgroundColor3 = state and Theme.Accent or Theme.Panel,
				Parent = Holder,
			}, { Corner(11), Stroke(Theme.Stroke,1,0.5) })

			local Knob = Create("Frame", {
				Size = UDim2.fromOffset(16, 16),
				Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
				BackgroundColor3 = Color3.fromRGB(255,255,255),
				Parent = SwitchBG,
			}, { Corner(8) })

			local Click = Create("TextButton", {
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
				Text = "",
				Parent = Holder,
			})

			local function setState(newState, fireCallback)
				state = newState
				Tween(SwitchBG, QUICK, {BackgroundColor3 = state and Theme.Accent or Theme.Panel})
				Tween(Knob, BOUNCE, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
				if fireCallback and tcfg.Callback then
					local ok, err = pcall(tcfg.Callback, state)
					if not ok then warn("[BTUI] Toggle callback error: " .. tostring(err)) end
				end
			end

			Click.MouseButton1Click:Connect(function()
				setState(not state, true)
			end)

			registerElement(Holder, tcfg.Title)

			return {
				Instance = Holder,
				Set = function(_, v) setState(v, true) end,
				Get = function() return state end,
			}
		end

		--========================================================
		-- CreateSlider
		--========================================================
		function Tab:CreateSlider(scfg)
			scfg = scfg or {}
			local values = scfg.Value or {}
			local min = values.Min or 0
			local max = values.Max or 100
			local default = math.clamp(values.Default or min, min, max)
			local step = scfg.Step or 1
			local isFloat = (step % 1 ~= 0)

			local current = default

			local Holder = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 46),
				BackgroundColor3 = Theme.Element,
				BackgroundTransparency = 0.15,
				Parent = Page,
			}, { Corner(8), Stroke(Theme.Stroke, 1, 0.6) })

			Create("TextLabel", {
				Size = UDim2.new(1, -70, 0, 18),
				Position = UDim2.fromOffset(12, 6),
				BackgroundTransparency = 1,
				Font = Theme.Font,
				Text = scfg.Title or "Slider",
				TextColor3 = Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Holder,
			})

			local ValueLabel = Create("TextLabel", {
				Size = UDim2.fromOffset(50, 18),
				Position = UDim2.new(1, -62, 0, 6),
				BackgroundTransparency = 1,
				Font = Theme.FontBold,
				Text = tostring(current),
				TextColor3 = Theme.Accent,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = Holder,
			})

			local Track = Create("Frame", {
				Size = UDim2.new(1, -24, 0, 6),
				Position = UDim2.fromOffset(12, 30),
				BackgroundColor3 = Theme.Panel,
				Parent = Holder,
			}, { Corner(3) })

			local function pct(v) return (v - min) / (max - min) end

			local Fill = Create("Frame", {
				Size = UDim2.new(pct(current), 0, 1, 0),
				BackgroundColor3 = Theme.Accent,
				Parent = Track,
			}, { Corner(3) })

			local Knob = Create("Frame", {
				Size = UDim2.fromOffset(14,14),
				Position = UDim2.new(pct(current), -7, 0.5, -7),
				BackgroundColor3 = Color3.fromRGB(255,255,255),
				Parent = Track,
			}, { Corner(7), Stroke(Theme.Accent, 2, 0) })

			local dragging = false

			local function round(v)
				local n = min + math.floor(((v - min) / step) + 0.5) * step
				n = math.clamp(n, min, max)
				if isFloat then
					n = tonumber(string.format("%.2f", n))
				else
					n = math.floor(n + 0.5)
				end
				return n
			end

			local function update(inputPos, fireCallback)
				local relative = math.clamp((inputPos - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				local raw = min + relative * (max - min)
				current = round(raw)
				local p = pct(current)
				Fill.Size = UDim2.new(p, 0, 1, 0)
				Knob.Position = UDim2.new(p, -7, 0.5, -7)
				ValueLabel.Text = tostring(current)
				if fireCallback and scfg.Callback then
					local ok, err = pcall(scfg.Callback, current)
					if not ok then warn("[BTUI] Slider callback error: " .. tostring(err)) end
				end
			end

			local function beginDrag(input)
				dragging = true
				update(input.Position.X, true)
			end

			Track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					beginDrag(input)
				end
			end)
			Knob.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					beginDrag(input)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					update(input.Position.X, true)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			registerElement(Holder, scfg.Title)

			return {
				Instance = Holder,
				Set = function(_, v)
					current = round(v)
					local p = pct(current)
					Tween(Fill, QUICK, {Size = UDim2.new(p,0,1,0)})
					Tween(Knob, QUICK, {Position = UDim2.new(p,-7,0.5,-7)})
					ValueLabel.Text = tostring(current)
				end,
				Get = function() return current end,
			}
		end

		--========================================================
		-- CreateInput
		--========================================================
		function Tab:CreateInput(icfg)
			icfg = icfg or {}
			local Holder = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Theme.Element,
				BackgroundTransparency = 0.15,
				Parent = Page,
			}, { Corner(8), Stroke(Theme.Stroke, 1, 0.6) })

			Create("TextLabel", {
				Size = UDim2.new(0, 110, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				BackgroundTransparency = 1,
				Font = Theme.Font,
				Text = icfg.Title or "Input",
				TextColor3 = Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Holder,
			})

			local Box = Create("TextBox", {
				Size = UDim2.new(1, -134, 0, 26),
				Position = UDim2.new(1, -12-190, 0.5, -13),
				BackgroundColor3 = Theme.Panel,
				Text = icfg.Value or "",
				PlaceholderText = icfg.Placeholder or "Enter text...",
				PlaceholderColor3 = Theme.SubText,
				Font = Theme.Font,
				TextColor3 = Theme.Text,
				TextSize = 13,
				ClearTextOnFocus = false,
				Parent = Holder,
			}, { Corner(6), Padding(0,8,0,8) })
			Box.Size = UDim2.new(1, -134, 0, 26)
			Box.AnchorPoint = Vector2.new(1, 0.5)
			Box.Position = UDim2.new(1, -12, 0.5, 0)

			Box.FocusLost:Connect(function(enterPressed)
				if icfg.Callback then
					local ok, err = pcall(icfg.Callback, Box.Text)
					if not ok then warn("[BTUI] Input callback error: " .. tostring(err)) end
				end
			end)

			registerElement(Holder, icfg.Title)

			return {
				Instance = Holder,
				Set = function(_, v) Box.Text = v end,
				Get = function() return Box.Text end,
			}
		end

		--========================================================
		-- CreateDropdown
		--========================================================
		function Tab:CreateDropdown(dcfg)
			dcfg = dcfg or {}
			local values = dcfg.Values or {}
			local current = dcfg.Value

			local Holder = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Theme.Element,
				BackgroundTransparency = 0.15,
				ZIndex = 2,
				Parent = Page,
			}, { Corner(8), Stroke(Theme.Stroke, 1, 0.6) })

			Create("TextLabel", {
				Size = UDim2.new(1, -160, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				BackgroundTransparency = 1,
				Font = Theme.Font,
				Text = dcfg.Title or "Dropdown",
				TextColor3 = Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Holder,
			})

			local SelectedBtn = Create("TextButton", {
				Size = UDim2.fromOffset(140, 26),
				Position = UDim2.new(1, -152, 0.5, -13),
				BackgroundColor3 = Theme.Panel,
				AutoButtonColor = false,
				Text = "",
				Parent = Holder,
			}, { Corner(6) })

			local SelectedLabel = Create("TextLabel", {
				Size = UDim2.new(1, -26, 1, 0),
				Position = UDim2.fromOffset(10, 0),
				BackgroundTransparency = 1,
				Font = Theme.Font,
				Text = current and tostring(current) or "Select...",
				TextColor3 = current and Theme.Text or Theme.SubText,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = SelectedBtn,
			})

			local ChevIcon = Create("ImageLabel", {
				Size = UDim2.fromOffset(14,14),
				Position = UDim2.new(1, -22, 0.5, -7),
				BackgroundTransparency = 1,
				ImageColor3 = Theme.SubText,
				Parent = SelectedBtn,
			})
			ResolveImage(ChevIcon, "chevron-down")

			----------------------------------------------------------------
			-- Popup: centered square, scroll + search + close
			----------------------------------------------------------------
			local Overlay = Create("Frame", {
				Name = "DropdownOverlay",
				Size = UDim2.new(1,0,1,0),
				BackgroundColor3 = Color3.fromRGB(0,0,0),
				BackgroundTransparency = 1,
				Visible = false,
				ZIndex = 50,
				Parent = Window._Main,
			})

			local POPUP_W, POPUP_H = 260, 220
			local Popup = Create("Frame", {
				Name = "DropdownPopup",
				Size = UDim2.fromOffset(0, 0),
				Position = UDim2.new(0.5, -POPUP_W/2, 0.5, -POPUP_H/2),
				BackgroundColor3 = Theme.Panel,
				BackgroundTransparency = 0.05,
				ZIndex = 51,
				Parent = Overlay,
			}, { Corner(10), Stroke(Theme.Accent, 1, 0.3) })

			local PTop = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				ZIndex = 52,
				Parent = Popup,
			})
			Create("TextLabel", {
				Size = UDim2.new(1, -40, 1, 0),
				Position = UDim2.fromOffset(10, 0),
				BackgroundTransparency = 1,
				Font = Theme.FontBold,
				Text = dcfg.Title or "Select",
				TextColor3 = Theme.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 52,
				Parent = PTop,
			})
			local PClose = Create("ImageButton", {
				Size = UDim2.fromOffset(22,22),
				Position = UDim2.new(1, -30, 0.5, -11),
				BackgroundColor3 = Theme.Element,
				AutoButtonColor = false,
				ZIndex = 52,
				Parent = PTop,
			}, { Corner(6) })
			local PCloseIcon = Create("ImageLabel", {
				Size = UDim2.fromOffset(12,12),
				Position = UDim2.new(0.5,-6,0.5,-6),
				BackgroundTransparency = 1,
				ImageColor3 = Theme.Text,
				ZIndex = 53,
				Parent = PClose,
			})
			ResolveImage(PCloseIcon, "x")

			local PSearchHolder = Create("Frame", {
				Size = UDim2.new(1, -20, 0, 28),
				Position = UDim2.fromOffset(10, 36),
				BackgroundColor3 = Theme.Element,
				ZIndex = 52,
				Parent = Popup,
			}, { Corner(6) })
			local PSearchIcon = Create("ImageLabel", {
				Size = UDim2.fromOffset(13,13),
				Position = UDim2.fromOffset(8,7),
				BackgroundTransparency = 1,
				ImageColor3 = Theme.SubText,
				ZIndex = 53,
				Parent = PSearchHolder,
			})
			ResolveImage(PSearchIcon, "search")
			local PSearchBox = Create("TextBox", {
				Size = UDim2.new(1, -34, 1, 0),
				Position = UDim2.fromOffset(28, 0),
				BackgroundTransparency = 1,
				Font = Theme.Font,
				PlaceholderText = "Search...",
				PlaceholderColor3 = Theme.SubText,
				Text = "",
				TextColor3 = Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				ZIndex = 53,
				Parent = PSearchHolder,
			})

			local OptionList = Create("ScrollingFrame", {
				Size = UDim2.new(1, -20, 1, -76),
				Position = UDim2.fromOffset(10, 70),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 4,
				ScrollBarImageColor3 = Theme.Accent,
				CanvasSize = UDim2.new(0,0,0,0),
				ZIndex = 52,
				Parent = Popup,
			})
			local OptionLayout = Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				Parent = OptionList,
			})
			AutoScroll(OptionList, OptionLayout, "Y")

			local optionButtons = {}

			local dropdownAPI = {}

			local function closePopup()
				local tw = Tween(Popup, QUICK, { Size = UDim2.fromOffset(0,0) })
				Tween(Overlay, QUICK, { BackgroundTransparency = 1 })
				tw.Completed:Connect(function()
					Overlay.Visible = false
				end)
				ChevIcon.Rotation = 0
			end

			local function selectValue(v, fireCallback)
				current = v
				SelectedLabel.Text = tostring(v)
				SelectedLabel.TextColor3 = Theme.Text
				for _, b in ipairs(optionButtons) do
					local isSel = b:GetAttribute("Val") == tostring(v)
					Tween(b, QUICK, { BackgroundColor3 = isSel and Theme.Accent or Theme.Element })
				end
				if fireCallback and dcfg.Callback then
					local ok, err = pcall(dcfg.Callback, v)
					if not ok then warn("[BTUI] Dropdown callback error: " .. tostring(err)) end
				end
			end

			local function buildOptions(list)
				for _, b in ipairs(optionButtons) do b:Destroy() end
				table.clear(optionButtons)

				for i, v in ipairs(list) do
					local OptBtn = Create("TextButton", {
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = (tostring(v) == tostring(current)) and Theme.Accent or Theme.Element,
						AutoButtonColor = false,
						Text = "",
						ZIndex = 53,
						LayoutOrder = i,
						Parent = OptionList,
					}, { Corner(6) })
					OptBtn:SetAttribute("Val", tostring(v))

					Create("TextLabel", {
						Size = UDim2.new(1, -16, 1, 0),
						Position = UDim2.fromOffset(10, 0),
						BackgroundTransparency = 1,
						Font = Theme.Font,
						Text = tostring(v),
						TextColor3 = Theme.Text,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 54,
						Parent = OptBtn,
					})

					OptBtn.MouseEnter:Connect(function()
						if tostring(v) ~= tostring(current) then
							Tween(OptBtn, QUICK, {BackgroundColor3 = Theme.ElementHover})
						end
					end)
					OptBtn.MouseLeave:Connect(function()
						if tostring(v) ~= tostring(current) then
							Tween(OptBtn, QUICK, {BackgroundColor3 = Theme.Element})
						end
					end)

					OptBtn.MouseButton1Click:Connect(function()
						selectValue(v, true)
						closePopup()
					end)

					table.insert(optionButtons, OptBtn)
				end
			end

			buildOptions(values)

			PSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
				local q = PSearchBox.Text:lower()
				for _, b in ipairs(optionButtons) do
					local val = (b:GetAttribute("Val") or ""):lower()
					b.Visible = (q == "" or val:find(q, 1, true) ~= nil)
				end
			end)

			local function openPopup()
				PSearchBox.Text = ""
				for _, b in ipairs(optionButtons) do b.Visible = true end
				Overlay.Visible = true
				Overlay.BackgroundTransparency = 1
				Popup.Size = UDim2.fromOffset(0,0)
				Tween(Overlay, QUICK, { BackgroundTransparency = 0.5 })
				Tween(Popup, BOUNCE, { Size = UDim2.fromOffset(POPUP_W, POPUP_H) })
				ChevIcon.Rotation = 180
			end

			SelectedBtn.MouseButton1Click:Connect(function()
				if Overlay.Visible then
					closePopup()
				else
					openPopup()
				end
			end)

			SelectedBtn.MouseEnter:Connect(function() Tween(SelectedBtn, QUICK, {BackgroundColor3 = Theme.ElementHover}) end)
			SelectedBtn.MouseLeave:Connect(function() Tween(SelectedBtn, QUICK, {BackgroundColor3 = Theme.Panel}) end)

			PClose.MouseButton1Click:Connect(closePopup)
			PClose.MouseEnter:Connect(function() Tween(PClose, QUICK, {BackgroundColor3 = Color3.fromRGB(200,60,60)}) end)
			PClose.MouseLeave:Connect(function() Tween(PClose, QUICK, {BackgroundColor3 = Theme.Element}) end)

			Overlay.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					-- click outside popup closes it
					local mousePos = UserInputService:GetMouseLocation()
					local pp = Popup.AbsolutePosition
					local ps = Popup.AbsoluteSize
					if mousePos.X < pp.X or mousePos.X > pp.X+ps.X or mousePos.Y < pp.Y or mousePos.Y > pp.Y+ps.Y then
						closePopup()
					end
				end
			end)

			registerElement(Holder, dcfg.Title)

			dropdownAPI.Instance = Holder
			dropdownAPI.Set = function(_, v) selectValue(v, true) end
			dropdownAPI.Get = function() return current end
			dropdownAPI.Refresh = function(_, newValues)
				values = newValues or {}
				buildOptions(values)
			end

			return dropdownAPI
		end

		return Tab
	end

	return Window
end

return BTUI
