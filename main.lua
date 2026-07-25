-- BTUI Modern Studio / Nexus Dark
-- Keeps your API:
-- local Window = BTUI:CreateWindow({ Title = "...", Image = "...", Subtitle = "...", SearchBar = true })
-- local MinimizeBtn = Window:CreateMinimizeBtn({ Title = "Open UI", Image = "..." })
-- local Tab = Window:CreateTab({ "Main", "home" })

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))

local function IsExploit()
	return request and true or false
end

local function Get(url)
	if IsExploit() then
		return game:HttpGet(url)
	else
		local Success, Result = pcall(function()
			return HttpService:GetAsync(url)
		end)
		if Success then
			return Result
		else
			return ReplicatedStorage:WaitForChild("Request", 9999):InvokeServer({ Url = url })
		end
	end
end

local function Loadstring(src)
	if not IsExploit() and ReplicatedStorage:FindFirstChild("Loadstring") then
		return function()
			return ReplicatedStorage:WaitForChild("Loadstring", 9999):InvokeServer(src)
		end
	else
		return loadstring(src)
	end
end

local IconModule = {
	IconsType = "lucide",
	New = nil,
	IconThemeTag = nil,
	Icons = {
		lucide = IsExploit() and Loadstring(
			Get("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua")
		)() or require("./lucide/dist/Icons"),
		solar = IsExploit() and Loadstring(
			Get("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/solar/dist/Icons.lua")
		)() or require("./solar/dist/Icons"),
		craft = IsExploit() and Loadstring(
			Get("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua")
		)() or require("./craft/dist/Icons"),
		geist = IsExploit() and Loadstring(
			Get("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua")
		)() or require("./geist/dist/Icons"),
		sfsymbols = IsExploit() and Loadstring(
			Get("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/sfsymbols/dist/Icons.lua")
		)() or require("./sfsymbols/dist/Icons"),
		gravity = IsExploit() and Loadstring(
			Get("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/gravity/dist/Icons.lua")
		)() or require("./gravity/dist/Icons"),
	},
}

local function parseIconString(iconString)
	if type(iconString) == "string" then
		local splitIndex = iconString:find(":")
		if splitIndex then
			local iconType = iconString:sub(1, splitIndex - 1)
			local iconName = iconString:sub(splitIndex + 1)
			return iconType, iconName
		end
	end
	return nil, iconString
end

function IconModule.AddIcons(packName, iconsData)
	if type(packName) ~= "string" or type(iconsData) ~= "table" then
		error("AddIcons: packName must be string, iconsData must be table")
		return
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
			if iconValue.Image and iconValue.ImageRectSize and iconValue.ImageRectPosition then
				local imageId = iconValue.Image
				if type(imageId) == "number" then
					imageId = "rbxassetid://" .. tostring(imageId)
				end

				IconModule.Icons[packName].Icons[iconName] = {
					Image = imageId,
					ImageRectSize = iconValue.ImageRectSize,
					ImageRectPosition = iconValue.ImageRectPosition,
					Parts = iconValue.Parts,
				}

				if not IconModule.Icons[packName].Spritesheets[imageId] then
					IconModule.Icons[packName].Spritesheets[imageId] = imageId
				end
			else
				warn("AddIcons: Invalid spritesheet data format for icon '" .. iconName .. "'")
			end
		else
			warn("AddIcons: Unsupported data type for icon '" .. iconName .. "': " .. type(iconValue))
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
	local targetName = iconName

	local iconSet = IconModule.Icons[targetType]

	if iconSet and iconSet.Icons and iconSet.Icons[targetName] then
		return {
			iconSet.Spritesheets[tostring(iconSet.Icons[targetName].Image)],
			iconSet.Icons[targetName],
		}
	elseif iconSet and iconSet[targetName] and string.find(iconSet[targetName], "rbxassetid://") then
		return DefaultFormat
				and {
					iconSet[targetName],
					{ ImageRectSize = Vector2.new(0, 0), ImageRectPosition = Vector2.new(0, 0) },
				}
			or iconSet[targetName]
	end
	return nil
end

function IconModule.GetIcon(Icon, Type)
	return IconModule.Icon(Icon, Type, false)
end

function IconModule.Icon2(Icon, Type, DefaultFormat)
	return IconModule.Icon(Icon, Type, true)
end

