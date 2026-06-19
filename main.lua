--// SKUI Clean White Hub + Notify
--// Features:
--// draggable window
--// draggable floating button
--// square/circle floating button
--// transparent window and floating button (0.6)
--// icon support for names and rbxassetid
--// tab image support
--// arrow on action buttons
--// dropdown popup with search
--// Library:Notify({ Title, Content, Duration, Icon })

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local function Get(url)
	if typeof(game.HttpGet) == "function" then
		local ok, result = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and result then
			return result
		end
	end

	local ok, result = pcall(function()
		return HttpService:GetAsync(url)
	end)
	if ok and result then
		return result
	end

	return ""
end

local function safeLoadPack(url)
	local src = Get(url)
	if src == "" then
		return { Icons = {}, Spritesheets = {} }
	end

	local fn = loadstring(src)
	if not fn then
		return { Icons = {}, Spritesheets = {} }
	end

	local ok, result = pcall(fn)
	if ok and type(result) == "table" then
		result.Icons = result.Icons or {}
		result.Spritesheets = result.Spritesheets or {}
		return result
	end

	if ok and type(result) == "function" then
		local ok2, result2 = pcall(result)
		if ok2 and type(result2) == "table" then
			result2.Icons = result2.Icons or {}
			result2.Spritesheets = result2.Spritesheets or {}
			return result2
		end
	end

	return { Icons = {}, Spritesheets = {} }
end

local IconModule = {
	IconsType = "lucide",
	New = nil,
	IconThemeTag = nil,
	Icons = {
		lucide = safeLoadPack("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"),
		solar = safeLoadPack("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/solar/dist/Icons.lua"),
		craft = safeLoadPack("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua"),
		geist = safeLoadPack("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua"),
		sfsymbols = safeLoadPack("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/sfsymbols/dist/Icons.lua"),
		gravity = safeLoadPack("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/gravity/dist/Icons.lua"),
	},
}

local function parseIconString(iconString)
	if type(iconString) == "string" then
		local iconType, iconName = iconString:match("^(.-):(.+)$")
		if iconType and iconName then
			return iconType, iconName
		end
	end
	return nil, iconString
end

function IconModule.AddIcons(packName, iconsData)
	if type(packName) ~= "string" or type(iconsData) ~= "table" then
		error("AddIcons: packName must be string, iconsData must be table")
	end

	if not IconModule.Icons[packName] then
		IconModule.Icons[packName] = {
			Icons = {},
			Spritesheets = {},
		}
	end

	for iconName, iconValue in pairs(iconsData) do
		if type(iconValue) == "number" or (type(iconValue) == "string" and iconValue:match("^rbxassetid://")) then
			local imageId = iconValue
			if type(iconValue) == "number" then
				imageId = "rbxassetid://" .. tostring(iconValue)
			end

			IconModule.Icons[packName].Icons[iconName] = {
				Image = imageId,
				ImageRectSize = Vector2.new(0, 0),
				ImageRectPosition = Vector2.new(0, 0),
				Parts = nil,
			}
			IconModule.Icons[packName].Spritesheets[imageId] = imageId
		elseif type(iconValue) == "table" then
			local imageId = iconValue.Image
			local rectSize = iconValue.ImageRectSize
			local rectPos = iconValue.ImageRectPosition or iconValue.ImageRectOffset

			if imageId and rectSize and rectPos then
				if type(imageId) == "number" then
					imageId = "rbxassetid://" .. tostring(imageId)
				end

				IconModule.Icons[packName].Icons[iconName] = {
					Image = imageId,
					ImageRectSize = rectSize,
					ImageRectPosition = rectPos,
					Parts = iconValue.Parts,
				}

				if not IconModule.Icons[packName].Spritesheets[imageId] then
					IconModule.Icons[packName].Spritesheets[imageId] = imageId
				end
			else
				warn("AddIcons: Invalid spritesheet data format for icon '" .. tostring(iconName) .. "'")
			end
		else
			warn("AddIcons: Unsupported data type for icon '" .. tostring(iconName) .. "': " .. type(iconValue))
		end
	end
end

function IconModule.SetIconsType(iconType)
	IconModule.IconsType = iconType
end

function IconModule.Init(New, IconThemeTag)
	IconModule.New = New
	IconModule.IconThemeTag = IconThemeTag
	return IconModule
end

