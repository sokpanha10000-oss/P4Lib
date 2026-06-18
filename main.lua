--// SKUI Nexus Green Hub Library
--// Paste this as a ModuleScript or loadstring script

local SKUI = {}
SKUI.__index = SKUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local function create(className, props)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	return obj
end

local function round(obj, radius)
	create("UICorner", {
		CornerRadius = radius or UDim.new(0, 10),
		Parent = obj
	})
end

local function stroke(obj, color, thickness, transparency)
	create("UIStroke", {
		Color = color or Color3.fromRGB(70, 170, 95),
		Thickness = thickness or 1,
		Transparency = transparency or 0.25,
		Parent = obj
	})
end

local function pad(obj, l, r, t, b)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or 0),
		Parent = obj
	})
end

local function tween(obj, info, goal)
	return TweenService:Create(obj, info, goal)
end

local function getGuiParent()
	if syn and syn.protect_gui then
		return CoreGui
	end
	return (gethui and gethui()) or CoreGui
end

-- Optional icon provider hook
SKUI.IconModule = nil
function SKUI:SetIconModule(module)
	SKUI.IconModule = module
end

local function resolveIcon(icon)
	if icon == nil then
		return nil, nil
	end

	if type(icon) == "number" then
		return "rbxassetid://" .. tostring(icon), nil
	end

	if type(icon) == "string" then
		if icon:match("^rbxassetid://") then
			return icon, nil
		end

		-- Try your icon module first
		local provider = SKUI.IconModule or rawget(_G, "IconModule")
		if provider then
			local ok, result = pcall(function()
				if provider.Icon2 then
					return provider.Icon2(icon)
				elseif provider.Icon then
					return provider.Icon(icon)
				end
				return nil
			end)

			if ok and result then
				if type(result) == "string" then
					return result, nil
				elseif type(result) == "table" then
					local image = result[1]
					local data = result[2]
					return image, data
				end
			end
		end
	end

	return nil, nil
end

local function makeIcon(parent, icon, size, tint)
	local image, data = resolveIcon(icon)
	if not image then
		return nil
	end

	local img = create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Image = image,
		ImageColor3 = tint or Color3.new(1, 1, 1),
		Size = size or UDim2.fromOffset(18, 18),
		Parent = parent
	})

	if data and data.ImageRectSize then
		img.ImageRectSize = data.ImageRectSize
	end
	if data and data.ImageRectPosition then
		img.ImageRectOffset = data.ImageRectPosition
	end

	return img
end