function IconModule.Image(IconConfig)
	local Icon = {
		Icon = IconConfig.Icon or nil,
		Type = IconConfig.Type,
		Colors = IconConfig.Colors or { (IconModule.IconThemeTag or Color3.new(1, 1, 1)), Color3.new(1, 1, 1) },
		Size = IconConfig.Size or UDim2.new(0, 24, 0, 24),
		IconFrame = nil,
	}

	local Colors = {}
	for _, color in next, Icon.Colors do
		Colors[_] = {
			ThemeTag = typeof(color) == "string" and color,
			Color = typeof(color) == "Color3" and color,
		}
	end

	local IconLabel = IconModule.Icon2(Icon.Icon, Icon.Type)
	local isrbxassetid = typeof(IconLabel) == "string" and string.find(IconLabel, "rbxassetid://")

	if IconModule.New then
		local New = IconModule.New
		local IconFrame = New("ImageLabel", {
			Size = Icon.Size,
			BackgroundTransparency = 1,
			ImageColor3 = Colors[1].Color or nil,
			ThemeTag = Colors[1].ThemeTag and {
				ImageColor3 = Colors[1].ThemeTag,
			},
			Image = isrbxassetid and IconLabel or IconLabel[1],
			ImageRectSize = isrbxassetid and nil or IconLabel[2].ImageRectSize,
			ImageRectOffset = isrbxassetid and nil or IconLabel[2].ImageRectPosition,
		})

		if not isrbxassetid and IconLabel[2].Parts then
			for _, part in next, IconLabel[2].Parts do
				local IconPartLabel = IconModule.Icon(part, Icon.Type)

				local IconPart = New("ImageLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					ImageColor3 = Colors[1 + _].Color or nil,
					ThemeTag = Colors[1 + _].ThemeTag and {
						ImageColor3 = Colors[1 + _].ThemeTag,
					},
					Image = IconPartLabel[1],
					ImageRectSize = IconPartLabel[2].ImageRectSize,
					ImageRectOffset = IconPartLabel[2].ImageRectPosition,
					Parent = IconFrame,
				})
			end
		end

		Icon.IconFrame = IconFrame
	else
		local IconFrame = Instance.new("ImageLabel")
		IconFrame.Size = Icon.Size
		IconFrame.BackgroundTransparency = 1
		IconFrame.ImageColor3 = Colors[1].Color
		IconFrame.Image = isrbxassetid and IconLabel or IconLabel[1]
		IconFrame.ImageRectSize = isrbxassetid and nil or IconLabel[2].ImageRectSize
		IconFrame.ImageRectOffset = isrbxassetid and nil or IconLabel[2].ImageRectPosition

		if not isrbxassetid and IconLabel[2].Parts then
			for _, part in next, IconLabel[2].Parts do
				local IconPartLabel = IconModule.Icon(part, Icon.Type)

				local IconPart = Instance.new("ImageLabel")
				IconPart.Size = UDim2.new(1, 0, 1, 0)
				IconPart.BackgroundTransparency = 1
				IconPart.ImageColor3 = Colors[1 + _].Color
				IconPart.Image = IconPartLabel[1]
				IconPart.ImageRectSize = IconPartLabel[2].ImageRectSize
				IconPart.ImageRectOffset = IconPartLabel[2].ImageRectPosition
				IconPart.Parent = IconFrame
			end
		end

		Icon.IconFrame = IconFrame
	end

	return Icon
end

local BTUI = {}
BTUI.IconModule = IconModule

local THEME = {
	BG = Color3.fromRGB(9, 9, 12),
	BG2 = Color3.fromRGB(14, 14, 18),
	BG3 = Color3.fromRGB(18, 18, 24),
	Panel = Color3.fromRGB(22, 22, 30),
	Accent = Color3.fromRGB(128, 87, 255),
	Accent2 = Color3.fromRGB(82, 150, 255),
	Accent3 = Color3.fromRGB(66, 220, 164),
	BlueSelect = Color3.fromRGB(70, 145, 255),
	Text = Color3.fromRGB(245, 245, 250),
	SubText = Color3.fromRGB(160, 166, 186),
	Stroke = Color3.fromRGB(56, 56, 70),
	SoftStroke = Color3.fromRGB(34, 34, 44),
	Shadow = Color3.fromRGB(0, 0, 0),
	Good = Color3.fromRGB(77, 220, 140),
	Warn = Color3.fromRGB(255, 210, 60),
	Danger = Color3.fromRGB(255, 90, 100),
}

local function New(className, props)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	return obj
end

local function Corner(parent, radius)
	return New("UICorner", {
		CornerRadius = radius or UDim.new(0, 10),
		Parent = parent,
	})
end

local function Stroke(parent, transparency, thickness, color)
	return New("UIStroke", {
		Transparency = transparency or 0.35,
		Thickness = thickness or 1,
		Color = color or THEME.Stroke,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Pad(parent, l, r, t, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l or 8),
		PaddingRight = UDim.new(0, r or 8),
		PaddingTop = UDim.new(0, t or 8),
		PaddingBottom = UDim.new(0, b or 8),
		Parent = parent,
	})
end

local function Tween(obj, info, goal)
	local tw = TweenService:Create(obj, info, goal)
	tw:Play()
	return tw
end

local function SafeCall(fn, ...)
	if typeof(fn) == "function" then
		local ok, err = pcall(fn, ...)
		if not ok then
			warn("[BTUI] callback error:", err)
		end
	end
end

local function IsImageLike(v)
	if type(v) == "number" then return true end
	if type(v) ~= "string" then return false end
	return v:match("^rbxassetid://") or v:match("^rbxthumb://") or v:match("^http")
end

local function NormalizeImage(v)
	if type(v) == "number" then
		return "rbxassetid://" .. tostring(v)
	end
	if type(v) == "string" then
		if v:match("^rbxassetid://") or v:match("^rbxthumb://") or v:match("^http") then
			return v
		end
		local digits = v:match("^%d+$")
		if digits then
			return "rbxassetid://" .. digits
		end
	end
	return nil
end

local function ResolveIcon(icon, iconType)
	if icon == nil then
		return nil, nil
	end

	local direct = NormalizeImage(icon)
	if direct then
		return direct, nil
	end

	if type(icon) == "string" and IconModule then
		local ok, result = pcall(function()
			if type(IconModule.Image) == "function" then
				local img = IconModule:Image({
					Icon = icon,
					Type = iconType or "lucide",
					Size = UDim2.fromOffset(18, 18),
				})
				if typeof(img) == "table" and img.IconFrame and img.IconFrame:IsA("ImageLabel") then
					return img.IconFrame.Image, {
						ImageRectSize = img.IconFrame.ImageRectSize,
						ImageRectPosition = img.IconFrame.ImageRectOffset,
					}
				end
			end

			if type(IconModule.Icon2) == "function" then
				local res = IconModule.Icon2(icon, iconType)
				if type(res) == "string" then
					return NormalizeImage(res) or res, nil
				elseif type(res) == "table" then
					return NormalizeImage(res[1]) or res[1], {
						ImageRectSize = res[2] and res[2].ImageRectSize or nil,
						ImageRectPosition = res[2] and res[2].ImageRectPosition or nil,
					}
				end
			end

			if type(IconModule.Icon) == "function" then
				local res = IconModule.Icon(icon, iconType, true)
				if type(res) == "string" then
					return NormalizeImage(res) or res, nil
				elseif type(res) == "table" then
					return NormalizeImage(res[1]) or res[1], {
						ImageRectSize = res[2] and res[2].ImageRectSize or nil,
						ImageRectPosition = res[2] and res[2].ImageRectPosition or nil,
					}
				end
			end
		end)
		if ok and result then
			return result
		end
	end

	return nil, nil