function IconModule.Icon(Icon, Type, DefaultFormat)
	DefaultFormat = DefaultFormat ~= false

	local iconType, iconName = parseIconString(Icon)
	local targetType = iconType or Type or IconModule.IconsType
	local iconSet = IconModule.Icons[targetType]
	if not iconSet then
		return nil
	end

	if iconSet.Icons and iconSet.Icons[iconName] then
		local data = iconSet.Icons[iconName]
		local sprite = (iconSet.Spritesheets and iconSet.Spritesheets[tostring(data.Image)]) or data.Image
		return { sprite, data }
	elseif iconSet[iconName] and type(iconSet[iconName]) == "string" and iconSet[iconName]:find("rbxassetid://") then
		return DefaultFormat and {
			iconSet[iconName],
			{
				ImageRectSize = Vector2.new(0, 0),
				ImageRectPosition = Vector2.new(0, 0),
			},
		} or iconSet[iconName]
	end

	return nil
end

function IconModule.GetIcon(Icon, Type)
	return IconModule.Icon(Icon, Type, false)
end

function IconModule.Icon2(Icon, Type, DefaultFormat)
	return IconModule.Icon(Icon, Type, DefaultFormat)
end

local Library = {}
Library.IconModule = IconModule

function Library:SetIconModule(module)
	if type(module) == "table" then
		self.IconModule = module
	end
end

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
		Parent = obj,
	})
end

local function stroke(obj, color, thickness, transparency)
	create("UIStroke", {
		Color = color or Color3.fromRGB(180, 180, 180),
		Thickness = thickness or 1,
		Transparency = transparency or 0.25,
		Parent = obj,
	})
end

local function pad(obj, l, r, t, b)
	create("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or 0),
		Parent = obj,
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

		local provider = Library.IconModule or IconModule
		if provider and provider.Icon then
			local ok, result = pcall(function()
				return provider.Icon(icon, nil, true)
			end)

			if ok and result then
				if type(result) == "string" then
					return result, nil
				elseif type(result) == "table" then
					return result[1], result[2]
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
		Parent = parent,
	})

	if data and data.ImageRectSize then
		img.ImageRectSize = data.ImageRectSize
	end
	if data and (data.ImageRectPosition or data.ImageRectOffset) then
		img.ImageRectOffset = data.ImageRectPosition or data.ImageRectOffset
	end

	return img
end

local function iconOrFallback(parent, icon, fallbackText, size, color)
	local img = makeIcon(parent, icon, size, color)
	if img then
		return img
	end

	return create("TextLabel", {
		Name = "FallbackIcon",
		BackgroundTransparency = 1,
		Text = fallbackText or "?",
		Size = size or UDim2.fromOffset(16, 16),
		Font = Enum.Font.GothamBold,
		TextColor3 = color or Color3.fromRGB(60, 60, 60),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = parent,
	})
end