function SKUI:CreateWindow(config)
	config = config or {}

	local Title = config.Title or "SKUI"
	local Subtitle = config.Subtitle or ""
	local Image = config.Image
	local SearchBar = config.SearchBar ~= false

	local screen = create("ScreenGui", {
		Name = "SKUI_Nexus",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = getGuiParent()
	})

	local main = create("Frame", {
		Name = "Window",
		Size = UDim2.fromOffset(550, 340),
		Position = UDim2.new(0.5, -275, 0.5, -170),
		BackgroundColor3 = Color3.fromRGB(10, 24, 16),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Active = true,
		Parent = screen
	})
	round(main, UDim.new(0, 14))
	stroke(main, Color3.fromRGB(40, 190, 90), 1, 0.55)

	local top = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Color3.fromRGB(11, 36, 22),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		Parent = main
	})
	round(top, UDim.new(0, 14))

	local topCover = create("Frame", {
		Name = "TopCover",
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 1, -18),
		BackgroundColor3 = top.BackgroundColor3,
		BackgroundTransparency = top.BackgroundTransparency,
		BorderSizePixel = 0,
		Parent = top
	})

	local iconHolder = create("Frame", {
		Name = "LogoHolder",
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.fromOffset(14, 10),
		BackgroundColor3 = Color3.fromRGB(18, 55, 33),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Parent = top
	})
	round(iconHolder, UDim.new(0, 8))
	stroke(iconHolder, Color3.fromRGB(60, 220, 120), 1, 0.7)
	if Image then
		makeIcon(iconHolder, Image, UDim2.fromOffset(18, 18), Color3.fromRGB(115, 255, 170))
		local img = iconHolder:FindFirstChild("Icon")
		if img then
			img.Position = UDim2.new(0.5, -9, 0.5, -9)
		end
	end

	local titleLabel = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(48, 7),
		Size = UDim2.new(1, -180, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = Color3.fromRGB(210, 255, 225),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top
	})

	local subtitleLabel = create("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(48, 23),
		Size = UDim2.new(1, -180, 0, 16),
		Font = Enum.Font.Gotham,
		Text = Subtitle,
		TextColor3 = Color3.fromRGB(130, 175, 145),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top
	})

	local closeBtn = create("TextButton", {
		Name = "CloseButton",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -40, 0, 8),
		BackgroundColor3 = Color3.fromRGB(55, 15, 15),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = top
	})
	round(closeBtn, UDim.new(0, 8))
	stroke(closeBtn, Color3.fromRGB(255, 90, 90), 1, 0.65)
	makeIcon(closeBtn, "x", UDim2.fromOffset(16, 16), Color3.fromRGB(255, 145, 145))
	local closeIcon = closeBtn:FindFirstChild("Icon")
	if closeIcon then
		closeIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
	end

	local searchBox
	if SearchBar then
		searchBox = create("TextBox", {
			Name = "SearchBar",
			PlaceholderText = "Search...",
			Text = "",
			ClearTextOnFocus = false,
			Size = UDim2.new(0, 160, 0, 28),
			Position = UDim2.new(1, -220, 0, 9),
			BackgroundColor3 = Color3.fromRGB(14, 42, 26),
			BackgroundTransparency = 0.10,
			BorderSizePixel = 0,
			Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(230, 255, 238),
			PlaceholderColor3 = Color3.fromRGB(110, 150, 120),
			TextSize = 12,
			Parent = top
		})
		round(searchBox, UDim.new(0, 8))
		stroke(searchBox, Color3.fromRGB(55, 190, 100), 1, 0.80)
		makeIcon(searchBox, "search", UDim2.fromOffset(14, 14), Color3.fromRGB(135, 255, 180))
		local sIcon = searchBox:FindFirstChild("Icon")
		if sIcon then
			sIcon.Position = UDim2.new(0, 8, 0.5, -7)
		end
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			if self._activeTab then
				self:_applySearch(searchBox.Text)
			end
		end)
	end

	local body = create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -46),
		Position = UDim2.new(0, 0, 0, 46),
		BackgroundTransparency = 1,
		Parent = main
	})

	local tabPanel = create("ScrollingFrame", {
		Name = "Tabs",
		Size = UDim2.new(0, 150, 1, 0),
		BackgroundColor3 = Color3.fromRGB(9, 24, 16),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Color3.fromRGB(70, 210, 110),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = body
	})
	round(tabPanel, UDim.new(0, 12))
	stroke(tabPanel, Color3.fromRGB(40, 160, 80), 1, 0.82)
	pad(tabPanel, 10, 10, 10, 10)

	local tabList = create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabPanel
	})

	local rightPanel = create("Frame", {
		Name = "ElementsPanel",
		Size = UDim2.new(1, -160, 1, 0),
		Position = UDim2.new(0, 160, 0, 0),
		BackgroundColor3 = Color3.fromRGB(7, 19, 13),
		BackgroundTransparency = 0.24,
		BorderSizePixel = 0,
		Parent = body
	})
	round(rightPanel, UDim.new(0, 12))
	stroke(rightPanel, Color3.fromRGB(36, 145, 78), 1, 0.88)

	local elementScroll = create("ScrollingFrame", {
		Name = "ElementScroll",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Color3.fromRGB(60, 200, 100),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = rightPanel
	})
	pad(elementScroll, 12, 12, 12, 12)

	local elementList = create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = elementScroll
	})

	local overlay = create("Frame", {
		Name = "PopupOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 40,
		Parent = main
	})

	local popup = create("Frame", {
		Name = "Popup",
		Size = UDim2.fromOffset(310, 250),
		Position = UDim2.new(0.5, -155, 0.5, -125),
		BackgroundColor3 = Color3.fromRGB(10, 29, 18),
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ZIndex = 41,
		Visible = false,
		Parent = overlay
	})
	round(popup, UDim.new(0, 12))
	stroke(popup, Color3.fromRGB(60, 220, 120), 1, 0.65)

	local popupTop = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.fromOffset(12, 10),
		Font = Enum.Font.GothamBold,
		Text = "Dropdown",
		TextColor3 = Color3.fromRGB(225, 255, 235),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 42,
		Parent = popup
	})

	local popupSearch = create("TextBox", {
		Name = "Search",
		PlaceholderText = "Search options...",
		Text = "",
		ClearTextOnFocus = false,
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.fromOffset(12, 35),
		BackgroundColor3 = Color3.fromRGB(16, 45, 28),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(235, 255, 240),
		PlaceholderColor3 = Color3.fromRGB(110, 150, 120),
		ZIndex = 42,
		Parent = popup
	})
	round(popupSearch, UDim.new(0, 8))
	stroke(popupSearch, Color3.fromRGB(75, 200, 110), 1, 0.85)

	local popupScroll = create("ScrollingFrame", {
		Name = "Options",
		Size = UDim2.new(1, -24, 1, -78),
		Position = UDim2.fromOffset(12, 70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Color3.fromRGB(60, 200, 100),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 42,
		Parent = popup
	})
	local popupList = create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = popupScroll
	})

	local popupClose = create("TextButton", {
		Name = "Close",
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -34, 0, 8),
		BackgroundColor3 = Color3.fromRGB(50, 15, 15),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		Text = "",
		ZIndex = 43,
		Parent = popup
	})
	round(popupClose, UDim.new(0, 8))
	stroke(popupClose, Color3.fromRGB(255, 90, 90), 1, 0.7)
	makeIcon(popupClose, "x", UDim2.fromOffset(14, 14), Color3.fromRGB(255, 145, 145))
	local popupCloseIcon = popupClose:FindFirstChild("Icon")
	if popupCloseIcon then
		popupCloseIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
		popupCloseIcon.ZIndex = 44
	end

	local floatingBtn

	local window = {
		ScreenGui = screen,
		Main = main,
		TopBar = top,
		Body = body,
		TabPanel = tabPanel,
		ElementPanel = rightPanel,
		Popup = popup,
		PopupOverlay = overlay,
		ActiveTabs = {},
		_activeTab = nil,
		_popupTarget = nil,
		_minimized = false,
		Dragging = false,
	}

	function window:_applySearch(query)
		query = string.lower(query or "")
		local tab = self._activeTab
		if not tab then return end

		for _, item in ipairs(tab._items or {}) do
			if item.SearchText then
				local visible = query == "" or string.find(string.lower(item.SearchText), query, 1, true)
				item.Root.Visible = visible
			end
		end
	end

	local function showTab(tab)
		for _, t in ipairs(window.ActiveTabs) do
			t.Container.Visible = false
			t.Button.BackgroundColor3 = Color3.fromRGB(16, 42, 26)
		end
		tab.Container.Visible = true
		tab.Button.BackgroundColor3 = Color3.fromRGB(30, 100, 58)
		window._activeTab = tab
		if searchBox then
			window:_applySearch(searchBox.Text)
		end
	end

	-- Dragging
	do
		local dragStart, startPos, dragInput

		local function update(input)
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end

		top.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = main.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		top.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragStart and main.Visible then
				update(input)
			end
		end)
	end

	closeBtn.MouseButton1Click:Connect(function()
		screen:Destroy()
		if floatingBtn then
			floatingBtn:Destroy()
		end
	end)

	popupClose.MouseButton1Click:Connect(function()
		overlay.Visible = false
		popup.Visible = false
	end)

	function window:CreateMinimizeBtn(config)
		config = config or {}
		local Title = config.Title or "Open UI"
		local Img = config.Image
		local Shape = config.Shape or "Square"

		local gui = create("ScreenGui", {
			Name = "SKUI_Minimize",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
			Parent = getGuiParent()
		})

		local btn = create("TextButton", {
			Name = "MinimizeBtn",
			Size = UDim2.fromOffset(120, 36),
			Position = UDim2.new(0, 16, 0.5, -18),
			BackgroundColor3 = Color3.fromRGB(12, 34, 20),
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = gui
		})

		if Shape == "Circle" then
			round(btn, UDim.new(1, 0))
		else
			round(btn, UDim.new(0, 8))
		end
		stroke(btn, Color3.fromRGB(65, 220, 115), 1, 0.72)

		if Img then
			makeIcon(btn, Img, UDim2.fromOffset(18, 18), Color3.fromRGB(130, 255, 180))
			local ic = btn:FindFirstChild("Icon")
			if ic then
				ic.Position = UDim2.fromOffset(12, 9)
			end
		end

		local txt = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Img and 38 or 14, 0, 0),
			Size = UDim2.new(1, -(Img and 48 or 18), 1, 0),
			Font = Enum.Font.GothamBold,
			Text = Title,
			TextColor3 = Color3.fromRGB(225, 255, 235),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn
		})

		btn.MouseButton1Click:Connect(function()
			main.Visible = not main.Visible
		end)

		floatingBtn = gui
		return btn
	end

	function window:CreateTab(tabData)
		local tabTitle = tabData[1] or "Tab"
		local tabIcon = tabData[2]

		local tabBtn = create("TextButton", {
			Name = tabTitle .. "_Tab",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Color3.fromRGB(16, 42, 26),
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = tabPanel
		})
		round(tabBtn, UDim.new(0, 10))
		stroke(tabBtn, Color3.fromRGB(50, 180, 95), 1, 0.85)

		if tabIcon then
			makeIcon(tabBtn, tabIcon, UDim2.fromOffset(16, 16), Color3.fromRGB(130, 255, 180))
			local ti = tabBtn:FindFirstChild("Icon")
			if ti then
				ti.Position = UDim2.fromOffset(10, 9)
			end
		end

		local tabText = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, tabIcon and 34 or 12, 0, 0),
			Size = UDim2.new(1, -(tabIcon and 40 or 14), 1, 0),
			Font = Enum.Font.GothamSemibold,
			Text = tabTitle,
			TextColor3 = Color3.fromRGB(225, 255, 235),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = tabBtn
		})

		local container = create("ScrollingFrame", {
			Name = tabTitle .. "_Container",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Color3.fromRGB(60, 200, 100),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			Parent = elementScroll
		})

		local list = create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = container
		})

		local tab = {
			Title = tabTitle,
			Icon = tabIcon,
			Button = tabBtn,
			Container = container,
			_items = {},
		}

		local function addItem(root, searchText)
			table.insert(tab._items, {
				Root = root,
				SearchText = searchText or ""
			})
		end

		function tab:CreateButton(data)
			data = data or {}
			local root = create("TextButton", {
				Name = "ButtonElement",
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = Color3.fromRGB(13, 34, 21),
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = container
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(50, 170, 90), 1, 0.9)

			local title = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -24, 1, 0),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Button",
				TextColor3 = Color3.fromRGB(235, 255, 240),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root
			})

			if data.Locked then
				title.TextTransparency = 0.25
			end

			root.MouseButton1Click:Connect(function()
				if data.Locked then return end
				if data.Callback then
					task.spawn(data.Callback)
				end
			end)

			addItem(root, data.Title or "Button")
			return root
		end

		function tab:CreateToggle(data)
			data = data or {}
			local state = data.Value == true

			local root = create("Frame", {
				Name = "ToggleElement",
				Size = UDim2.new(1, 0, 0, 42),
				BackgroundColor3 = Color3.fromRGB(13, 34, 21),
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				Parent = container
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(50, 170, 90), 1, 0.9)

			local title = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 4),
				Size = UDim2.new(1, -70, 0, 18),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Toggle",
				TextColor3 = Color3.fromRGB(235, 255, 240),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root
			})

			local desc = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 20),
				Size = UDim2.new(1, -70, 0, 14),
				Font = Enum.Font.Gotham,
				Text = data.Desc or "",
				TextColor3 = Color3.fromRGB(130, 170, 140),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root
			})

			local switch = create("TextButton", {
				Size = UDim2.fromOffset(42, 22),
				Position = UDim2.new(1, -54, 0.5, -11),
				BackgroundColor3 = state and Color3.fromRGB(45, 170, 90) or Color3.fromRGB(35, 55, 42),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = root
			})
			round(switch, UDim.new(1, 0))

			local knob = create("Frame", {
				Size = UDim2.fromOffset(18, 18),
				Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
				BackgroundColor3 = Color3.fromRGB(235, 255, 240),
				BorderSizePixel = 0,
				Parent = switch
			})
			round(knob, UDim.new(1, 0))

			local function setState(v)
				state = v
				tween(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = state and Color3.fromRGB(45, 170, 90) or Color3.fromRGB(35, 55, 42)
				}):Play()
				tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
				}):Play()
				if data.Callback then
					task.spawn(data.Callback, state)
				end
			end

			switch.MouseButton1Click:Connect(function()
				setState(not state)
			end)

			addItem(root, (data.Title or "Toggle") .. " " .. (data.Desc or ""))
			return {
				Set = setState,
				Get = function()
					return state
				end
			}
		end

		function tab:CreateInput(data)
			data = data or {}

			local root = create("Frame", {
				Name = "InputElement",
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = Color3.fromRGB(13, 34, 21),
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				Parent = container
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(50, 170, 90), 1, 0.9)

			local title = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 4),
				Size = UDim2.new(1, -24, 0, 16),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Input",
				TextColor3 = Color3.fromRGB(235, 255, 240),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root
			})

			local box = create("TextBox", {
				PlaceholderText = data.Placeholder or "Enter text...",
				Text = data.Value or "",
				ClearTextOnFocus = false,
				Size = UDim2.new(1, -24, 0, 24),
				Position = UDim2.fromOffset(12, 24),
				BackgroundColor3 = Color3.fromRGB(16, 45, 28),
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(240, 255, 242),
				PlaceholderColor3 = Color3.fromRGB(110, 150, 120),
				TextSize = 12,
				Parent = root
			})
			round(box, UDim.new(0, 8))
			stroke(box, Color3.fromRGB(60, 190, 110), 1, 0.88)

			box.FocusLost:Connect(function()
				if data.Callback then
					task.spawn(data.Callback, box.Text)
				end
			end)

			addItem(root, data.Title or "Input")
			return box
		end

		function tab:CreateSlider(data)
			data = data or {}
			local min = (data.Value and data.Value.Min) or 0
			local max = (data.Value and data.Value.Max) or 100
			local value = (data.Value and data.Value.Default) or min

			local root = create("Frame", {
				Name = "SliderElement",
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = Color3.fromRGB(13, 34, 21),
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				Parent = container
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(50, 170, 90), 1, 0.9)

			local title = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 4),
				Size = UDim2.new(1, -70, 0, 16),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Slider",
				TextColor3 = Color3.fromRGB(235, 255, 240),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root
			})

			local valLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -50, 0, 4),
				Size = UDim2.fromOffset(40, 16),
				Font = Enum.Font.Gotham,
				Text = tostring(value),
				TextColor3 = Color3.fromRGB(140, 255, 175),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = root
			})

			local track = create("Frame", {
				Size = UDim2.new(1, -24, 0, 8),
				Position = UDim2.fromOffset(12, 32),
				BackgroundColor3 = Color3.fromRGB(25, 55, 36),
				BorderSizePixel = 0,
				Parent = root
			})
			round(track, UDim.new(1, 0))

			local fill = create("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(55, 200, 105),
				BorderSizePixel = 0,
				Parent = track
			})
			round(fill, UDim.new(1, 0))

			local knob = create("Frame", {
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = Color3.fromRGB(235, 255, 240),
				BorderSizePixel = 0,
				Parent = track
			})
			round(knob, UDim.new(1, 0))

			local dragging = false

			local function setValue(v)
				v = math.clamp(v, min, max)
				value = v
				local alpha = (value - min) / math.max((max - min), 1)
				fill.Size = UDim2.new(alpha, 0, 1, 0)
				knob.Position = UDim2.new(alpha, -7, 0.5, -7)
				valLabel.Text = tostring(math.floor((value * 1000) + 0.5) / 1000)
				if data.Callback then
					task.spawn(data.Callback, value)
				end
			end

			local function updateFromX(x)
				local px = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				setValue(min + ((max - min) * px))
			end

			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateFromX(input.Position.X)
				end
			end)

			track.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromX(input.Position.X)
				end
			end)

			setValue(value)
			addItem(root, data.Title or "Slider")
			return {
				Set = setValue,
				Get = function()
					return value
				end
			}
		end

		function tab:CreateDropdown(data)
			data = data or {}
			local values = data.Values or {}
			local selected = data.Value or values[1] or "None"

			local root = create("TextButton", {
				Name = "DropdownElement",
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Color3.fromRGB(13, 34, 21),
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = container
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(50, 170, 90), 1, 0.9)

			local title = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -44, 1, 0),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Dropdown",
				TextColor3 = Color3.fromRGB(235, 255, 240),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root
			})

			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -140, 0, 0),
				Size = UDim2.fromOffset(110, 36),
				Font = Enum.Font.Gotham,
				Text = tostring(selected),
				TextColor3 = Color3.fromRGB(145, 255, 185),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = root
			})

			local arrow = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(20, 20),
				Position = UDim2.new(1, -24, 0.5, -10),
				Font = Enum.Font.GothamBold,
				Text = "▾",
				TextColor3 = Color3.fromRGB(145, 255, 185),
				TextSize = 16,
				Parent = root
			})

			local dropdown = {}

			local function refreshList(filterText)
				filterText = string.lower(filterText or "")
				for _, c in ipairs(popupScroll:GetChildren()) do
					if c:IsA("TextButton") then
						c:Destroy()
					end
				end

				for _, v in ipairs(values) do
					local str = tostring(v)
					if filterText == "" or string.find(string.lower(str), filterText, 1, true) then
						local opt = create("TextButton", {
							Size = UDim2.new(1, 0, 0, 30),
							BackgroundColor3 = Color3.fromRGB(14, 39, 24),
							BackgroundTransparency = 0.10,
							BorderSizePixel = 0,
							Text = str,
							Font = Enum.Font.Gotham,
							TextSize = 12,
							TextColor3 = Color3.fromRGB(235, 255, 240),
							AutoButtonColor = false,
							ZIndex = 42,
							Parent = popupScroll
						})
						round(opt, UDim.new(0, 8))
						stroke(opt, Color3.fromRGB(50, 170, 90), 1, 0.9)

						opt.MouseButton1Click:Connect(function()
							selected = str
							valueLabel.Text = str
							popup.Visible = false
							overlay.Visible = false
							if data.Callback then
								task.spawn(data.Callback, selected)
							end
						end)
					end
				end
			end

			local function openDropdown()
				overlay.Visible = true
				popup.Visible = true
				popupSearch.Text = ""
				refreshList("")
				popupSearch:CaptureFocus()
			end

			root.MouseButton1Click:Connect(openDropdown)
			arrow.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					openDropdown()
				end
			end)

			popupSearch:GetPropertyChangedSignal("Text"):Connect(function()
				if popup.Visible then
					refreshList(popupSearch.Text)
				end
			end)

			function dropdown:Refresh(newValues)
				values = newValues or {}
				if popup.Visible then
					refreshList(popupSearch.Text)
				end
			end

			function dropdown:SetValue(v)
				selected = tostring(v)
				valueLabel.Text = selected
				if data.Callback then
					task.spawn(data.Callback, selected)
				end
			end

			function dropdown:GetValue()
				return selected
			end

			root.MouseButton1Click:Connect(function()
				-- required for your usage
			end)

			addItem(root, data.Title or "Dropdown")
			return setmetatable(dropdown, { __index = dropdown })
		end

		table.insert(window.ActiveTabs, tab)
		if #window.ActiveTabs == 1 then
			showTab(tab)
		end

		tabBtn.MouseButton1Click:Connect(function()
			showTab(tab)
		end)

		return tab
	end

	return setmetatable(window, { __index = self })
end

return SKUI