end

local function MakeIcon(parent, icon, size, tint, iconType)
	local img, rect = ResolveIcon(icon, iconType)
	if not img then
		local textFallback = New("TextLabel", {
			Name = "IconFallback",
			BackgroundTransparency = 1,
			Size = size or UDim2.fromOffset(18, 18),
			Text = tostring(icon or "?"):sub(1, 1):upper(),
			TextColor3 = tint or THEME.Text,
			TextSize = math.max(10, math.floor((size and size.Y.Offset or 18) * 0.7)),
			Font = Enum.Font.GothamBold,
			ZIndex = 5,
			Parent = parent,
		})
		return textFallback
	end

	local iconLabel = New("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = size or UDim2.fromOffset(18, 18),
		Image = img,
		ImageColor3 = tint or THEME.Text,
		ImageTransparency = 0,
		ScaleType = Enum.ScaleType.Fit,
		ResampleMode = Enum.ResamplerMode.Default,
		Parent = parent,
	})

	if rect then
		if rect.ImageRectSize then
			iconLabel.ImageRectSize = rect.ImageRectSize
		end
		if rect.ImageRectPosition then
			iconLabel.ImageRectOffset = rect.ImageRectPosition
		end
	end

	return iconLabel
end

local function CreateShadow(parent)
	local shadow = New("Frame", {
		Name = "Shadow",
		BackgroundColor3 = THEME.Shadow,
		BackgroundTransparency = 0.55,
		Size = UDim2.new(1, 22, 1, 22),
		Position = UDim2.fromOffset(-11, -11),
		ZIndex = 0,
		Parent = parent,
	})
	Corner(shadow, UDim.new(0, 16))
	return shadow
end

local function Dragify(dragHandle, target)
	local dragging = false
	local dragInput
	local startPos
	local startFramePos

	local function update(input)
		local delta = input.Position - startPos
		target.Position = UDim2.new(
			startFramePos.X.Scale,
			startFramePos.X.Offset + delta.X,
			startFramePos.Y.Scale,
			startFramePos.Y.Offset + delta.Y
		)
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = input.Position
			startFramePos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			update(input)
		end
	end)
end

local function MakeCanvasUpdater(scrollFrame, layout)
	local function update()
		local content = layout.AbsoluteContentSize
		scrollFrame.CanvasSize = UDim2.fromOffset(0, content.Y + 12)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	task.defer(update)
	return update
end

local function SetGlow(frame)
	local glow = New("Frame", {
		Name = "Glow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1,
		Parent = frame,
	})
	local g1 = New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 40, 1, 40),
		Position = UDim2.fromOffset(-20, -20),
		Image = "rbxassetid://10709791238",
		ImageTransparency = 0.84,
		ImageColor3 = THEME.Accent,
		ZIndex = 1,
		Parent = glow,
	})
	local g2 = New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 50, 1, 50),
		Position = UDim2.fromOffset(-25, -25),
		Image = "rbxassetid://10709791238",
		ImageTransparency = 0.90,
		ImageColor3 = THEME.Accent2,
		ZIndex = 1,
		Parent = glow,
	})
	local g3 = New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 70, 1, 70),
		Position = UDim2.fromOffset(-35, -35),
		Image = "rbxassetid://10709791238",
		ImageTransparency = 0.94,
		ImageColor3 = THEME.Accent3,
		ZIndex = 1,
		Parent = glow,
	})
	return glow, g1, g2, g3
end