function Library:Notify(config)
	config = config or {}

	local Title = config.Title or "Notification"
	local Content = config.Content or ""
	local Duration = tonumber(config.Duration) or 3
	local Icon = config.Icon

	local gui = self._notifyGui
	if not gui then
		gui = create("ScreenGui", {
			Name = "SKUI_Notifications",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
			Parent = getGuiParent(),
		})

		local holder = create("Frame", {
			Name = "Holder",
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 320, 1, -20),
			Position = UDim2.new(1, -334, 0, 10),
			Parent = gui,
		})

		local list = create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			Parent = holder,
		})

		self._notifyGui = gui
		self._notifyHolder = holder
	end

	local card = create("Frame", {
		Name = "Notification",
		Size = UDim2.fromOffset(320, 76),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Parent = self._notifyHolder,
	})
	round(card, UDim.new(0, 12))
	stroke(card, Color3.fromRGB(220, 220, 220), 1, 0.45)

	local iconHolder = create("Frame", {
		Name = "IconHolder",
		Size = UDim2.fromOffset(38, 38),
		Position = UDim2.fromOffset(14, 19),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		Parent = card,
	})
	round(iconHolder, UDim.new(0, 10))
	stroke(iconHolder, Color3.fromRGB(220, 220, 220), 1, 0.5)

	local visual = iconOrFallback(iconHolder, Icon, "!", UDim2.fromOffset(22, 22), Color3.fromRGB(85, 200, 120))
	visual.Position = UDim2.new(0.5, -11, 0.5, -11)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(62, 12),
		Size = UDim2.new(1, -74, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = Color3.fromRGB(35, 35, 35),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	create("TextLabel", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(62, 33),
		Size = UDim2.new(1, -74, 0, 30),
		Font = Enum.Font.Gotham,
		Text = Content,
		TextColor3 = Color3.fromRGB(110, 110, 110),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	card.BackgroundTransparency = 1
	card.Position = UDim2.new(1, 20, 0, 0)

	tween(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.08,
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()

	task.delay(Duration, function()
		if card and card.Parent then
			local out = tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
				Position = UDim2.new(1, 20, 0, 0),
			})
			out:Play()
			out.Completed:Wait()
			if card and card.Parent then
				card:Destroy()
			end
		end
	end)

	return card
end

function Library:CreateWindow(config)
	config = config or {}

	local Title = config.Title or "SKUI"
	local Subtitle = config.Subtitle or ""
	local Image = config.Image
	local SearchBar = config.SearchBar ~= false

	local lightMain = Color3.fromRGB(248, 248, 248)
	local lightPanel = Color3.fromRGB(255, 255, 255)
	local lightTop = Color3.fromRGB(242, 242, 242)
	local darkText = Color3.fromRGB(35, 35, 35)
	local mutedText = Color3.fromRGB(110, 110, 110)
	local accent = Color3.fromRGB(85, 200, 120)
	local accentSoft = Color3.fromRGB(210, 245, 220)

	local screen = create("ScreenGui", {
		Name = "SKUI_Nexus",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = getGuiParent(),
	})

	local main = create("Frame", {
		Name = "Window",
		Size = UDim2.fromOffset(550, 340),
		Position = UDim2.new(0.5, -275, 0.5, -170),
		BackgroundColor3 = lightMain,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Active = true,
		Parent = screen,
	})
	round(main, UDim.new(0, 14))
	stroke(main, Color3.fromRGB(205, 205, 205), 1, 0.35)

	local top = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = lightTop,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Parent = main,
	})
	round(top, UDim.new(0, 14))

	create("Frame", {
		Name = "TopCover",
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 1, -18),
		BackgroundColor3 = lightTop,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Parent = top,
	})

	local iconHolder = create("Frame", {
		Name = "LogoHolder",
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.fromOffset(14, 10),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = top,
	})
	round(iconHolder, UDim.new(0, 8))
	stroke(iconHolder, accent, 1, 0.55)

	if Image then
		local logo = iconOrFallback(iconHolder, Image, "◉", UDim2.fromOffset(18, 18), accent)
		logo.Position = UDim2.new(0.5, -9, 0.5, -9)
	end

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(48, 7),
		Size = UDim2.new(1, -180, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = darkText,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top,
	})

	create("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(48, 23),
		Size = UDim2.new(1, -180, 0, 16),
		Font = Enum.Font.Gotham,
		Text = Subtitle,
		TextColor3 = mutedText,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top,
	})

	local closeBtn = create("TextButton", {
		Name = "CloseButton",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -40, 0, 8),
		BackgroundColor3 = Color3.fromRGB(245, 245, 245),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = top,
	})
	round(closeBtn, UDim.new(0, 8))
	stroke(closeBtn, Color3.fromRGB(220, 220, 220), 1, 0.45)
	local closeVisual = iconOrFallback(closeBtn, "x", "×", UDim2.fromOffset(16, 16), Color3.fromRGB(65, 65, 65))
	closeVisual.Position = UDim2.new(0.5, -8, 0.5, -8)

	local searchBox
	if SearchBar then
		searchBox = create("TextBox", {
			Name = "SearchBar",
			PlaceholderText = "Search...",
			Text = "",
			ClearTextOnFocus = false,
			Size = UDim2.new(0, 160, 0, 28),
			Position = UDim2.new(1, -220, 0, 9),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Font = Enum.Font.Gotham,
			TextColor3 = darkText,
			PlaceholderColor3 = Color3.fromRGB(140, 140, 140),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = top,
		})
		round(searchBox, UDim.new(0, 8))
		stroke(searchBox, Color3.fromRGB(210, 210, 210), 1, 0.55)
		pad(searchBox, 28, 8, 0, 0)
		local searchVisual = iconOrFallback(searchBox, "search", "⌕", UDim2.fromOffset(14, 14), accent)
		searchVisual.Position = UDim2.new(0, 8, 0.5, -7)
	end

	local body = create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -46),
		Position = UDim2.new(0, 0, 0, 46),
		BackgroundTransparency = 1,
		Parent = main,
	})

	local tabPanel = create("ScrollingFrame", {
		Name = "Tabs",
		Size = UDim2.new(0, 150, 1, 0),
		BackgroundColor3 = lightPanel,
		BackgroundTransparency = 0.20,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = body,
	})
	round(tabPanel, UDim.new(0, 12))
	stroke(tabPanel, Color3.fromRGB(220, 220, 220), 1, 0.45)
	pad(tabPanel, 10, 10, 10, 10)

	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabPanel,
	})

	local rightPanel = create("Frame", {
		Name = "ElementsPanel",
		Size = UDim2.new(1, -160, 1, 0),
		Position = UDim2.new(0, 160, 0, 0),
		BackgroundColor3 = lightPanel,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Parent = body,
	})
	round(rightPanel, UDim.new(0, 12))
	stroke(rightPanel, Color3.fromRGB(220, 220, 220), 1, 0.45)

	local elementsHolder = create("Frame", {
		Name = "ElementsHolder",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = rightPanel,
	})

	local overlay = create("Frame", {
		Name = "PopupOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 40,
		Parent = main,
	})

	local popup = create("Frame", {
		Name = "Popup",
		Size = UDim2.fromOffset(310, 250),
		Position = UDim2.new(0.5, -155, 0.5, -125),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ZIndex = 41,
		Visible = false,
		Parent = overlay,
	})
	round(popup, UDim.new(0, 12))
	stroke(popup, Color3.fromRGB(215, 215, 215), 1, 0.4)

	local popupTitle = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.fromOffset(12, 10),
		Font = Enum.Font.GothamBold,
		Text = "Dropdown",
		TextColor3 = darkText,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 42,
		Parent = popup,
	})

	local popupSearch = create("TextBox", {
		Name = "Search",
		PlaceholderText = "Search options...",
		Text = "",
		ClearTextOnFocus = false,
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.fromOffset(12, 35),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = darkText,
		PlaceholderColor3 = Color3.fromRGB(145, 145, 145),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 42,
		Parent = popup,
	})
	round(popupSearch, UDim.new(0, 8))
	stroke(popupSearch, Color3.fromRGB(215, 215, 215), 1, 0.5)
	pad(popupSearch, 28, 8, 0, 0)
	local popupSearchVisual = iconOrFallback(popupSearch, "search", "⌕", UDim2.fromOffset(14, 14), accent)
	popupSearchVisual.Position = UDim2.new(0, 8, 0.5, -7)

	local popupScroll = create("ScrollingFrame", {
		Name = "Options",
		Size = UDim2.new(1, -24, 1, -78),
		Position = UDim2.fromOffset(12, 70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 42,
		Parent = popup,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = popupScroll,
	})

	local popupClose = create("TextButton", {
		Name = "Close",
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -34, 0, 8),
		BackgroundColor3 = Color3.fromRGB(245, 245, 245),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Text = "",
		ZIndex = 43,
		Parent = popup,
	})
	round(popupClose, UDim.new(0, 8))
	stroke(popupClose, Color3.fromRGB(220, 220, 220), 1, 0.45)
	local popupCloseVisual = iconOrFallback(popupClose, "x", "×", UDim2.fromOffset(14, 14), Color3.fromRGB(65, 65, 65))
	popupCloseVisual.Position = UDim2.new(0.5, -7, 0.5, -7)

	local floatingGui
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
	}

	function window:_applySearch(query)
		query = string.lower(query or "")
		local tab = self._activeTab
		if not tab then
			return
		end

		for _, item in ipairs(tab._items or {}) do
			if item.Root then
				local visible = query == "" or string.find(string.lower(item.SearchText or ""), query, 1, true) ~= nil
				item.Root.Visible = visible
			end
		end
	end

	local function showTab(tab)
		for _, t in ipairs(window.ActiveTabs) do
			t.Container.Visible = false
			t.Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end

		tab.Container.Visible = true
		tab.Button.BackgroundColor3 = accentSoft
		window._activeTab = tab

		if searchBox then
			window:_applySearch(searchBox.Text)
		end
	end

	do
		local dragStart
		local startPos
		local dragInput
		local dragging = false

		local function update(input)
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
			if dragging and dragInput and input == dragInput and dragStart and main.Visible then
				update(input)
			end
		end)
	end

	closeBtn.MouseButton1Click:Connect(function()
		if screen then
			screen:Destroy()
		end
		if floatingGui then
			floatingGui:Destroy()
		end
	end)

	popupClose.MouseButton1Click:Connect(function()
		overlay.Visible = false
		popup.Visible = false
	end)

	function window:CreateMinimizeBtn(config)
		config = config or {}
		local Img = config.Image
		local Shape = config.Shape or "Square"

		local gui = create("ScreenGui", {
			Name = "SKUI_Minimize",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
			Parent = getGuiParent(),
		})

		local btn = create("TextButton", {
			Name = "MinimizeBtn",
			Size = UDim2.fromOffset(36, 36),
			Position = UDim2.new(0, 16, 0.5, -18),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Active = true,
			Parent = gui,
		})

		if Shape == "Circle" then
			round(btn, UDim.new(1, 0))
		else
			round(btn, UDim.new(0, 0))
		end

		stroke(btn, Color3.fromRGB(220, 220, 220), 1, 0.45)

		local icon = iconOrFallback(btn, Img or "home", "◉", UDim2.new(1, 0, 1, 0), accent)
		icon.Position = UDim2.new(0, 0, 0, 0)
		icon.Size = UDim2.new(1, 0, 1, 0)
		if icon:IsA("ImageLabel") then
			icon.ScaleType = Enum.ScaleType.Fit
		end

		local dragStart
		local startPos
		local dragInput
		local dragging = false

		local function update(input)
			local delta = input.Position - dragStart
			btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end

		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = btn.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		btn.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and dragInput and input == dragInput and dragStart then
				update(input)
			end
		end)

		btn.MouseButton1Click:Connect(function()
			main.Visible = not main.Visible
		end)

		floatingGui = gui
		return btn
	end

	function window:CreateTab(tabData)
		local tabTitle = tabData[1] or "Tab"
		local tabIcon = tabData[2]

		local tabBtn = create("TextButton", {
			Name = tabTitle .. "_Tab",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = tabPanel,
		})
		round(tabBtn, UDim.new(0, 10))
		stroke(tabBtn, Color3.fromRGB(220, 220, 220), 1, 0.5)

		if tabIcon then
			local ico = makeIcon(tabBtn, tabIcon, UDim2.fromOffset(16, 16), accent)
			if ico then
				ico.Position = UDim2.fromOffset(10, 9)
			end
		end

		create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, tabIcon and 34 or 12, 0, 0),
			Size = UDim2.new(1, -(tabIcon and 40 or 14), 1, 0),
			Font = Enum.Font.GothamSemibold,
			Text = tabTitle,
			TextColor3 = darkText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = tabBtn,
		})

		local container = create("ScrollingFrame", {
			Name = tabTitle .. "_Container",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = accent,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			Parent = elementsHolder,
		})
		pad(container, 12, 12, 12, 12)

		create("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = container,
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
				SearchText = searchText or "",
			})
		end

		function tab:CreateButton(data)
			data = data or {}

			local root = create("TextButton", {
				Name = "ButtonElement",
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.10,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = container,
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(220, 220, 220), 1, 0.55)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -42, 1, 0),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Button",
				TextColor3 = darkText,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root,
			})

			local arrow = iconOrFallback(root, "chevron-right", "›", UDim2.fromOffset(12, 12), accent)
			arrow.Position = UDim2.new(1, -18, 0.5, -6)

			if data.Locked then
				root.BackgroundTransparency = 0.20
			end

			root.MouseButton1Click:Connect(function()
				if data.Locked then
					return
				end
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
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.10,
				BorderSizePixel = 0,
				Parent = container,
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(220, 220, 220), 1, 0.55)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 4),
				Size = UDim2.new(1, -70, 0, 18),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Toggle",
				TextColor3 = darkText,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root,
			})

			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 20),
				Size = UDim2.new(1, -70, 0, 14),
				Font = Enum.Font.Gotham,
				Text = data.Desc or "",
				TextColor3 = mutedText,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root,
			})

			local switch = create("TextButton", {
				Size = UDim2.fromOffset(42, 22),
				Position = UDim2.new(1, -54, 0.5, -11),
				BackgroundColor3 = state and accent or Color3.fromRGB(220, 220, 220),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = root,
			})
			round(switch, UDim.new(1, 0))

			local knob = create("Frame", {
				Size = UDim2.fromOffset(18, 18),
				Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Parent = switch,
			})
			round(knob, UDim.new(1, 0))

			local function setState(v)
				state = v
				tween(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = state and accent or Color3.fromRGB(220, 220, 220),
				}):Play()
				tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
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
				end,
			}
		end

		function tab:CreateInput(data)
			data = data or {}

			local root = create("Frame", {
				Name = "InputElement",
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.10,
				BorderSizePixel = 0,
				Parent = container,
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(220, 220, 220), 1, 0.55)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 4),
				Size = UDim2.new(1, -24, 0, 16),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Input",
				TextColor3 = darkText,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root,
			})

			local box = create("TextBox", {
				PlaceholderText = data.Placeholder or "Enter text...",
				Text = data.Value or "",
				ClearTextOnFocus = false,
				Size = UDim2.new(1, -24, 0, 24),
				Position = UDim2.fromOffset(12, 24),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				Font = Enum.Font.Gotham,
				TextColor3 = darkText,
				PlaceholderColor3 = Color3.fromRGB(145, 145, 145),
				TextSize = 12,
				Parent = root,
			})
			round(box, UDim.new(0, 8))
			stroke(box, Color3.fromRGB(220, 220, 220), 1, 0.55)

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
			local step = tonumber(data.Step) or 1
			if step <= 0 then step = 1 end

			local root = create("Frame", {
				Name = "SliderElement",
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.10,
				BorderSizePixel = 0,
				Parent = container,
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(220, 220, 220), 1, 0.55)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 4),
				Size = UDim2.new(1, -70, 0, 16),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Slider",
				TextColor3 = darkText,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root,
			})

			local valLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -50, 0, 4),
				Size = UDim2.fromOffset(40, 16),
				Font = Enum.Font.Gotham,
				Text = tostring(value),
				TextColor3 = accent,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = root,
			})

			local track = create("Frame", {
				Size = UDim2.new(1, -24, 0, 8),
				Position = UDim2.fromOffset(12, 32),
				BackgroundColor3 = Color3.fromRGB(230, 230, 230),
				BorderSizePixel = 0,
				Parent = root,
			})
			round(track, UDim.new(1, 0))

			local fill = create("Frame", {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = accent,
				BorderSizePixel = 0,
				Parent = track,
			})
			round(fill, UDim.new(1, 0))

			local knob = create("Frame", {
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Parent = track,
			})
			round(knob, UDim.new(1, 0))

			local dragging = false

			local function setValue(v)
				v = math.clamp(v, min, max)
				v = math.floor((v - min) / step + 0.5) * step + min
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
				end,
			}
		end

		function tab:CreateDropdown(data)
			data = data or {}
			local values = data.Values or {}
			local selected = data.Value or values[1] or "None"

			local root = create("TextButton", {
				Name = "DropdownElement",
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.10,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = container,
			})
			round(root, UDim.new(0, 10))
			stroke(root, Color3.fromRGB(220, 220, 220), 1, 0.55)

			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 0),
				Size = UDim2.new(1, -56, 1, 0),
				Font = Enum.Font.GothamMedium,
				Text = data.Title or "Dropdown",
				TextColor3 = darkText,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = root,
			})

			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -140, 0, 0),
				Size = UDim2.fromOffset(110, 36),
				Font = Enum.Font.Gotham,
				Text = tostring(selected),
				TextColor3 = accent,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = root,
			})

			local clickIcon = iconOrFallback(root, "chevron-down", "▾", UDim2.fromOffset(14, 14), accent)
			clickIcon.Position = UDim2.new(1, -22, 0.5, -7)

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
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 0.08,
							BorderSizePixel = 0,
							Text = str,
							Font = Enum.Font.Gotham,
							TextSize = 12,
							TextColor3 = darkText,
							AutoButtonColor = false,
							ZIndex = 42,
							Parent = popupScroll,
						})
						round(opt, UDim.new(0, 8))
						stroke(opt, Color3.fromRGB(220, 220, 220), 1, 0.55)

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
				popupTitle.Text = data.Title or "Dropdown"
				popupSearch.Text = ""
				refreshList("")
				popupSearch:CaptureFocus()
			end

			root.MouseButton1Click:Connect(openDropdown)
			clickIcon.Parent = root
			clickIcon.ZIndex = root.ZIndex + 1

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

			addItem(root, data.Title or "Dropdown")
			return dropdown
		end

		function tab:CreateLabel(data)
			data = data or {}
			local root = create("TextLabel", {
				Name = "LabelElement",
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				Text = data.Text or "",
				TextColor3 = darkText,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = container,
			})
			addItem(root, data.Text or "Label")
			return root
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

	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			if window._activeTab then
				window:_applySearch(searchBox.Text)
			end
		end)
	end

	function window:Notify(config)
		return Library:Notify(config)
	end

	return window
end

return Library