function BTUI:CreateWindow(config)
	config = config or {}

	local window = {}
	window.Tabs = {}
	window.ActiveTab = nil
	window._destroyed = false
	window._uiVisible = true
	window._searchText = ""

	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
	local guiParent = (gethui and gethui()) or CoreGui or playerGui

	local ScreenGui = New("ScreenGui", {
		Name = "BTUI_Modern_" .. tostring(math.random(10000, 99999)),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = guiParent,
	})

	local MainShadow = New("Frame", {
		Name = "MainShadow",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(920, 600),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 1,
		Parent = ScreenGui,
	})
	CreateShadow(MainShadow)
	local _, glow1, glow2, glow3 = SetGlow(MainShadow)

	local Main = New("Frame", {
		Name = "Main",
		BackgroundColor3 = THEME.BG,
		BackgroundTransparency = 0.08,
		Size = UDim2.fromOffset(550, 340),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = ScreenGui,
	})
	Corner(Main, UDim.new(0, 16))
	Stroke(Main, 0.22, 1, THEME.Stroke)

	local MainGlow = New("Frame", {
		Name = "MainGlow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1,
		Parent = Main,
	})
	SetGlow(MainGlow)

	local TopBar = New("Frame", {
		Name = "TopBar",
		BackgroundColor3 = THEME.BG2,
		BackgroundTransparency = 0.03,
		Size = UDim2.new(1, 0, 0, 54),
		ZIndex = 3,
		Parent = Main,
	})
	Stroke(TopBar, 0.82, 1, THEME.SoftStroke)

	local TopGlow = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 2,
		Parent = TopBar,
	})
	SetGlow(TopGlow)

	local LogoWrap = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.fromOffset(12, 12),
		ZIndex = 4,
		Parent = TopBar,
	})
	local logo = MakeIcon(LogoWrap, config.Image or "sparkles", UDim2.fromOffset(18, 18), THEME.Text, "lucide")
	if not logo then
		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "◆",
			TextColor3 = THEME.Text,
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			ZIndex = 4,
			Parent = LogoWrap,
		})
	end

	local Title = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -260, 0, 22),
		Position = UDim2.fromOffset(42, 8),
		Text = config.Title or "BTUI",
		TextColor3 = THEME.Text,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = TopBar,
	})

	local Subtitle = New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -260, 0, 14),
		Position = UDim2.fromOffset(42, 24),
		Text = config.Subtitle or "",
		TextColor3 = THEME.SubText,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = TopBar,
	})

	local SearchBox
	if config.SearchBar then
		local SearchFrame = New("Frame", {
			Name = "SearchFrame",
			BackgroundColor3 = THEME.BG3,
			BackgroundTransparency = 0.12,
			Size = UDim2.fromOffset(190, 28),
			Position = UDim2.new(1, -300, 0, 10),
			ZIndex = 4,
			Parent = TopBar,
		})
		Corner(SearchFrame, UDim.new(0, 9))
		Stroke(SearchFrame, 0.7, 1, THEME.SoftStroke)

		local SearchIconWrap = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(20, 20),
			Position = UDim2.fromOffset(7, 4),
			ZIndex = 5,
			Parent = SearchFrame,
		})
		local sIcon = MakeIcon(SearchIconWrap, "search", UDim2.fromOffset(14, 14), THEME.SubText, "lucide")
		if not sIcon then
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "⌕",
				TextColor3 = THEME.SubText,
				TextSize = 15,
				Font = Enum.Font.GothamBold,
				ZIndex = 5,
				Parent = SearchIconWrap,
			})
		end

		SearchBox = New("TextBox", {
			Name = "SearchBox",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -28, 1, 0),
			Position = UDim2.fromOffset(28, 0),
			ClearTextOnFocus = false,
			PlaceholderText = "Search...",
			Text = "",
			TextColor3 = THEME.Text,
			PlaceholderColor3 = THEME.SubText,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = SearchFrame,
		})
	end

	local CloseBtn = New("TextButton", {
		Name = "CloseBtn",
		BackgroundColor3 = THEME.Danger,
		BackgroundTransparency = 0.1,
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -34, 0, 10),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 5,
		Parent = TopBar,
	})
	Corner(CloseBtn, UDim.new(0, 9))
	Stroke(CloseBtn, 0.68, 1, Color3.fromRGB(120, 50, 50))
	local closeIconWrap = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 6,
		Parent = CloseBtn,
	})
	local closeIcon = MakeIcon(closeIconWrap, "x", UDim2.fromOffset(14, 14), THEME.Text, "lucide")
	if not closeIcon then
		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "×",
			TextColor3 = THEME.Text,
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			ZIndex = 6,
			Parent = closeIconWrap,
		})
	end

	local Body = New("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -48),
		Position = UDim2.fromOffset(0, 48),
		ZIndex = 3,
		Parent = Main,
	})

	local Sidebar = New("ScrollingFrame", {
		Name = "Sidebar",
		BackgroundColor3 = THEME.BG2,
		BackgroundTransparency = 0.1,
		Size = UDim2.new(0, 156, 1, 0),
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = Body,
	})
	Stroke(Sidebar, 0.72, 1, THEME.SoftStroke)
	Pad(Sidebar, 8, 8, 8, 8)
	local SidebarLayout = New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Sidebar,
	})
	MakeCanvasUpdater(Sidebar, SidebarLayout)

	local Divider = New("Frame", {
		BackgroundColor3 = THEME.SoftStroke,
		BackgroundTransparency = 0.65,
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.fromOffset(156, 0),
		ZIndex = 3,
		Parent = Body,
	})

	local Right = New("Frame", {
		Name = "Right",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -156, 1, 0),
		Position = UDim2.fromOffset(156, 0),
		ZIndex = 3,
		Parent = Body,
	})

	local Pages = New("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 3,
		Parent = Right,
	})

	local FloatingGui
	local FloatingBtn

	local function setVisible(state)
		window._uiVisible = state
		Main.Visible = state
		MainShadow.Visible = state
		if FloatingGui then
			FloatingGui.Enabled = not state
		end
	end

	local function openAnim()
		Main.Visible = true
		MainShadow.Visible = true
		Main.Size = UDim2.fromOffset(530, 326)
		Main.BackgroundTransparency = 0.16
		Tween(Main, TweenInfo.new(0.23, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(550, 340),
			BackgroundTransparency = 0.08,
		})
	end

	local function closeAnim()
		local tw = Tween(Main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(530, 326),
			BackgroundTransparency = 0.18,
		})
		tw.Completed:Once(function()
			if not window._destroyed then
				Main.Visible = false
				MainShadow.Visible = false
			end
		end)
	end

	local function applySearch(text)
		window._searchText = string.lower(text or "")
		local tab = window.ActiveTab
		if not tab then
			return
		end

		for _, item in ipairs(tab._searchItems) do
			if item.Root and item.Root.Parent then
				local hay = string.lower((item.SearchText or "") .. " " .. (item.DescText or ""))
				local show = window._searchText == "" or string.find(hay, window._searchText, 1, true) ~= nil
				item.Root.Visible = show
			end
		end
	end

	if SearchBox then
		SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			applySearch(SearchBox.Text)
		end)
	end

	local function selectTab(tab)
		if window.ActiveTab == tab then
			return
		end

		if window.ActiveTab then
			Tween(window.ActiveTab.Button, TweenInfo.new(0.18), {
				BackgroundTransparency = 0.35,
			})
			Tween(window.ActiveTab.ButtonIndicator, TweenInfo.new(0.18), {
				BackgroundTransparency = 1,
			})
			window.ActiveTab.Page.Visible = false
		end

		window.ActiveTab = tab
		tab.Page.Visible = true
		tab.Page.GroupTransparency = 1
		Tween(tab.Page, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
		})

		Tween(tab.Button, TweenInfo.new(0.18), {
			BackgroundTransparency = 0.12,
		})
		Tween(tab.ButtonIndicator, TweenInfo.new(0.18), {
			BackgroundTransparency = 0,
		})
		applySearch(SearchBox and SearchBox.Text or "")
	end

	local function createFloatingButton()
		if FloatingGui then
			return
		end

		FloatingGui = New("ScreenGui", {
			Name = "BTUI_Floating_" .. tostring(math.random(10000, 99999)),
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Enabled = false,
			Parent = guiParent,
		})

		FloatingBtn = New("TextButton", {
			Name = "OpenBtn",
			BackgroundColor3 = THEME.BG2,
			BackgroundTransparency = 0.04,
			Size = UDim2.fromOffset(132, 40),
			Position = UDim2.new(1, -150, 1, -64),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 50,
			Parent = FloatingGui,
		})
		Corner(FloatingBtn, UDim.new(0, 12))
		Stroke(FloatingBtn, 0.58, 1, THEME.Stroke)

		local FloatingGlow = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 49,
			Parent = FloatingBtn,
		})
		SetGlow(FloatingGlow)

		local btnIcon = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.fromOffset(10, 5),
			ZIndex = 51,
			Parent = FloatingBtn,
		})
		local icon = MakeIcon(btnIcon, config.Image or "home", UDim2.fromOffset(18, 18), THEME.Text, "lucide")
		if not icon then
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "◎",
				TextColor3 = THEME.Text,
				TextSize = 16,
				Font = Enum.Font.GothamBold,
				ZIndex = 51,
				Parent = btnIcon,
			})
		end

		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -44, 1, 0),
			Position = UDim2.fromOffset(42, 0),
			Text = config.MinimizeTitle or "Open UI",
			TextColor3 = THEME.Text,
			TextSize = 13,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 51,
			Parent = FloatingBtn,
		})

		FloatingBtn.MouseEnter:Connect(function()
			Tween(FloatingBtn, TweenInfo.new(0.14), { BackgroundTransparency = 0.01 })
		end)
		FloatingBtn.MouseLeave:Connect(function()
			Tween(FloatingBtn, TweenInfo.new(0.14), { BackgroundTransparency = 0.06 })
		end)

		FloatingBtn.MouseButton1Click:Connect(function()
			setVisible(true)
			openAnim()
			FloatingGui.Enabled = false
		end)
	end

	function window:CreateMinimizeBtn(minConfig)
		minConfig = minConfig or {}
		config.MinimizeTitle = minConfig.Title or config.MinimizeTitle or "Open UI"
		if minConfig.Image then
			config.Image = minConfig.Image
		end
		createFloatingButton()
		if FloatingGui then
			FloatingGui.Enabled = false
		end
		return FloatingBtn
	end

	CloseBtn.MouseButton1Click:Connect(function()
		window:Destroy()
	end)

	Dragify(TopBar, Main)
	Dragify(TopBar, MainShadow)

	local function createElementCard(parent, height)
		local card = New("Frame", {
			BackgroundColor3 = THEME.BG2,
			BackgroundTransparency = 0.14,
			Size = UDim2.new(1, -4, 0, height),
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = parent,
		})
		Corner(card, UDim.new(0, 12))
		Stroke(card, 0.76, 1, THEME.SoftStroke)
		return card
	end

	local function refreshTabSearch(tab)
		if window.ActiveTab == tab then
			applySearch(SearchBox and SearchBox.Text or "")
		end
	end

	function window:CreateTab(tabConfig)
		tabConfig = tabConfig or {}
		local name = tabConfig[1] or tabConfig.Title or "Tab"
		local icon = tabConfig[2] or tabConfig.Image or nil

		local tab = {}
		tab.Title = name
		tab.Icon = icon
		tab._searchItems = {}
		tab.Elements = {}

		local Button = New("TextButton", {
			Name = "TabButton_" .. name,
			BackgroundColor3 = THEME.BG3,
			BackgroundTransparency = 0.35,
			Size = UDim2.new(1, 0, 0, 38),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 4,
			Parent = Sidebar,
		})
		Corner(Button, UDim.new(0, 11))
		Stroke(Button, 0.76, 1, THEME.SoftStroke)

		local Indicator = New("Frame", {
			Name = "Indicator",
			BackgroundColor3 = THEME.BlueSelect,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(3, 22),
			Position = UDim2.fromOffset(5, 8),
			ZIndex = 5,
			Parent = Button,
		})
		Corner(Indicator, UDim.new(1, 0))

		local iconWrap = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(22, 22),
			Position = UDim2.fromOffset(13, 8),
			ZIndex = 5,
			Parent = Button,
		})
		local tabIcon = MakeIcon(iconWrap, icon, UDim2.fromOffset(16, 16), THEME.Text, "lucide")
		if not tabIcon then
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "•",
				TextColor3 = THEME.Text,
				TextSize = 18,
				Font = Enum.Font.GothamBold,
				ZIndex = 5,
				Parent = iconWrap,
			})
		end

		local TabName = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -42, 1, 0),
			Position = UDim2.fromOffset(38, 0),
			Text = name,
			TextColor3 = THEME.Text,
			TextSize = 13,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = Button,
		})

		local Page = New("CanvasGroup", {
			Name = "TabPage_" .. name,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			GroupTransparency = 1,
			ZIndex = 3,
			Parent = Pages,
		})

		local Header = New("Frame", {
			Name = "PageHeader",
			BackgroundColor3 = THEME.BG2,
			BackgroundTransparency = 0.06,
			Size = UDim2.new(1, -10, 0, 92),
			Position = UDim2.fromOffset(5, 5),
			ZIndex = 3,
			Parent = Page,
		})
		Corner(Header, UDim.new(0, 14))
		Stroke(Header, 0.8, 1, THEME.SoftStroke)

		local HeaderIconWrap = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(42, 42),
			Position = UDim2.fromOffset(18, 20),
			ZIndex = 4,
			Parent = Header,
		})
		local fallbackTitleIcon = tabIcon and tab.Icon or "lightbulb"
		local HeaderIcon = MakeIcon(HeaderIconWrap, fallbackTitleIcon, UDim2.fromOffset(32, 32), THEME.Warn, "lucide")
		if not HeaderIcon then
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "💡",
				TextColor3 = THEME.Warn,
				TextSize = 28,
				Font = Enum.Font.GothamBold,
				ZIndex = 4,
				Parent = HeaderIconWrap,
			})
		end

		local HeaderTitle = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -80, 0, 26),
			Position = UDim2.fromOffset(68, 22),
			Text = (tab.Title == "Lighting" and "Lighting" or tab.Title),
			TextColor3 = THEME.Text,
			TextSize = 24,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 4,
			Parent = Header,
		})

		local HeaderSub = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -80, 0, 18),
			Position = UDim2.fromOffset(68, 48),
			Text = tab.Title == "Lighting" and "View and adjust properties of lighting." or "View and adjust properties.",
			TextColor3 = THEME.SubText,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 4,
			Parent = Header,
		})

		local Scroll = New("ScrollingFrame", {
			Name = "ElementScroll",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -10, 1, -104),
			Position = UDim2.fromOffset(5, 100),
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = 4,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.None,
			ZIndex = 3,
			Parent = Page,
		})
		Pad(Scroll, 4, 4, 4, 4)

		local Layout = New("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = Scroll,
		})
		MakeCanvasUpdater(Scroll, Layout)

		tab.Button = Button
		tab.ButtonIndicator = Indicator
		tab.Page = Page
		tab.Scroll = Scroll
		tab.NameLabel = TabName

		local function registerElement(root, searchText, descText)
			local item = {
				Root = root,
				SearchText = searchText or "",
				DescText = descText or "",
			}
			table.insert(tab._searchItems, item)
			table.insert(tab.Elements, root)
			refreshTabSearch(tab)
			return item
		end

		function tab:CreateButton(btnConfig)
			btnConfig = btnConfig or {}
			local Title = btnConfig.Title or "Button"
			local Locked = btnConfig.Locked or false
			local Callback = btnConfig.Callback

			local Root = createElementCard(Scroll, 42)
			local Btn = New("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 5,
				Parent = Root,
			})

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -18, 1, 0),
				Position = UDim2.fromOffset(14, 0),
				Text = Title,
				TextColor3 = Locked and Color3.fromRGB(135, 150, 140) or THEME.Text,
				TextSize = 14,
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 6,
				Parent = Btn,
			})

			if Locked then
				Root.BackgroundTransparency = 0.28
			end

			Btn.MouseEnter:Connect(function()
				if not Locked then
					Tween(Root, TweenInfo.new(0.15), { BackgroundTransparency = 0.06 })
				end
			end)
			Btn.MouseLeave:Connect(function()
				if not Locked then
					Tween(Root, TweenInfo.new(0.15), { BackgroundTransparency = 0.14 })
				end
			end)
			Btn.MouseButton1Click:Connect(function()
				if Locked then return end
				SafeCall(Callback)
			end)

			registerElement(Root, Title, "")
			return Root
		end

		function tab:CreateToggle(togConfig)
			togConfig = togConfig or {}
			local Title = togConfig.Title or "Toggle"
			local Desc = togConfig.Desc or ""
			local Value = togConfig.Value or false
			local Callback = togConfig.Callback

			local Root = createElementCard(Scroll, 54)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -70, 0, 18),
				Position = UDim2.fromOffset(14, 10),
				Text = Title,
				TextColor3 = THEME.Text,
				TextSize = 14,
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 5,
				Parent = Root,
			})

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -70, 0, 14),
				Position = UDim2.fromOffset(14, 28),
				Text = Desc,
				TextColor3 = THEME.SubText,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 5,
				Parent = Root,
			})

			local Switch = New("TextButton", {
				BackgroundColor3 = Value and THEME.BlueSelect or Color3.fromRGB(52, 56, 66),
				BackgroundTransparency = 0.05,
				Size = UDim2.fromOffset(46, 24),
				Position = UDim2.new(1, -58, 0, 15),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 5,
				Parent = Root,
			})
			Corner(Switch, UDim.new(1, 0))

			local Knob = New("Frame", {
				BackgroundColor3 = Color3.fromRGB(246, 248, 252),
				Size = UDim2.fromOffset(18, 18),
				Position = Value and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
				ZIndex = 6,
				Parent = Switch,
			})
			Corner(Knob, UDim.new(1, 0))

			local function setState(state)
				Value = state
				Tween(Switch, TweenInfo.new(0.16), {
					BackgroundColor3 = state and THEME.BlueSelect or Color3.fromRGB(52, 56, 66),
				})
				Tween(Knob, TweenInfo.new(0.16), {
					Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
				})
				SafeCall(Callback, state)
			end

			Switch.MouseButton1Click:Connect(function()
				setState(not Value)
			end)

			registerElement(Root, Title, Desc)
			return {
				Set = setState,
				Get = function()
					return Value
				end,
				Root = Root,
			}
		end

		function tab:CreateSlider(sldConfig)
			sldConfig = sldConfig or {}
			local Title = sldConfig.Title or "Slider"
			local Step = tonumber(sldConfig.Step) or 1
			local Min = tonumber(sldConfig.Value and sldConfig.Value.Min) or 0
			local Max = tonumber(sldConfig.Value and sldConfig.Value.Max) or 100
			local Value = tonumber(sldConfig.Value and sldConfig.Value.Default) or Min
			local Callback = sldConfig.Callback

			local Root = createElementCard(Scroll, 66)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 0, 18),
				Position = UDim2.fromOffset(14, 9),
				Text = Title,
				TextColor3 = THEME.Text,
				TextSize = 14,
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 5,
				Parent = Root,
			})

			local ValueLbl = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(84, 18),
				Position = UDim2.new(1, -96, 0, 9),
				Text = tostring(Value),
				TextColor3 = THEME.SubText,
				TextSize = 13,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 5,
				Parent = Root,
			})

			local Bar = New("Frame", {
				BackgroundColor3 = Color3.fromRGB(52, 56, 66),
				BackgroundTransparency = 0.08,
				Size = UDim2.new(1, -28, 0, 8),
				Position = UDim2.fromOffset(14, 39),
				ZIndex = 5,
				Parent = Root,
			})
			Corner(Bar, UDim.new(1, 0))

			local Fill = New("Frame", {
				BackgroundColor3 = THEME.BlueSelect,
				Size = UDim2.fromScale(0, 1),
				ZIndex = 6,
				Parent = Bar,
			})
			Corner(Fill, UDim.new(1, 0))

			local Knob = New("Frame", {
				BackgroundColor3 = Color3.fromRGB(246, 248, 252),
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.new(0, -7, 0.5, -7),
				ZIndex = 7,
				Parent = Bar,
			})
			Corner(Knob, UDim.new(1, 0))

			local Drag = false

			local function setValue(v)
				local stepped = math.floor(((v - Min) / Step) + 0.5) * Step + Min
				stepped = math.clamp(stepped, Min, Max)
				Value = stepped

				local alpha = (Value - Min) / math.max((Max - Min), 0.0001)
				Fill.Size = UDim2.new(alpha, 0, 1, 0)
				Knob.Position = UDim2.new(alpha, -7, 0.5, -7)
				ValueLbl.Text = tostring(Value)

				SafeCall(Callback, Value)
			end

			local function updateFromX(x)
				local rel = math.clamp((x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
				setValue(Min + ((Max - Min) * rel))
			end

			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Drag = true
					updateFromX(input.Position.X)
				end
			end)
			Bar.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Drag = false
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if Drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromX(input.Position.X)
				end
			end)

			setValue(Value)
			registerElement(Root, Title, "")
			return {
				Set = setValue,
				Get = function()
					return Value
				end,
				Root = Root,
			}
		end

		function tab:CreateInput(inpConfig)
			inpConfig = inpConfig or {}
			local Title = inpConfig.Title or "Input"
			local Value = inpConfig.Value or ""
			local Placeholder = inpConfig.Placeholder or "Enter text..."
			local Callback = inpConfig.Callback

			local Root = createElementCard(Scroll, 58)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 0, 18),
				Position = UDim2.fromOffset(14, 8),
				Text = Title,
				TextColor3 = THEME.Text,
				TextSize = 14,
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 5,
				Parent = Root,
			})

			local Box = New("TextBox", {
				BackgroundColor3 = THEME.BG3,
				BackgroundTransparency = 0.1,
				Size = UDim2.new(1, -28, 0, 24),
				Position = UDim2.fromOffset(14, 30),
				Text = Value,
				PlaceholderText = Placeholder,
				ClearTextOnFocus = false,
				TextColor3 = THEME.Text,
				PlaceholderColor3 = THEME.SubText,
				TextSize = 13,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 6,
				Parent = Root,
			})
			Corner(Box, UDim.new(0, 8))
			Stroke(Box, 0.78, 1, THEME.SoftStroke)
			Pad(Box, 10, 10, 0, 0)

			Box.FocusLost:Connect(function(enterPressed)
				if enterPressed then
					Value = Box.Text
					SafeCall(Callback, Box.Text)
				end
			end)

			registerElement(Root, Title, "")
			return {
				Set = function(text)
					Value = tostring(text or "")
					Box.Text = Value
				end,
				Get = function()
					return Box.Text
				end,
				Root = Root,
			}
		end

		function tab:CreateDropdown(ddConfig)
			ddConfig = ddConfig or {}
			local Title = ddConfig.Title or "Dropdown"
			local Values = ddConfig.Values or {}
			local Current = ddConfig.Value or (Values[1] or "")
			local Callback = ddConfig.Callback

			local Root = createElementCard(Scroll, 46)
			local Btn = New("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 5,
				Parent = Root,
			})

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -70, 0, 18),
				Position = UDim2.fromOffset(14, 6),
				Text = Title,
				TextColor3 = THEME.Text,
				TextSize = 14,
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 6,
				Parent = Btn,
			})

			local ValueLbl = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -34, 0, 14),
				Position = UDim2.fromOffset(14, 23),
				Text = tostring(Current),
				TextColor3 = THEME.SubText,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 6,
				Parent = Btn,
			})

			local ArrowWrap = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.new(1, -28, 0.5, -9),
				ZIndex = 6,
				Parent = Btn,
			})
			local ArrowIcon = MakeIcon(ArrowWrap, "chevron-down", UDim2.fromOffset(14, 14), THEME.Text, "lucide")
			if not ArrowIcon then
				New("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Text = "⌄",
					TextColor3 = THEME.Text,
					TextSize = 16,
					Font = Enum.Font.GothamBold,
					ZIndex = 6,
					Parent = ArrowWrap,
				})
			end

			local DropdownPopup = New("Frame", {
				Name = "DropdownPopup",
				BackgroundColor3 = THEME.BG2,
				BackgroundTransparency = 0.02,
				Size = UDim2.fromOffset(330, 258),
				Position = UDim2.new(0.5, -165, 0.5, -129),
				Visible = false,
				ZIndex = 50,
				Parent = Main,
			})
			Corner(DropdownPopup, UDim.new(0, 12))
			Stroke(DropdownPopup, 0.35, 1, THEME.Accent)

			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 0, 24),
				Position = UDim2.fromOffset(12, 10),
				Text = Title,
				TextColor3 = THEME.Text,
				TextSize = 15,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 51,
				Parent = DropdownPopup,
			})

			local PopupSearch = New("TextBox", {
				BackgroundColor3 = THEME.BG3,
				BackgroundTransparency = 0.1,
				Size = UDim2.new(1, -24, 0, 28),
				Position = UDim2.fromOffset(12, 42),
				Text = "",
				PlaceholderText = "Search...",
				ClearTextOnFocus = false,
				TextColor3 = THEME.Text,
				PlaceholderColor3 = THEME.SubText,
				TextSize = 13,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 51,
				Parent = DropdownPopup,
			})
			Corner(PopupSearch, UDim.new(0, 8))
			Stroke(PopupSearch, 0.78, 1, THEME.SoftStroke)
			Pad(PopupSearch, 10, 10, 0, 0)

			local PopupScroll = New("ScrollingFrame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -16, 1, -82),
				Position = UDim2.fromOffset(8, 76),
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, 0),
				ScrollBarThickness = 4,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.None,
				ZIndex = 51,
				Parent = DropdownPopup,
			})

			local PopupLayout = New("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = PopupScroll,
			})
			Pad(PopupScroll, 4, 4, 4, 4)
			MakeCanvasUpdater(PopupScroll, PopupLayout)

			local openState = false
			local optionButtons = {}

			local function closePopup()
				openState = false
				DropdownPopup.Visible = false
			end

			local function openPopup()
				openState = true
				DropdownPopup.Visible = true
				DropdownPopup.Size = UDim2.fromOffset(306, 238)
				Tween(DropdownPopup, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.fromOffset(320, 250),
				})
				PopupSearch.Text = ""
				task.defer(function()
					PopupSearch:CaptureFocus()
				end)
			end

			local function applyFilter()
				local q = string.lower(PopupSearch.Text or "")
				for _, item in ipairs(optionButtons) do
					local show = q == "" or string.find(string.lower(item.Value), q, 1, true) ~= nil
					item.Root.Visible = show
				end
			end

			local function buildOptions(values)
				for _, child in ipairs(PopupScroll:GetChildren()) do
					if child:IsA("Frame") then
						child:Destroy()
					end
				end
				table.clear(optionButtons)

				for _, opt in ipairs(values) do
					local OptBtn = New("TextButton", {
						BackgroundColor3 = THEME.BG2,
						BackgroundTransparency = 0.16,
						Size = UDim2.new(1, -4, 0, 34),
						Text = "",
						AutoButtonColor = false,
						ZIndex = 52,
						Parent = PopupScroll,
					})
					Corner(OptBtn, UDim.new(0, 9))
					Stroke(OptBtn, 0.8, 1, THEME.SoftStroke)

					New("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -18, 1, 0),
						Position = UDim2.fromOffset(12, 0),
						Text = tostring(opt),
						TextColor3 = THEME.Text,
						TextSize = 13,
						Font = Enum.Font.GothamSemibold,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 53,
						Parent = OptBtn,
					})

					OptBtn.MouseEnter:Connect(function()
						Tween(OptBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.06 })
					end)
					OptBtn.MouseLeave:Connect(function()
						Tween(OptBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.16 })
					end)

					OptBtn.MouseButton1Click:Connect(function()
						Current = tostring(opt)
						ValueLbl.Text = Current
						SafeCall(Callback, Current)
						closePopup()
					end)

					table.insert(optionButtons, {
						Root = OptBtn,
						Value = tostring(opt),
					})
				end

				applyFilter()
			end

			buildOptions(Values)
			PopupSearch:GetPropertyChangedSignal("Text"):Connect(applyFilter)

			Btn.MouseButton1Click:Connect(function()
				if openState then
					closePopup()
				else
					openPopup()
				end
			end)

			local dropdown = {
				Root = Root,
				Button = Btn,
				ValueLabel = ValueLbl,
				Popup = DropdownPopup,
				Refresh = function(_, newValues)
					Values = newValues or {}
					buildOptions(Values)
				end,
				Set = function(_, value)
					Current = tostring(value or "")
					ValueLbl.Text = Current
					SafeCall(Callback, Current)
				end,
				Get = function()
					return Current
				end,
			}

			registerElement(Root, Title, tostring(Current))
			return dropdown
		end

		Button.MouseButton1Click:Connect(function()
			selectTab(tab)
		end)

		table.insert(window.Tabs, tab)
		if not window.ActiveTab then
			selectTab(tab)
		end

		return tab
	end

	function window:Destroy()
		if self._destroyed then
			return
		end
		self._destroyed = true
		if FloatingGui then
			FloatingGui:Destroy()
			FloatingGui = nil
		end
		if ScreenGui then
			ScreenGui:Destroy()
		end
	end

	function window:SetVisible(state)
		setVisible(state)
	end

	function window:Toggle()
		if self._destroyed then
			return
		end
		if Main.Visible then
			closeAnim()
			setVisible(false)
			if FloatingGui then
				FloatingGui.Enabled = true
			end
		else
			setVisible(true)
			openAnim()
		end
	end

	function window:_ApplySearch(text)
		if SearchBox then
			SearchBox.Text = text or ""
		end
		applySearch(text or "")
	end

	function window:_GetGui()
		return ScreenGui
	end

	function window:_GetMain()
		return Main
	end

	return setmetatable(window, {
		__index = BTUI,
	})
end

function BTUI.SetIconModule(module)
	IconModule = module
end

return BTUI
