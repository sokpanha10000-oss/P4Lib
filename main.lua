--========================================================
-- DarkyUI
-- Clean single-file Roblox UI library
--========================================================
-- Features:
--   • 550x340 main window
--   • PC + mobile window dragging
--   • Draggable floating minimize/restore button
--   • Square corners
--   • Search bar
--   • Profile + username
--   • Lucide icon names + Roblox asset IDs
--   • Tabs with scrolling
--   • Auto-sized independent sections (NO section Size option)
--   • Automatic page scrolling only when content overflows
--   • Button / Toggle / Slider / Input / Dropdown
--   • Centered searchable dropdown popup
--   • Themes: Red / BlueSky / White / Yellow / Green / Purple / Orange
--   • Theme affects toggle + slider + KeySystem accent only
--   • Notification automatically uses Window.Image
--   • KeySystem can be created BEFORE CreateWindow
--   • Optional saved key
--========================================================

local DarkyUI = {}

--========================================================
-- SERVICES
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ContentProvider = game:GetService("ContentProvider")
local LocalPlayer = Players.LocalPlayer

--========================================================
-- CONSTANTS
--========================================================

local WINDOW_WIDTH = 550
local WINDOW_HEIGHT = 340

local MAIN_GUI_NAME = "DarkyUI_Main"
local KEY_GUI_NAME = "DarkyUI_KeySystem"
local NOTIFY_GUI_NAME = "DarkyUI_Notifications"

local COLORS = {
    Background = Color3.fromRGB(18, 18, 21),
    Background2 = Color3.fromRGB(23, 23, 27),
    Panel = Color3.fromRGB(29, 29, 34),
    Panel2 = Color3.fromRGB(35, 35, 41),

    Text = Color3.fromRGB(245, 245, 247),
    SubText = Color3.fromRGB(160, 160, 170),
    Muted = Color3.fromRGB(105, 105, 115),

    Border = Color3.fromRGB(52, 52, 61),
    Danger = Color3.fromRGB(235, 75, 85),
    Info = Color3.fromRGB(70, 125, 255),
    Warning = Color3.fromRGB(245, 185, 70),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local THEMES = {
    Red = {
        Accent = Color3.fromRGB(225, 65, 75),
        Accent2 = Color3.fromRGB(245, 95, 105),
    },

    BlueSky = {
        Accent = Color3.fromRGB(70, 125, 255),
        Accent2 = Color3.fromRGB(95, 150, 255),
    },

    White = {
        Accent = Color3.fromRGB(205, 205, 212),
        Accent2 = Color3.fromRGB(245, 245, 250),
    },

    Yellow = {
        Accent = Color3.fromRGB(235, 180, 45),
        Accent2 = Color3.fromRGB(255, 210, 70),
    },

    Green = {
        Accent = Color3.fromRGB(55, 190, 105),
        Accent2 = Color3.fromRGB(85, 220, 130),
    },

    Purple = {
        Accent = Color3.fromRGB(140, 85, 225),
        Accent2 = Color3.fromRGB(170, 110, 255),
    },

    Orange = {
        Accent = Color3.fromRGB(235, 120, 45),
        Accent2 = Color3.fromRGB(255, 150, 65),
    },
}

DarkyUI.Themes = THEMES
DarkyUI.CurrentTheme = "BlueSky"
DarkyUI.CurrentImage = nil
DarkyUI._Window = nil
DarkyUI._KeySystem = nil
DarkyUI._KeyPassed = false
DarkyUI._ThemeObjects = {}

local FAST = TweenInfo.new(
    0.14,
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

local MED = TweenInfo.new(
    0.22,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.Out
)

--========================================================
-- HELPERS
--========================================================

local function New(className, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    return object
end

local function Tween(object, info, properties)
    if not object or not object.Parent then
        return nil
    end

    local tween = TweenService:Create(
        object,
        info,
        properties
    )

    tween:Play()

    return tween
end

-- Roblox never errors on a bad/invalid/moderated rbxassetid:// - the
-- ImageLabel just silently renders blank with no feedback. This checks
-- whether the asset actually loaded and, if not, hands back control via
-- onFailed so the caller can fall back to a placeholder (e.g. initials).
-- Runs off-thread so it never blocks UI creation.
local function VerifyImageLoad(imageLabel, onFailed)
    if not imageLabel then
        return
    end

    task.spawn(function()
        local ok, contentId = pcall(function()
            return imageLabel.Image
        end)

        if not ok or not contentId or contentId == "" then
            return
        end

        local success, result = pcall(function()
            ContentProvider:PreloadAsync({ imageLabel })
            return imageLabel.IsLoaded
        end)

        local loaded = success and (result == nil or result == true)

        if not loaded then
            if imageLabel.Parent and typeof(onFailed) == "function" then
                pcall(onFailed)
            end
        end
    end)
end

local function Stroke(parent, color, thickness)
    return New("UIStroke", {
        Parent = parent,
        Color = color or COLORS.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Padding(parent, left, right, top, bottom)
    return New("UIPadding", {
        Parent = parent,
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    })
end

local function AssetId(value)
    if typeof(value) == "number" then
        return "rbxassetid://" .. tostring(value)
    end

    if typeof(value) ~= "string" then
        return nil
    end

    if value:match("^rbxassetid://") then
        return value
    end

    if value:match("^%d+$") then
        return "rbxassetid://" .. value
    end

    return value
end

local function IsAssetId(value)
    if typeof(value) ~= "string" then
        return false
    end

    return value:match("^rbxassetid://") ~= nil
        or value:match("^%d+$") ~= nil
end

local function AddCorner(parent, radius)
    if not parent then return nil end
    local old = parent:FindFirstChildOfClass("UICorner")
    if old then old:Destroy() end
    return New("UICorner", { Parent = parent, CornerRadius = UDim.new(0, radius or 10) })
end

local function CreateAuraFor(gui, target, colorProvider, options)
    options = options or {}
    if not gui or not target then return nil end
    local expand = options.Expand or 18
    local aura = New("Frame", {
        Parent = gui, Name = options.Name or "Aura",
        AnchorPoint = target.AnchorPoint, Position = target.Position,
        Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset + expand, target.Size.Y.Scale, target.Size.Y.Offset + expand),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = target.Visible, ZIndex = math.max((target.ZIndex or 1) - 2, 0),
    })
    AddCorner(aura, (options.Radius or 12) + 8)
    local strokes = {}
    local layers = options.Layers or 6
    local thickness = options.Thickness or 5
    local transparency = options.Transparency or 0.78
    for i = 1, layers do
        strokes[i] = New("UIStroke", {
            Parent = aura, Color = colorProvider(),
            Thickness = thickness + ((layers - i) * 3),
            Transparency = math.clamp(transparency + ((i - 1) * 0.035), 0, 1),
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
    end
    local function sync()
        if not aura.Parent or not target.Parent then return false end
        aura.AnchorPoint = target.AnchorPoint; aura.Position = target.Position
        aura.Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset + expand, target.Size.Y.Scale, target.Size.Y.Offset + expand)
        aura.Visible = target.Visible; aura.Rotation = target.Rotation
        return true
    end
    local connections = {
        target:GetPropertyChangedSignal("Position"):Connect(sync),
        target:GetPropertyChangedSignal("Size"):Connect(sync),
        target:GetPropertyChangedSignal("Visible"):Connect(sync),
        target:GetPropertyChangedSignal("Rotation"):Connect(sync),
    }
    local object = { Root = aura, Strokes = strokes }
    function object:SetColor(color)
        for _, stroke in ipairs(strokes) do if stroke.Parent then stroke.Color = color end end
    end
    function object:SetVisible(value) aura.Visible = value == true end
    function object:Destroy()
        for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
        if aura then aura:Destroy() end
    end
    sync(); return object
end

--========================================================
-- HTTP / LOADSTRING
--========================================================

local function HttpGet(url)
    local methods = {
        function()
            return game:HttpGet(url)
        end,

        function()
            return request({
                Url = url,
                Method = "GET",
            }).Body
        end,

        function()
            return http_request({
                Url = url,
                Method = "GET",
            }).Body
        end,
    }

    for _, method in ipairs(methods) do
        local success, result = pcall(method)

        if success and result and result ~= "" then
            return result
        end
    end

    return nil
end

local function GetLoadstring()
    if typeof(loadstring) == "function" then
        return loadstring
    end

    if typeof(load) == "function" then
        return load
    end

    return nil
end

--========================================================
-- LUCIDE
--========================================================

local LUCIDE_URL =
    "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"

local function LoadLucide()
    local env = {}

    pcall(function()
        if typeof(getgenv) == "function" then
            env = getgenv()
        end
    end)

    -- Supports the user's IsUI / Loadstring / Get environment.
    if env.IsUI and env.Loadstring and env.Get then
        local success, result = pcall(function()
            return env.Loadstring(
                env.Get(LUCIDE_URL)
            )()
        end)

        if success and type(result) == "table" then
            return result
        end
    end

    local source = HttpGet(LUCIDE_URL)
    local loader = GetLoadstring()

    if source and loader then
        local success, result = pcall(function()
            return loader(source)()
        end)

        if success and type(result) == "table" then
            return result
        end
    end

    return {}
end

DarkyUI.Icons = {
    lucide = LoadLucide(),
}

-- Returns asset, isGlyph.
-- isGlyph = true only for resolved lucide icon names (monochrome glyphs,
-- safe to tint). Direct rbxassetid/rbxasset/http(s) images are real
-- pictures and must NOT be tinted, or their colors get washed out/hidden.
local function ResolveIcon(icon)
    if icon == nil then
        return nil, false
    end

    if typeof(icon) == "number" then
        return AssetId(icon), false
    end

    if typeof(icon) ~= "string" then
        return nil, false
    end

    if IsAssetId(icon) then
        return AssetId(icon), false
    end

    if icon:match("^https?://") then
        return icon, false
    end

    if icon:match("^rbxasset") then
        return icon, false
    end

    local direct = DarkyUI.Icons.lucide[icon]

    if direct then
        return AssetId(tostring(direct)), true
    end

    local lower = icon:lower()

    for name, value in pairs(DarkyUI.Icons.lucide) do
        if tostring(name):lower() == lower then
            return AssetId(tostring(value)), true
        end
    end

    return nil, false
end

--========================================================
-- THEME
--========================================================
-- Declared here (ahead of Icon below) since themed icons need to
-- register for live theme-change updates.

local function CurrentTheme()
    return THEMES[DarkyUI.CurrentTheme]
        or THEMES.BlueSky
end

local function RegisterTheme(callback)
    table.insert(
        DarkyUI._ThemeObjects,
        callback
    )

    pcall(function()
        callback(
            DarkyUI.CurrentTheme,
            CurrentTheme()
        )
    end)
end

-- themed: false/nil = static COLORS.Text icon (default, unchanged behavior).
--         true      = tinted with the current theme's Accent color, and
--                      automatically re-tints whenever the theme changes.
--         "Accent2" = same as true, but follows Accent2 instead of Accent.
local function Icon(parent, icon, size, position, zIndex, themed)
    local asset, isGlyph = ResolveIcon(icon)

    if not asset then
        return nil
    end

    local image = New("ImageLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Position = position,
        Size = UDim2.fromOffset(size, size),
        Image = asset,
        ImageColor3 = isGlyph and COLORS.Text or COLORS.White,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = zIndex or 10,
    })

    -- Only tint lucide glyphs live with the theme; a real custom image
    -- (rbxassetid/rbxasset/http) is left as-is regardless of `themed`.
    if themed and isGlyph then
        local colorKey = themed == "Accent2" and "Accent2" or "Accent"

        RegisterTheme(function(_, colors)
            if image and image.Parent then
                image.ImageColor3 = colors[colorKey]
            end
        end)
    end

    return image
end

--========================================================
-- VISUAL DESIGN HELPERS
--========================================================

local function AddTopAccent(parent)
    return New("Frame", {
        Parent = parent,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = COLORS.Border,
        BorderSizePixel = 0,
        ZIndex = 29,
    })
end

local function AddSectionAccent(parent)
    return New("Frame", {
        Parent = parent,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(2, 20),
        BackgroundColor3 = COLORS.Border,
        BorderSizePixel = 0,
        ZIndex = 15,
    })
end

function DarkyUI:SetTheme(name)
    if type(name) ~= "string" then
        return false
    end

    local selected

    for themeName in pairs(THEMES) do
        if themeName:lower() == name:lower() then
            selected = themeName
            break
        end
    end

    if not selected then
        return false
    end

    DarkyUI.CurrentTheme = selected

    local colors = CurrentTheme()

    for index = #DarkyUI._ThemeObjects, 1, -1 do
        local callback = DarkyUI._ThemeObjects[index]

        if type(callback) == "function" then
            local success = pcall(
                callback,
                selected,
                colors
            )

            if not success then
                table.remove(
                    DarkyUI._ThemeObjects,
                    index
                )
            end
        else
            table.remove(
                DarkyUI._ThemeObjects,
                index
            )
        end
    end

    return true
end

DarkyUI.Theme = DarkyUI.SetTheme

--========================================================
-- NOTIFICATIONS
--========================================================

function DarkyUI:Notify(config)
    config = config or {}

    local title = tostring(
        config.Title or "DarkyUI"
    )

    local content = tostring(
        config.Content or ""
    )

    local duration = tonumber(
        config.Duration
    ) or 3

    if duration < 0 then
        duration = 0
    end

    local gui = CoreGui:FindFirstChild(
        NOTIFY_GUI_NAME
    )

    if not gui then
        gui = New(
            "ScreenGui",
            {
                Name = NOTIFY_GUI_NAME,
                Parent = CoreGui,
                IgnoreGuiInset = true,
                ResetOnSpawn = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder = 2100000,
            }
        )
    end

    local holder = gui:FindFirstChild("Holder")

    if not holder then
        holder = New(
            "Frame",
            {
                Parent = gui,
                Name = "Holder",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -16, 0, 16),
                Size = UDim2.new(0, 330, 1, -32),
                BackgroundTransparency = 1,
                ZIndex = 3000,
            }
        )

        New(
            "UIListLayout",
            {
                Parent = holder,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            }
        )
    end

    local notification = New(
        "Frame",
        {
            Parent = holder,
            Size = UDim2.fromOffset(310, 70),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 3001,
        }
    )

    AddCorner(notification, 12)

    Stroke(
        notification,
        COLORS.Border,
        1
    )

    local accent = New(
        "Frame",
        {
            Parent = notification,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(3, 70),
            BackgroundColor3 = CurrentTheme().Accent,
            BorderSizePixel = 0,
            ZIndex = 3002,
        }
    )

    local image = DarkyUI.CurrentImage

    -- The Window image is automatically reused.
    if image ~= nil then
        local imageObject = Icon(
            notification,
            image,
            40,
            UDim2.fromOffset(10, 15),
            3003
        )

        if not imageObject then
            local asset = AssetId(image)

            if asset then
                New(
                    "ImageLabel",
                    {
                        Parent = notification,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(10, 15),
                        Size = UDim2.fromOffset(40, 40),
                        Image = asset,
                        ScaleType = Enum.ScaleType.Crop,
                        ZIndex = 3003,
                    }
                )
            end
        end
    end

    local textLeft = image ~= nil
        and 60
        or 14

    local titleLabel = New(
        "TextLabel",
        {
            Parent = notification,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(textLeft, 8),
            Size = UDim2.new(1, -textLeft - 14, 0, 20),
            Text = title,
            TextColor3 = COLORS.Text,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 3004,
        }
    )

    local contentLabel = New(
        "TextLabel",
        {
            Parent = notification,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(textLeft, 29),
            Size = UDim2.new(1, -textLeft - 14, 0, 33),
            Text = content,
            TextColor3 = COLORS.SubText,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 3004,
        }
    )

    notification.Position = UDim2.new(
        1,
        320,
        0,
        0
    )

    Tween(
        notification,
        MED,
        {
            Position = UDim2.new(
                1,
                0,
                0,
                0
            )
        }
    )

    task.delay(
        duration,
        function()
            if not notification
                or not notification.Parent then
                return
            end

            local tween = Tween(
                notification,
                MED,
                {
                    Position = UDim2.new(
                        1,
                        320,
                        0,
                        0
                    )
                }
            )

            if tween then
                tween.Completed:Connect(
                    function()
                        if notification then
                            notification:Destroy()
                        end
                    end
                )
            else
                notification:Destroy()
            end
        end
    )

    return notification
end

--========================================================
-- KEY SYSTEM
--========================================================

local function SafeClipboard(text)
    local methods = {
        function()
            setclipboard(text)
        end,

        function()
            toclipboard(text)
        end,

        function()
            if syn and syn.clipboard then
                syn.clipboard = text
            else
                error("clipboard unavailable")
            end
        end,
    }

    for _, method in ipairs(methods) do
        local success = pcall(method)

        if success then
            return true
        end
    end

    return false
end

local function MakeKeySystem(config)
    config = config or {}

    local KeySystem = {
        Destroyed = false,
        Cancelled = false,
    }

    local title = tostring(
        config.Title or "Access Required"
    )

    local note = tostring(
        config.Note or ""
    )

    local keyURL = tostring(
        config.URL or ""
    )

    local saveKey =
        config.SaveKey == true

    -- Thumbnail accepts either the documented table shape
    -- ({ Image = "rbxassetid://...", Title = "..." }) or a bare
    -- image value (rbxassetid string/number, rbxasset://, or
    -- http(s) URL) passed directly as config.Thumbnail, so a plain
    -- id doesn't silently fail to show.
    local thumbnail = config.Thumbnail or {}

    if typeof(thumbnail) == "string"
        or typeof(thumbnail) == "number" then
        thumbnail = { Image = thumbnail }
    end

    -- Border/Blur: connect to the Window's settings.
    -- Explicit config.Border/config.Blur always win. Otherwise, if a
    -- Window already exists (KeySystem created AFTER CreateWindow),
    -- inherit its Border/Blur so both stay visually consistent.
    -- Falls back to false, same default as Window.
    local existingWindow =
        DarkyUI._Window
        and not DarkyUI._Window.Destroyed
        and DarkyUI._Window
        or nil

    local useBorder
    if config.Border ~= nil then
        useBorder = config.Border == true
    elseif existingWindow then
        useBorder = existingWindow.Border == true
    else
        useBorder = false
    end

    local useBlur
    if config.Blur ~= nil then
        useBlur = config.Blur == true
    elseif existingWindow then
        useBlur = existingWindow.Blur == true
    else
        useBlur = false
    end

    KeySystem.Border = useBorder
    KeySystem.Blur = useBlur

    local fileName =
        "DarkyUI_Key.txt"

    -- Create the KeySystem first and keep it independent from the hub GUI.
    local oldGui = CoreGui:FindFirstChild(
        KEY_GUI_NAME
    )

    if oldGui then
        oldGui:Destroy()
    end

    local gui = New(
        "ScreenGui",
        {
            Name = KEY_GUI_NAME,
            Parent = CoreGui,
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 3000000,
        }
    )

    KeySystem.Gui = gui

    local overlay = New(
        "Frame",
        {
            Parent = gui,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = COLORS.Black,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            ZIndex = 2000,
        }
    )

    local main = New(
        "Frame",
        {
            Parent = overlay,
            Name = "Main",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(500, 280),
            BackgroundColor3 = COLORS.Background,
            BorderSizePixel = 0,
            ZIndex = 2001,
        }
    )

    AddCorner(main, 12)
    local keyStroke = Stroke(
        main,
        KeySystem.Border and CurrentTheme().Accent or COLORS.Border,
        1
    )
    keyStroke.Transparency = KeySystem.Border and 0 or 1

    local keyAura
    if KeySystem.Blur then
        keyAura = CreateAuraFor(gui, main, function() return CurrentTheme().Accent end, {
            Name = "KeyAura", Expand = 16, Radius = 12, Layers = 5, Thickness = 4, Transparency = 0.80
        })
    end
    KeySystem.Aura = keyAura

    RegisterTheme(function(_, colors)
        if keyStroke and keyStroke.Parent then
            keyStroke.Color = KeySystem.Border and colors.Accent or COLORS.Border
            keyStroke.Transparency = KeySystem.Border and 0 or 1
        end
        if keyAura and keyAura.Root and keyAura.Root.Parent then keyAura:SetColor(colors.Accent) end
    end)

    --====================================================
    -- HEADER
    --====================================================

    local header = New(
        "Frame",
        {
            Parent = main,
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.new(1, -2, 0, 55),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ZIndex = 2002,
        }
    )

    AddCorner(header, 11)

    New(
        "Frame",
        {
            Parent = header,
            Name = "CornerMask",
            Position = UDim2.new(0, 0, 1, -11),
            Size = UDim2.new(1, 0, 0, 11),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ZIndex = 2002,
        }
    )

    Stroke(header, COLORS.Border, 1)

    New(
        "TextLabel",
        {
            Parent = header,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(15, 7),
            Size = UDim2.new(1, -30, 0, 22),
            Text = title,
            TextColor3 = COLORS.Text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2003,
        }
    )

    New(
        "TextLabel",
        {
            Parent = header,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(15, 30),
            Size = UDim2.new(1, -30, 0, 17),
            Text = note,
            TextColor3 = COLORS.SubText,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2003,
        }
    )

    --====================================================
    -- LEFT THUMBNAIL
    --====================================================

    local left = New(
        "Frame",
        {
            Parent = main,
            Position = UDim2.fromOffset(13, 68),
            Size = UDim2.fromOffset(150, 132),
            BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0,
            ZIndex = 2003,
        }
    )

    Stroke(left, COLORS.Border, 1)

    local thumbAsset =
        thumbnail.Image
            and AssetId(thumbnail.Image)

    if thumbAsset then
        local image = New(
            "ImageLabel",
            {
                Parent = left,
                Position = UDim2.fromOffset(7, 7),
                Size = UDim2.new(1, -14, 0, 92),
                BackgroundColor3 = COLORS.Panel2,
                BorderSizePixel = 0,
                Image = thumbAsset,
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 2004,
            }
        )

        Stroke(image, COLORS.Border, 1)
    else
        New(
            "TextLabel",
            {
                Parent = left,
                Position = UDim2.fromOffset(7, 7),
                Size = UDim2.new(1, -14, 0, 92),
                BackgroundColor3 = COLORS.Panel2,
                BorderSizePixel = 0,
                Text = "KEY",
                TextColor3 = COLORS.Muted,
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                ZIndex = 2004,
            }
        )
    end

    New(
        "TextLabel",
        {
            Parent = left,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(7, 105),
            Size = UDim2.new(1, -14, 0, 20),
            Text = tostring(
                thumbnail.Title
                    or "Premium Member"
            ),
            TextColor3 = COLORS.Text,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 2005,
        }
    )

    --====================================================
    -- RIGHT INPUT AREA
    --====================================================

    local right = New(
        "Frame",
        {
            Parent = main,
            Position = UDim2.fromOffset(174, 68),
            Size = UDim2.new(1, -187, 0, 132),
            BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0,
            ZIndex = 2003,
        }
    )

    Stroke(right, COLORS.Border, 1)

    New(
        "TextLabel",
        {
            Parent = right,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(11, 10),
            Size = UDim2.new(1, -22, 0, 20),
            Text = "Enter your access key",
            TextColor3 = COLORS.Text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2004,
        }
    )

    New(
        "TextLabel",
        {
            Parent = right,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(11, 31),
            Size = UDim2.new(1, -22, 0, 17),
            Text = "Paste your key below to continue.",
            TextColor3 = COLORS.SubText,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2004,
        }
    )

    local inputFrame = New(
        "Frame",
        {
            Parent = right,
            Position = UDim2.fromOffset(10, 58),
            Size = UDim2.new(1, -20, 0, 38),
            BackgroundColor3 = COLORS.Panel2,
            BorderSizePixel = 0,
            ZIndex = 2005,
        }
    )

    Stroke(inputFrame, COLORS.Border, 1)

    local inputIcon = Icon(
        inputFrame,
        "key-round",
        16,
        UDim2.fromOffset(10, 11),
        2006
    )

    if not inputIcon then
        New(
            "TextLabel",
            {
                Parent = inputFrame,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.fromOffset(20, 38),
                Text = "🔑",
                TextSize = 13,
                TextColor3 = CurrentTheme().Accent2,
                Font = Enum.Font.GothamBold,
                ZIndex = 2006,
            }
        )
    end

    local keyInput = New(
        "TextBox",
        {
            Parent = inputFrame,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(34, 0),
            Size = UDim2.new(1, -42, 1, 0),
            PlaceholderText = "Enter key...",
            PlaceholderColor3 = COLORS.Muted,
            Text = "",
            TextColor3 = COLORS.Text,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2006,
        }
    )

    local status = New(
        "TextLabel",
        {
            Parent = main,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(13, 240),
            Size = UDim2.new(1, -26, 0, 18),
            Text = "",
            TextColor3 = COLORS.SubText,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 2007,
        }
    )

    --====================================================
    -- BOTTOM BUTTONS
    --====================================================

    local function KeyButton(x, text, iconName, background)
        local button = New(
            "TextButton",
            {
                Parent = main,
                Position = UDim2.fromOffset(x, 210),
                Size = UDim2.fromOffset(108, 38),
                BackgroundColor3 = background,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 2008,
            }
        )

        Stroke(
            button,
            background == CurrentTheme().Accent
                and CurrentTheme().Accent2
                or COLORS.Border,
            1
        )

        local image = Icon(
            button,
            iconName,
            16,
            UDim2.fromOffset(12, 11),
            2009
        )

        if iconName == "x" and image then
            image.ImageColor3 = COLORS.Danger
        elseif image then
            image.ImageColor3 =
                background == CurrentTheme().Accent
                and COLORS.White
                or COLORS.Text
        end

        New(
            "TextLabel",
            {
                Parent = button,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(36, 0),
                Size = UDim2.new(1, -41, 1, 0),
                Text = text,
                TextColor3 =
                    background == CurrentTheme().Accent
                    and COLORS.White
                    or COLORS.Text,
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 2009,
            }
        )

        return button
    end

    local cancelButton = KeyButton(
        13,
        "Cancel",
        "x",
        COLORS.Panel
    )

    local getKeyButton = KeyButton(
        195,
        "Get Key",
        "key",
        COLORS.Panel
    )

    local submitButton = KeyButton(
        379,
        "Submit",
        "arrow-right",
        CurrentTheme().Accent
    )

    -- Only the accent of the KeySystem changes with the theme.
    RegisterTheme(function(_, colors)
        if not main.Parent then
            return
        end

        submitButton.BackgroundColor3 = colors.Accent

        local stroke = submitButton:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = colors.Accent2
        end

        for _, child in ipairs(submitButton:GetChildren()) do
            if child:IsA("TextLabel") then
                child.TextColor3 = COLORS.White
            elseif child:IsA("ImageLabel") then
                child.ImageColor3 = COLORS.White
            end
        end

        local keyIcon = inputFrame:FindFirstChildOfClass("ImageLabel")
        if keyIcon then
            keyIcon.ImageColor3 = colors.Accent2
        end

        status.TextColor3 = COLORS.SubText
    end)

    AddCorner(left, 10)
    AddCorner(right, 10)
    AddCorner(inputFrame, 8)
    AddCorner(cancelButton, 9)
    AddCorner(getKeyButton, 9)
    AddCorner(submitButton, 9)

    --====================================================
    -- VALIDATION / SAVE
    --====================================================

    local function Validate(key)
        if typeof(config.KeyValidator) ~= "function" then
            return false
        end

        local success, result = pcall(
            config.KeyValidator,
            key
        )

        return success and result == true
    end

    local function SaveKey(key)
        if not saveKey then
            return
        end

        if typeof(writefile) ~= "function" then
            return
        end

        pcall(function()
            writefile(fileName, key)
        end)
    end

    local function ReadKey()
        if not saveKey then
            return nil
        end

        if typeof(isfile) ~= "function"
            or typeof(readfile) ~= "function" then
            return nil
        end

        local exists = false

        pcall(function()
            exists = isfile(fileName)
        end)

        if not exists then
            return nil
        end

        local key

        pcall(function()
            key = readfile(fileName)
        end)

        if key and key ~= "" then
            return key
        end

        return nil
    end

    local function Finish()
        if KeySystem.Destroyed then
            return
        end

        KeySystem.Destroyed = true
        DarkyUI._KeyPassed = true

        local tween = Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(500, 0)
            }
        )

        if tween then
            tween.Completed:Connect(function()
                if gui then
                    gui:Destroy()
                end

                -- Reveal a hub created immediately after CreateKeySystem.
                if DarkyUI._Window
                    and not DarkyUI._Window.Destroyed
                    and DarkyUI._Window._KeyLocked then

                    DarkyUI._Window._KeyLocked = false
                    DarkyUI._Window.Main.Visible = true

                    DarkyUI._Window.Main.Size =
                        UDim2.fromOffset(550, 0)

                    Tween(
                        DarkyUI._Window.Main,
                        MED,
                        {
                            Size = UDim2.fromOffset(
                                WINDOW_WIDTH,
                                WINDOW_HEIGHT
                            )
                        }
                    )
                end
            end)
        else
            if gui then
                gui:Destroy()
            end
        end
    end

    cancelButton.MouseButton1Click:Connect(function()
        KeySystem.Cancelled = true
        KeySystem.Destroyed = true
        DarkyUI._KeyPassed = false

        if gui then
            gui:Destroy()
        end
    end)

    getKeyButton.MouseButton1Click:Connect(function()
        if keyURL == "" then
            status.Text = "Key URL is not configured."
            status.TextColor3 = COLORS.Danger
            return
        end

        local copied = SafeClipboard(keyURL)

        if copied then
            status.Text = "Key URL copied to clipboard."
            status.TextColor3 = CurrentTheme().Accent2
        else
            -- Still show URL when clipboard APIs are unavailable.
            status.Text = keyURL
            status.TextColor3 = COLORS.SubText
        end
    end)

    local submitting = false

    local function SubmitKey()
        if submitting then
            return
        end

        submitting = true

        local key = keyInput.Text

        if key == "" then
            status.Text = "Please enter a key."
            status.TextColor3 = COLORS.Warning
            submitting = false
            return
        end

        status.Text = "Checking key..."
        status.TextColor3 = COLORS.SubText

        if Validate(key) then
            status.Text = "Key accepted!"
            status.TextColor3 = CurrentTheme().Accent2

            SaveKey(key)

            task.delay(0.25, Finish)
        else
            status.Text = "Invalid key."
            status.TextColor3 = COLORS.Danger
        end

        submitting = false
    end

    submitButton.MouseButton1Click:Connect(
        SubmitKey
    )

    keyInput.FocusLost:Connect(
        function(enterPressed)
            if enterPressed then
                SubmitKey()
            end
        end
    )

    --====================================================
    -- SAVED KEY
    --====================================================

    local saved = ReadKey()

    if saved and Validate(saved) then
        keyInput.Text = saved
        Finish()
    else
        main.Size = UDim2.fromOffset(500, 0)

        Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(500, 280)
            }
        )
    end

    function KeySystem:GetKey()
        return keyInput.Text
    end

    function KeySystem:SetKey(value)
        keyInput.Text = tostring(value or "")
    end

    function KeySystem:Submit()
        SubmitKey()
    end

    function KeySystem:Destroy()
        if KeySystem.Destroyed then
            return
        end

        KeySystem.Destroyed = true

        if gui then
            gui:Destroy()
        end
    end

    function KeySystem:IsDestroyed()
        return KeySystem.Destroyed == true
    end

    return KeySystem
end

function DarkyUI:CreateAura(target, config)
    config = config or {}
    if not target or not target:IsA("GuiObject") then return nil end
    local gui = target:FindFirstAncestorOfClass("ScreenGui")
    if not gui then return nil end
    local aura = CreateAuraFor(gui, target, function() return CurrentTheme().Accent end, config)
    if aura then
        RegisterTheme(function(_, colors)
            if aura.Root and aura.Root.Parent then aura:SetColor(colors.Accent) end
        end)
    end
    return aura
end

function DarkyUI:CreateKeySystem(config)
    if self._KeySystem
        and not self._KeySystem.Destroyed then
        self._KeySystem:Destroy()
    end

    self._KeyPassed = false

    local keySystem = MakeKeySystem(config)

    self._KeySystem = keySystem

    return keySystem
end

--========================================================
-- WINDOW
--========================================================

function DarkyUI:CreateWindow(config)
    config = config or {}

    if DarkyUI._Window
        and not DarkyUI._Window.Destroyed then
        pcall(function()
            DarkyUI._Window:Destroy()
        end)
    end

    if config.Image ~= nil then
        DarkyUI.CurrentImage = config.Image
    end

    local Window = {
        Destroyed = false,
        Minimized = false,
        Tabs = {},
        Elements = {},
        ActiveTab = nil,
    }

    Window.Title = tostring(
        config.Title or "DarkyUI"
    )

    Window.Subtitle = tostring(
        config.Subtitle or ""
    )

    Window.Image = config.Image
    Window.SearchEnabled =
        config.SearchBar == true
    Window.UserConfig =
        config.User or {}

    -- Border/Blur: connect to the KeySystem's settings.
    -- Explicit config.Border/config.Blur always win. Otherwise, if a
    -- KeySystem already exists (CreateKeySystem called first, the
    -- documented common order), inherit its Border/Blur so both stay
    -- visually consistent. Falls back to false.
    local existingKeySystem =
        DarkyUI._KeySystem
        and not DarkyUI._KeySystem.Destroyed
        and DarkyUI._KeySystem
        or nil

    if config.Border ~= nil then
        Window.Border = config.Border == true
    elseif existingKeySystem then
        Window.Border = existingKeySystem.Border == true
    else
        Window.Border = false
    end

    if config.Blur ~= nil then
        Window.Blur = config.Blur == true
    elseif existingKeySystem then
        Window.Blur = existingKeySystem.Blur == true
    else
        Window.Blur = false
    end

    -- If a KeySystem was just created and has not passed yet,
    -- keep the hub hidden until the KeySystem succeeds.
    Window._KeyLocked =
        DarkyUI._KeySystem ~= nil
        and not DarkyUI._KeySystem.Destroyed
        and not DarkyUI._KeyPassed

    --====================================================
    -- GUI
    --====================================================

    local oldGui = CoreGui:FindFirstChild(
        MAIN_GUI_NAME
    )

    if oldGui then
        oldGui:Destroy()
    end

    local gui = New(
        "ScreenGui",
        {
            Name = MAIN_GUI_NAME,
            Parent = CoreGui,
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 1000000,
        }
    )

    Window.Gui = gui

    --====================================================
    -- FLOATING BUTTON
    --====================================================

    local floating = New(
        "TextButton",
        {
            Parent = gui,
            Name = "FloatingButton",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 18, 0.5, 0),
            Size = UDim2.fromOffset(52, 52),
            BackgroundColor3 = COLORS.Panel,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Active = true,
            Text = "",
            Visible = false,
            ZIndex = 500,
        }
    )

    AddCorner(floating, 11)

    Stroke(
        floating,
        COLORS.Border,
        1
    )

    local floatingIcon = Icon(
        floating,
        Window.Image or "layout-dashboard",
        24,
        UDim2.new(0.5, -12, 0.5, -12),
        501
    )

    if not floatingIcon then
        New(
            "TextLabel",
            {
                Parent = floating,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = string.sub(Window.Title, 1, 1):upper(),
                TextColor3 = COLORS.Text,
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                ZIndex = 501,
            }
        )
    end

    --====================================================
    -- MAIN
    --====================================================

    local main = New(
        "Frame",
        {
            Parent = gui,
            Name = "Main",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(
                WINDOW_WIDTH,
                WINDOW_HEIGHT
            ),
            BackgroundColor3 = COLORS.Background,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Visible = not Window._KeyLocked,
            ZIndex = 10,
        }
    )

    Window.Main = main

    AddCorner(main, 12)
    local mainStroke = Stroke(
        main,
        Window.Border and CurrentTheme().Accent or COLORS.Border,
        1
    )
    mainStroke.Transparency = Window.Border and 0 or 1

    local mainAura
    if Window.Blur then
        mainAura = CreateAuraFor(gui, main, function() return CurrentTheme().Accent end, {
            Name = "MainAura", Expand = 20, Radius = 12, Layers = 6, Thickness = 5, Transparency = 0.76
        })
    end
    Window.Aura = mainAura

    --====================================================
    -- TOP BAR
    --====================================================

    local top = New(
        "Frame",
        {
            Parent = main,
            Name = "TopBar",
            Position = UDim2.fromOffset(1, 1),
            Size = UDim2.new(1, -2, 0, 57),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ZIndex = 20,
        }
    )

    AddCorner(top, 11)

    New(
        "Frame",
        {
            Parent = top,
            Name = "CornerMask",
            Position = UDim2.new(0, 0, 1, -11),
            Size = UDim2.new(1, 0, 0, 11),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ZIndex = 20,
        }
    )

    Stroke(
        top,
        COLORS.Border,
        1
    )

    RegisterTheme(function(_, colors)
        if mainStroke and mainStroke.Parent then
            mainStroke.Color = Window.Border and colors.Accent or COLORS.Border
            mainStroke.Transparency = Window.Border and 0 or 1
        end
        if mainAura and mainAura.Root and mainAura.Root.Parent then
            mainAura:SetColor(colors.Accent)
        end
    end)

    --====================================================
    -- DRAG MAIN WINDOW
    --====================================================

    do
        local dragging = false
        local dragInput
        local dragStart
        local startPosition

        local function update(input)
            if not dragging then
                return
            end

            local delta =
                input.Position - dragStart

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end

        top.InputBegan:Connect(function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch then

                dragging = true
                dragStart = input.Position
                startPosition = main.Position
                dragInput = input

                input.Changed:Connect(function()
                    if input.UserInputState ==
                        Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        top.InputChanged:Connect(function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseMovement
                or input.UserInputType ==
                Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput then
                update(input)
            end
        end)
    end

    --====================================================
    -- WINDOW ICON
    --====================================================

    local iconHolder = New(
        "Frame",
        {
            Parent = top,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(11, 9),
            Size = UDim2.fromOffset(40, 40),
            ZIndex = 21,
        }
    )

    local windowIcon = Icon(
        iconHolder,
        Window.Image or "layout-dashboard",
        24,
        UDim2.new(0.5, -12, 0.5, -12),
        22
    )

    if not windowIcon then
        New(
            "TextLabel",
            {
                Parent = iconHolder,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = string.sub(Window.Title, 1, 1):upper(),
                TextColor3 = COLORS.Text,
                TextSize = 19,
                Font = Enum.Font.GothamBold,
                ZIndex = 22,
            }
        )
    end

    --====================================================
    -- TITLE + SUBTITLE
    --====================================================

    local titleLabel = New(
        "TextLabel",
        {
            Parent = top,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(58, 7),
            Size = UDim2.new(1, -225, 0, 23),
            Text = Window.Title,
            TextColor3 = COLORS.Text,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 22,
        }
    )

    local subtitleLabel = New(
        "TextLabel",
        {
            Parent = top,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(58, 30),
            Size = UDim2.new(1, -225, 0, 17),
            Text = Window.Subtitle,
            TextColor3 = COLORS.SubText,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 22,
        }
    )

    --====================================================
    -- SEARCH BAR
    --====================================================

    local searchBox

    if Window.SearchEnabled then
        local searchFrame = New(
            "Frame",
            {
                Parent = top,
                Position = UDim2.new(1, -205, 0, 11),
                Size = UDim2.fromOffset(125, 36),
                BackgroundColor3 = COLORS.Panel,
                BorderSizePixel = 0,
                ZIndex = 25,
            }
        )

        Stroke(
            searchFrame,
            COLORS.Border,
            1
        )

        Icon(
            searchFrame,
            "search",
            15,
            UDim2.fromOffset(9, 10),
            26
        )

        searchBox = New(
            "TextBox",
            {
                Parent = searchFrame,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -35, 1, 0),
                PlaceholderText = "Search",
                PlaceholderColor3 = COLORS.Muted,
                Text = "",
                TextColor3 = COLORS.Text,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 26,
            }
        )

        Window.SearchBox = searchBox
    end

    --====================================================
    -- MINIMIZE / CLOSE
    --====================================================

    local minimizeButton = New(
        "TextButton",
        {
            Parent = top,
            Position = UDim2.new(1, -75, 0, 9),
            Size = UDim2.fromOffset(30, 38),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 30,
        }
    )

    Icon(
        minimizeButton,
        "minus",
        17,
        UDim2.new(0.5, -8, 0.5, -8),
        31
    )

    local closeButton = New(
        "TextButton",
        {
            Parent = top,
            Position = UDim2.new(1, -40, 0, 9),
            Size = UDim2.fromOffset(30, 38),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 30,
        }
    )

    local closeIcon = Icon(
        closeButton,
        "x",
        18,
        UDim2.new(0.5, -9, 0.5, -9),
        31
    )

    if closeIcon then
        closeIcon.ImageColor3 = COLORS.Danger
    end

    --====================================================
    -- BODY
    --====================================================

    local body = New(
        "Frame",
        {
            Parent = main,
            Position = UDim2.fromOffset(0, 58),
            Size = UDim2.new(1, 0, 1, -58),
            BackgroundTransparency = 1,
            ZIndex = 10,
        }
    )

    --====================================================
    -- TABS
    --====================================================

    local tabs = New(
        "ScrollingFrame",
        {
            Parent = body,
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.fromOffset(145, 266),
            BackgroundColor3 = COLORS.Background2,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = COLORS.Border,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 11,
        }
    )

    AddCorner(tabs, 10)

    Stroke(
        tabs,
        COLORS.Border,
        1
    )

    Padding(
        tabs,
        6,
        6,
        6,
        6
    )

    New(
        "UIListLayout",
        {
            Parent = tabs,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
        }
    )

    --====================================================
    -- PROFILE
    --====================================================

    if Window.UserConfig.Profile
        or Window.UserConfig.Username then

        local profile = New(
            "Frame",
            {
                Parent = tabs,
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = COLORS.Panel,
                BorderSizePixel = 0,
                LayoutOrder = -100,
                ZIndex = 13,
            }
        )

        Stroke(
            profile,
            COLORS.Border,
            1
        )

        if Window.UserConfig.Profile then
            local avatar = New(
                "ImageLabel",
                {
                    Parent = profile,
                    Position = UDim2.fromOffset(7, 7),
                    Size = UDim2.fromOffset(36, 36),
                    BackgroundColor3 = COLORS.Panel2,
                    BorderSizePixel = 0,
                    ZIndex = 14,
                }
            )

            pcall(function()
                local image =
                    Players:GetUserThumbnailAsync(
                        LocalPlayer.UserId,
                        Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size100x100
                    )

                avatar.Image = image
            end)

            Stroke(
                avatar,
                COLORS.Border,
                1
            )
        end

        if Window.UserConfig.Username then
            local x =
                Window.UserConfig.Profile
                    and 49
                    or 8

            New(
                "TextLabel",
                {
                    Parent = profile,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(x, 7),
                    Size = UDim2.new(1, -x - 5, 0, 19),
                    Text = LocalPlayer.DisplayName,
                    TextColor3 = COLORS.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 14,
                }
            )

            New(
                "TextLabel",
                {
                    Parent = profile,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(x, 26),
                    Size = UDim2.new(1, -x - 5, 0, 16),
                    Text = "@" .. LocalPlayer.Name,
                    TextColor3 = COLORS.SubText,
                    TextSize = 9,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 14,
                }
            )
        end
    end

    --====================================================
    -- CONTENT
    --====================================================

    local content = New(
        "Frame",
        {
            Parent = body,
            Position = UDim2.fromOffset(160, 8),
            Size = UDim2.new(1, -168, 1, -16),
            BackgroundTransparency = 1,
            ZIndex = 11,
        }
    )

    --====================================================
    -- SEARCH LOGIC
    --====================================================

    local function SearchElements(text)
        text = tostring(text or ""):lower()

        for _, element in ipairs(Window.Elements) do
            if element.Root and element.Root.Parent then
                if text == "" then
                    element.Root.Visible = true
                else
                    local elementTitle = tostring(
                        element.Title or ""
                    ):lower()

                    local elementDesc = tostring(
                        element.Desc or ""
                    ):lower()

                    element.Root.Visible =
                        elementTitle:find(text, 1, true) ~= nil
                        or elementDesc:find(text, 1, true) ~= nil
                end
            end
        end
    end

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text")
            :Connect(function()
                SearchElements(searchBox.Text)
            end)
    end

    --====================================================
    -- WINDOW METHODS
    --====================================================

    function Window:Minimize()
        if self.Destroyed
            or self.Minimized
            or self._KeyLocked then
            return
        end

        self.Minimized = true

        Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(
                    WINDOW_WIDTH,
                    0
                )
            }
        )

        task.delay(0.22, function()
            if self.Destroyed then
                return
            end

            main.Visible = false
            floating.Visible = true
            floating.Size = UDim2.fromOffset(0, 0)

            Tween(
                floating,
                MED,
                {
                    Size = UDim2.fromOffset(52, 52)
                }
            )
        end)
    end

    function Window:Restore()
        if self.Destroyed
            or not self.Minimized then
            return
        end

        self.Minimized = false
        floating.Visible = false
        main.Visible = true
        main.Size = UDim2.fromOffset(WINDOW_WIDTH, 0)

        Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(
                    WINDOW_WIDTH,
                    WINDOW_HEIGHT
                )
            }
        )
    end

    --====================================================
    -- DELETE CONFIRMATION POPUP
    --====================================================

    local function ShowDeleteConfirm()
        local confirmGui = New(
            "ScreenGui",
            {
                Name = "DarkyUI_ConfirmDelete",
                Parent = CoreGui,
                IgnoreGuiInset = true,
                ResetOnSpawn = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder = 3500000,
            }
        )

        local overlay = New(
            "Frame",
            {
                Parent = confirmGui,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = COLORS.Black,
                BackgroundTransparency = 0.4,
                BorderSizePixel = 0,
                ZIndex = 1000,
            }
        )

        local function ClosePopup()
            confirmGui:Destroy()
        end

        local outside = New(
            "TextButton",
            {
                Parent = overlay,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 1000,
            }
        )

        outside.MouseButton1Click:Connect(ClosePopup)

        local popup = New(
            "Frame",
            {
                Parent = overlay,
                Name = "ConfirmPopup",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(300, 170),
                BackgroundColor3 = COLORS.Background,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 1002,
            }
        )

        AddCorner(popup, 12)

        Stroke(
            popup,
            COLORS.Border,
            1
        )

        local warnIcon = Icon(
            popup,
            "trash-2",
            30,
            UDim2.new(0.5, -15, 0, 20),
            1003,
            false
        )

        if warnIcon then
            warnIcon.ImageColor3 = COLORS.Danger
        end

        New(
            "TextLabel",
            {
                Parent = popup,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(15, 60),
                Size = UDim2.new(1, -30, 0, 20),
                Text = "Delete UI library?",
                TextColor3 = COLORS.Text,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1003,
            }
        )

        New(
            "TextLabel",
            {
                Parent = popup,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(15, 82),
                Size = UDim2.new(1, -30, 0, 32),
                Text = "Do you really want to delete UI library? This action cannot be undone.",
                TextColor3 = COLORS.SubText,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 1003,
            }
        )

        local cancelButton = New(
            "TextButton",
            {
                Parent = popup,
                Position = UDim2.new(0, 15, 1, -46),
                Size = UDim2.new(0.5, -20, 0, 32),
                BackgroundColor3 = COLORS.Info,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 1003,
            }
        )

        AddCorner(cancelButton, 8)

        local cancelIcon = Icon(
            cancelButton,
            "x",
            14,
            UDim2.new(0, 12, 0.5, -7),
            1004
        )

        if cancelIcon then
            cancelIcon.ImageColor3 = COLORS.White
        end

        New(
            "TextLabel",
            {
                Parent = cancelButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -38, 1, 0),
                Text = "Cancel",
                TextColor3 = COLORS.White,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1004,
            }
        )

        local deleteButton = New(
            "TextButton",
            {
                Parent = popup,
                Position = UDim2.new(0.5, 5, 1, -46),
                Size = UDim2.new(0.5, -20, 0, 32),
                BackgroundColor3 = COLORS.Danger,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ZIndex = 1003,
            }
        )

        AddCorner(deleteButton, 8)

        local deleteIcon = Icon(
            deleteButton,
            "trash-2",
            14,
            UDim2.new(0, 12, 0.5, -7),
            1004
        )

        if deleteIcon then
            deleteIcon.ImageColor3 = COLORS.White
        end

        New(
            "TextLabel",
            {
                Parent = deleteButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -38, 1, 0),
                Text = "Delete",
                TextColor3 = COLORS.White,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 1004,
            }
        )

        cancelButton.MouseEnter:Connect(function()
            Tween(cancelButton, FAST, { BackgroundTransparency = 0.15 })
        end)

        cancelButton.MouseLeave:Connect(function()
            Tween(cancelButton, FAST, { BackgroundTransparency = 0 })
        end)

        deleteButton.MouseEnter:Connect(function()
            Tween(deleteButton, FAST, { BackgroundTransparency = 0.15 })
        end)

        deleteButton.MouseLeave:Connect(function()
            Tween(deleteButton, FAST, { BackgroundTransparency = 0 })
        end)

        cancelButton.MouseButton1Click:Connect(ClosePopup)

        deleteButton.MouseButton1Click:Connect(function()
            ClosePopup()
            Window:Destroy()
        end)

        popup.Size = UDim2.fromOffset(300, 0)

        Tween(
            popup,
            MED,
            {
                Size = UDim2.fromOffset(300, 170)
            }
        )
    end

    function Window:Destroy()
        if self.Destroyed then
            return
        end

        self.Destroyed = true

        if self.Aura then
            pcall(function() self.Aura:Destroy() end)
            self.Aura = nil
        end

        if gui then
            gui:Destroy()
        end
    end

    function Window:CreateAura(config)
        config = config or {}
        if not self.Main or not self.Main.Parent then return nil end
        if self.Aura then self.Aura:Destroy() end
        self.Aura = DarkyUI:CreateAura(self.Main, config)
        return self.Aura
    end

    function Window:SetTitle(value)
        self.Title = tostring(value)
        titleLabel.Text = self.Title
    end

    function Window:SetSubtitle(value)
        self.Subtitle = tostring(value)
        subtitleLabel.Text = self.Subtitle
    end

    function Window:SetIcon(value)
        self.Image = value
        DarkyUI.CurrentImage = value

        local asset, isGlyph = ResolveIcon(value)

        if asset then
            local tint = isGlyph and COLORS.Text or COLORS.White

            if windowIcon then
                windowIcon.Image = asset
                windowIcon.ImageColor3 = tint
            end

            if floatingIcon then
                floatingIcon.Image = asset
                floatingIcon.ImageColor3 = tint
            end
        end
    end

    function Window:SetVisible(value)
        value = value == true

        if value then
            if self.Minimized then
                self:Restore()
            else
                main.Visible = true
            end
        else
            main.Visible = false
        end
    end

    function Window:GetActiveTab()
        return self.ActiveTab
    end

    --====================================================
    -- BUTTON EVENTS
    --====================================================

    minimizeButton.MouseButton1Click:Connect(function()
        self = Window
        Window:Minimize()
    end)

    closeButton.MouseButton1Click:Connect(function()
        ShowDeleteConfirm()
    end)

    --====================================================
    -- FLOATING BUTTON DRAG + TAP
    --====================================================

    do
        local dragging = false
        local dragInput
        local dragStart
        local startPosition
        local moved = false

        local function update(input)
            if not dragging then
                return
            end

            local delta =
                input.Position - dragStart

            if delta.Magnitude > 7 then
                moved = true
            end

            floating.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end

        floating.InputBegan:Connect(function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch then

                dragging = true
                moved = false
                dragInput = input
                dragStart = input.Position
                startPosition = floating.Position

                input.Changed:Connect(function()
                    if input.UserInputState ==
                        Enum.UserInputState.End then

                        dragging = false

                        if not moved then
                            Window:Restore()
                        end
                    end
                end)
            end
        end)

        floating.InputChanged:Connect(function(input)
            if input.UserInputType ==
                Enum.UserInputType.MouseMovement
                or input.UserInputType ==
                Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput then
                update(input)
            end
        end)
    end

    --====================================================
    -- CREATE TAB
    --====================================================

    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}

        local Tab = {
            Title = tabConfig.Title or "Tab",
            Icon = tabConfig.Icon or "circle",
            Sections = {},
            Selected = false,
        }

        local tabButton = New(
            "TextButton",
            {
                Parent = tabs,
                Name = "TabButton",
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = COLORS.Panel,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = #Window.Tabs + 1,
                ZIndex = 15,
            }
        )

        AddCorner(tabButton, 8)

        Stroke(
            tabButton,
            COLORS.Border,
            1
        )

        local selectedBar = New(
            "Frame",
            {
                Parent = tabButton,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromOffset(3, 38),
                BackgroundColor3 = COLORS.Border,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 16,
            }
        )

        AddCorner(selectedBar, 6)

        local tabIconHolder = New(
            "Frame",
            {
                Parent = tabButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 0),
                Size = UDim2.fromOffset(38, 38),
                ZIndex = 16,
            }
        )

        local tabIcon = Icon(
            tabIconHolder,
            Tab.Icon,
            17,
            UDim2.new(0.5, -8, 0.5, -8),
            17
        )

        if not tabIcon then
            New(
                "TextLabel",
                {
                    Parent = tabIconHolder,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = string.sub(Tab.Title, 1, 1):upper(),
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 17,
                }
            )
        end

        local tabText = New(
            "TextLabel",
            {
                Parent = tabButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(47, 0),
                Size = UDim2.new(1, -53, 1, 0),
                Text = Tab.Title,
                TextColor3 = COLORS.SubText,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 17,
            }
        )

        local page = New(
            "ScrollingFrame",
            {
                Parent = content,
                Name = "Page_" .. tostring(#Window.Tabs + 1),
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = COLORS.Border,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Visible = false,
                ZIndex = 12,
            }
        )

        Padding(
            page,
            0,
            5,
            0,
            8
        )

        New(
            "UIListLayout",
            {
                Parent = page,
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 7),
            }
        )

        Tab.Button = tabButton
        Tab.Page = page
        Tab._Bar = selectedBar
        Tab._Text = tabText

        function Tab:Select()
            for _, other in ipairs(Window.Tabs) do
                local active =
                    other == Tab

                other.Page.Visible = active
                other.Selected = active
                other._Bar.Visible = active

                other.Button.BackgroundColor3 = active
                    and COLORS.Panel2
                    or COLORS.Panel

                other._Text.TextColor3 = active
                    and COLORS.Text
                    or COLORS.SubText
            end

            Window.ActiveTab = Tab

            if searchBox then
                SearchElements(searchBox.Text)
            end
        end

        tabButton.MouseButton1Click:Connect(function()
            Tab:Select()
        end)

        tabButton.MouseEnter:Connect(function()
            if not Tab.Selected then
                Tween(
                    tabButton,
                    FAST,
                    {
                        BackgroundColor3 = COLORS.Panel2
                    }
                )
            end
        end)

        tabButton.MouseLeave:Connect(function()
            if not Tab.Selected then
                Tween(
                    tabButton,
                    FAST,
                    {
                        BackgroundColor3 = COLORS.Panel
                    }
                )
            end
        end)

        --================================================
        -- CREATE SECTION
        --================================================

        function Tab:CreateSection(sectionConfig)
            sectionConfig = sectionConfig or {}

            local Section = {
                Title = sectionConfig.Title or "Section",
            }

            -- No Size property. Fully automatic.
            local sectionFrame = New(
                "Frame",
                {
                    Parent = page,
                    Name = "Section_" .. Section.Title,
                    Size = UDim2.new(1, -2, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = COLORS.Background2,
                    BorderSizePixel = 0,
                    LayoutOrder = #Tab.Sections + 1,
                    ZIndex = 13,
                }
            )

            AddCorner(sectionFrame, 10)

            Stroke(
                sectionFrame,
                COLORS.Border,
                1
            )

            Padding(
                sectionFrame,
                9,
                9,
                8,
                9
            )

            AddSectionAccent(sectionFrame)

            New(
                "TextLabel",
                {
                    Parent = sectionFrame,
                    Position = UDim2.fromOffset(6, 0),
                    Size = UDim2.new(1, -6, 0, 20),
                    BackgroundTransparency = 1,
                    Text = Section.Title,
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 16,
                }
            )

            local holder = New(
                "Frame",
                {
                    Parent = sectionFrame,
                    Position = UDim2.fromOffset(0, 25),
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 14,
                }
            )

            New(
                "UIListLayout",
                {
                    Parent = holder,
                    FillDirection = Enum.FillDirection.Vertical,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5),
                }
            )

            Section.Frame = sectionFrame
            Section.Holder = holder
            Section.Elements = {}

            table.insert(
                Tab.Sections,
                Section
            )

            local function Register(root, title, desc)
                AddCorner(root, 8)
                local record = {
                    Root = root,
                    Title = title,
                    Desc = desc,
                }

                table.insert(
                    Window.Elements,
                    record
                )

                table.insert(
                    Section.Elements,
                    record
                )

                return record
            end

            --============================================
            -- BUTTON
            --============================================

            function Section:CreateButton(buttonConfig)
                buttonConfig = buttonConfig or {}

                local title =
                    buttonConfig.Title or "Button"

                -- Optional description shown below the button title.
                local desc =
                    buttonConfig.Desc or ""

                local locked =
                    buttonConfig.Locked == true

                local height =
                    desc ~= "" and 53 or 40

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(1, 0, 0, height),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                local click = New(
                    "TextButton",
                    {
                        Parent = root,
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 17,
                    }
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(
                            11,
                            desc ~= "" and 7 or 0
                        ),
                        Size = UDim2.new(1, -55, 0, 20),
                        Text = title,
                        TextColor3 = locked
                            and COLORS.Muted
                            or COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 28),
                            Size = UDim2.new(1, -20, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 18,
                        }
                    )
                end

                if locked then
                    local lock = Icon(
                        root,
                        "lock",
                        14,
                        UDim2.new(1, -25, 0.5, -7),
                        18
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end

                    click.Active = false
                else
                    Icon(
                        root,
                        "chevron-right",
                        15,
                        UDim2.new(1, -28, 0.5, -7),
                        18
                    )

                    click.MouseEnter:Connect(function()
                        Tween(
                            root,
                            FAST,
                            {
                                BackgroundColor3 = COLORS.Panel2
                            }
                        )
                    end)

                    click.MouseLeave:Connect(function()
                        Tween(
                            root,
                            FAST,
                            {
                                BackgroundColor3 = COLORS.Panel
                            }
                        )
                    end)

                    click.MouseButton1Click:Connect(function()
                        if typeof(buttonConfig.Callback) ==
                            "function" then

                            task.spawn(
                                buttonConfig.Callback
                            )
                        end
                    end)
                end

                local object = {
                    Root = root,
                }

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- TOGGLE
            --============================================

            function Section:CreateToggle(toggleConfig)
                toggleConfig = toggleConfig or {}

                local title =
                    toggleConfig.Title or "Toggle"

                local desc =
                    toggleConfig.Desc or ""

                local state =
                    toggleConfig.Value == true

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 57 or 44
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(
                            11,
                            desc ~= "" and 7 or 0
                        ),
                        Size = UDim2.new(1, -75, 0, 20),
                        Text = title,
                        TextColor3 = COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 28),
                            Size = UDim2.new(1, -80, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 18,
                        }
                    )
                end

                local switch = New(
                    "TextButton",
                    {
                        Parent = root,
                        Position = UDim2.new(1, -58, 0.5, -11),
                        Size = UDim2.fromOffset(44, 22),
                        BackgroundColor3 = COLORS.Panel2,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 19,
                    }
                )

                AddCorner(switch, 8)

                Stroke(
                    switch,
                    COLORS.Border,
                    1
                )

                local knob = New(
                    "Frame",
                    {
                        Parent = switch,
                        Position = UDim2.fromOffset(3, 3),
                        Size = UDim2.fromOffset(16, 16),
                        BackgroundColor3 = COLORS.SubText,
                        BorderSizePixel = 0,
                        ZIndex = 20,
                    }
                )

                AddCorner(knob, 6)

                local function updateToggle(_, colors)
                    if not root.Parent then
                        return
                    end

                    if state then
                        Tween(
                            switch,
                            FAST,
                            {
                                BackgroundColor3 = colors.Accent
                            }
                        )

                        Tween(
                            knob,
                            FAST,
                            {
                                Position = UDim2.new(1, -19, 0.5, -8),
                                BackgroundColor3 = COLORS.White,
                            }
                        )
                    else
                        Tween(
                            switch,
                            FAST,
                            {
                                BackgroundColor3 = COLORS.Panel2
                            }
                        )

                        Tween(
                            knob,
                            FAST,
                            {
                                Position = UDim2.fromOffset(3, 3),
                                BackgroundColor3 = COLORS.SubText,
                            }
                        )
                    end
                end

                RegisterTheme(updateToggle)

                local object = {
                    Root = root,
                }

                function object:SetValue(value, callCallback)
                    state = value == true
                    updateToggle(nil, CurrentTheme())

                    if callCallback ~= false
                        and typeof(toggleConfig.Callback) ==
                            "function" then

                        task.spawn(
                            toggleConfig.Callback,
                            state
                        )
                    end
                end

                function object:GetValue()
                    return state
                end

                switch.MouseButton1Click:Connect(function()
                    object:SetValue(
                        not state,
                        true
                    )
                end)

                updateToggle(
                    nil,
                    CurrentTheme()
                )

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- SLIDER
            --============================================

            function Section:CreateSlider(sliderConfig)
                sliderConfig = sliderConfig or {}

                local title =
                    sliderConfig.Title or "Slider"

                local desc =
                    sliderConfig.Desc or ""

                local range =
                    sliderConfig.Value or {}

                local minimum =
                    tonumber(range.Min) or 0

                local maximum =
                    tonumber(range.Max) or 100

                local current =
                    tonumber(range.Default)
                    or minimum

                local step =
                    tonumber(sliderConfig.Step)
                    or 1

                if maximum < minimum then
                    minimum, maximum = maximum, minimum
                end

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 67 or 56
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 7),
                        Size = UDim2.new(1, -75, 0, 20),
                        Text = title,
                        TextColor3 = COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                local valueLabel = New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -60, 0, 7),
                        Size = UDim2.fromOffset(50, 20),
                        Text = tostring(current),
                        TextColor3 = CurrentTheme().Accent2,
                        TextSize = 11,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 27),
                            Size = UDim2.new(1, -20, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 18,
                        }
                    )
                end

                local sliderHolder = New(
                    "Frame",
                    {
                        Parent = root,
                        Position = UDim2.fromOffset(
                            11,
                            desc ~= "" and 49 or 38
                        ),
                        Size = UDim2.new(1, -22, 0, 10),
                        BackgroundTransparency = 1,
                        ZIndex = 18,
                    }
                )

                local track = New(
                    "Frame",
                    {
                        Parent = sliderHolder,
                        Position = UDim2.new(0, 0, 0.5, -3),
                        Size = UDim2.new(1, 0, 0, 6),
                        BackgroundColor3 = COLORS.Panel2,
                        BorderSizePixel = 0,
                        ZIndex = 18,
                    }
                )

                AddCorner(track, 5)

                Stroke(
                    track,
                    COLORS.Border,
                    1
                )

                local fill = New(
                    "Frame",
                    {
                        Parent = track,
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundColor3 = CurrentTheme().Accent,
                        BorderSizePixel = 0,
                        ZIndex = 19,
                    }
                )

                AddCorner(fill, 5)

                local knob = New(
                    "Frame",
                    {
                        Parent = track,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        Size = UDim2.fromOffset(12, 12),
                        BackgroundColor3 = COLORS.White,
                        BorderSizePixel = 0,
                        ZIndex = 20,
                    }
                )

                AddCorner(knob, 5)

                local drag = New(
                    "TextButton",
                    {
                        Parent = sliderHolder,
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 21,
                    }
                )

                local function roundStep(value)
                    value = math.clamp(
                        value,
                        minimum,
                        maximum
                    )

                    local steps = math.floor(
                        ((value - minimum) / step) + 0.5
                    )

                    return math.clamp(
                        minimum + (steps * step),
                        minimum,
                        maximum
                    )
                end

                local function set(value, callCallback)
                    current = roundStep(value)

                    local percent = (
                        current - minimum
                    ) / math.max(
                        maximum - minimum,
                        0.00001
                    )

                    fill.Size = UDim2.new(
                        percent,
                        0,
                        1,
                        0
                    )

                    knob.Position = UDim2.new(
                        percent,
                        0,
                        0.5,
                        0
                    )

                    valueLabel.Text =
                        tostring(current)

                    if callCallback
                        and typeof(sliderConfig.Callback) ==
                            "function" then

                        task.spawn(
                            sliderConfig.Callback,
                            current
                        )
                    end
                end

                local function updateTheme(_, colors)
                    if not root.Parent then
                        return
                    end

                    fill.BackgroundColor3 =
                        colors.Accent

                    valueLabel.TextColor3 =
                        colors.Accent2
                end

                RegisterTheme(updateTheme)

                local moving = false

                local function xToValue(x)
                    local alpha = math.clamp(
                        (
                            x
                            - sliderHolder.AbsolutePosition.X
                        )
                        / math.max(
                            sliderHolder.AbsoluteSize.X,
                            1
                        ),
                        0,
                        1
                    )

                    set(
                        minimum
                            + (
                                maximum
                                - minimum
                            ) * alpha,
                        true
                    )
                end

                drag.InputBegan:Connect(function(input)
                    if input.UserInputType ==
                        Enum.UserInputType.MouseButton1
                        or input.UserInputType ==
                        Enum.UserInputType.Touch then

                        moving = true
                        xToValue(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if moving
                        and (
                            input.UserInputType ==
                                Enum.UserInputType.MouseMovement
                            or input.UserInputType ==
                                Enum.UserInputType.Touch
                        ) then

                        xToValue(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType ==
                        Enum.UserInputType.MouseButton1
                        or input.UserInputType ==
                        Enum.UserInputType.Touch then

                        moving = false
                    end
                end)

                local object = {
                    Root = root,
                }

                function object:SetValue(value, callCallback)
                    set(
                        tonumber(value) or minimum,
                        callCallback ~= false
                    )
                end

                function object:GetValue()
                    return current
                end

                function object:SetRange(minimumValue, maximumValue, default)
                    minimum = tonumber(minimumValue)
                        or minimum

                    maximum = tonumber(maximumValue)
                        or maximum

                    if maximum < minimum then
                        minimum, maximum = maximum, minimum
                    end

                    if default ~= nil then
                        current = tonumber(default)
                            or minimum
                    end

                    set(current, false)
                end

                set(current, false)

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- INPUT
            --============================================

            function Section:CreateInput(inputConfig)
                inputConfig = inputConfig or {}

                local title =
                    inputConfig.Title or "Input"

                local desc =
                    inputConfig.Desc or ""

                local inputY =
                    desc ~= "" and 46 or 27

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 75 or 62
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 7),
                        Size = UDim2.new(1, -20, 0, 19),
                        Text = title,
                        TextColor3 = COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 27),
                            Size = UDim2.new(1, -20, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 18,
                        }
                    )
                end

                local box = New(
                    "Frame",
                    {
                        Parent = root,
                        Position = UDim2.fromOffset(10, inputY),
                        Size = UDim2.new(1, -20, 0, 26),
                        BackgroundColor3 = COLORS.Panel2,
                        BorderSizePixel = 0,
                        ZIndex = 18,
                    }
                )

                Stroke(
                    box,
                    COLORS.Border,
                    1
                )

                local textBox = New(
                    "TextBox",
                    {
                        Parent = box,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(8, 0),
                        Size = UDim2.new(1, -38, 1, 0),
                        Text = inputConfig.Value or "",
                        PlaceholderText = inputConfig.Placeholder or "",
                        PlaceholderColor3 = COLORS.Muted,
                        TextColor3 = COLORS.Text,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        ClearTextOnFocus = false,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 19,
                    }
                )

                -- Pencil icon: tinted with the active theme's Accent color
                -- (BlueSky by default) and re-tints live if the theme changes.
                Icon(
                    box,
                    "pencil",
                    14,
                    UDim2.new(1, -24, 0.5, -7),
                    19,
                    true
                )

                textBox.FocusLost:Connect(function(enterPressed)
                    if typeof(inputConfig.Callback) ==
                        "function" then

                        task.spawn(
                            inputConfig.Callback,
                            textBox.Text,
                            enterPressed
                        )
                    end
                end)

                local object = {
                    Root = root,
                    TextBox = textBox,
                }

                function object:GetValue()
                    return textBox.Text
                end

                function object:SetValue(value)
                    textBox.Text = tostring(value or "")
                end

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            --============================================
            -- DROPDOWN
            --============================================

            function Section:CreateDropdown(dropdownConfig)
                dropdownConfig = dropdownConfig or {}

                local title =
                    dropdownConfig.Title or "Dropdown"

                -- Optional description shown below the dropdown title.
                local desc =
                    dropdownConfig.Desc or ""

                local values =
                    dropdownConfig.Values or {}

                local multi =
                    dropdownConfig.Multi == true

                local selected

                if multi then
                    selected = {}

                    if type(dropdownConfig.Value) == "table" then
                        for _, value in ipairs(dropdownConfig.Value) do
                            table.insert(selected, value)
                        end
                    elseif dropdownConfig.Value ~= nil then
                        table.insert(selected, dropdownConfig.Value)
                    end
                else
                    selected = dropdownConfig.Value

                    if selected == nil and #values > 0 then
                        selected = values[1]
                    end
                end

                local function IsSelected(value)
                    if not multi then
                        return tostring(value) == tostring(selected)
                    end

                    for _, item in ipairs(selected) do
                        if tostring(item) == tostring(value) then
                            return true
                        end
                    end

                    return false
                end

                local function GetSelectedText()
                    if not multi then
                        return tostring(selected or "Select...")
                    end

                    if #selected == 0 then
                        return "Select..."
                    end

                    local parts = {}

                    for _, value in ipairs(selected) do
                        table.insert(parts, tostring(value))
                    end

                    return table.concat(parts, ", ")
                end

                local root = New(
                    "Frame",
                    {
                        Parent = holder,
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            desc ~= "" and 72 or 57
                        ),
                        BackgroundColor3 = COLORS.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 15,
                    }
                )

                Stroke(
                    root,
                    COLORS.Border,
                    1
                )

                New(
                    "TextLabel",
                    {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(
                            11,
                            desc ~= "" and 7 or 6
                        ),
                        Size = UDim2.new(1, -180, 0, 20),
                        Text = title,
                        TextColor3 = COLORS.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamMedium,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    }
                )

                if desc ~= "" then
                    New(
                        "TextLabel",
                        {
                            Parent = root,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(11, 28),
                            Size = UDim2.new(1, -22, 0, 16),
                            Text = desc,
                            TextColor3 = COLORS.SubText,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 18,
                        }
                    )
                end

                local display = New(
                    "TextButton",
                    {
                        Parent = root,
                        Position = UDim2.new(1, -165, 0.5, -14),
                        Size = UDim2.fromOffset(154, 28),
                        BackgroundColor3 = COLORS.Panel2,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 20,
                    }
                )

                AddCorner(display, 8)

                Stroke(
                    display,
                    COLORS.Border,
                    1
                )

                local selectedLabel = New(
                    "TextLabel",
                    {
                        Parent = display,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(9, 0),
                        Size = UDim2.new(1, -35, 1, 0),
                        Text = GetSelectedText(),
                        TextColor3 = COLORS.Text,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 21,
                    }
                )

                Icon(
                    display,
                    "chevrons-up-down",
                    15,
                    UDim2.new(1, -22, 0.5, -7),
                    21
                )

                local popupGui = nil

                local function ClosePopup()
                    if popupGui then
                        popupGui:Destroy()
                        popupGui = nil
                    end
                end

                local function OpenPopup()
                    if popupGui then
                        ClosePopup()
                        return
                    end

                    -- Dropdown overlays the hub and is independently scrollable.
                    popupGui = New(
                        "ScreenGui",
                        {
                            Name = "DarkyUI_Dropdown",
                            Parent = CoreGui,
                            IgnoreGuiInset = true,
                            ResetOnSpawn = false,
                            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                            DisplayOrder = 2500000,
                        }
                    )

                    local overlay = New(
                        "Frame",
                        {
                            Parent = popupGui,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundColor3 = COLORS.Black,
                            BackgroundTransparency = 0.5,
                            BorderSizePixel = 0,
                            ZIndex = 1000,
                        }
                    )

                    local outside = New(
                        "TextButton",
                        {
                            Parent = overlay,
                            Size = UDim2.fromScale(1, 1),
                            BackgroundTransparency = 1,
                            Text = "",
                            AutoButtonColor = false,
                            ZIndex = 1000,
                        }
                    )

                    local popup = New(
                        "Frame",
                        {
                            Parent = overlay,
                            Name = "Popup",
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromOffset(360, 0),
                            BackgroundColor3 = COLORS.Background,
                            BorderSizePixel = 0,
                            ZIndex = 1002,
                        }
                    )

                    AddCorner(popup, 12)

                    Stroke(
                        popup,
                        COLORS.Border,
                        1
                    )

                    outside.MouseButton1Click:Connect(
                        ClosePopup
                    )

                    local header = New(
                        "Frame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(1, 1),
                            Size = UDim2.new(1, -2, 0, 49),
                            BackgroundColor3 = COLORS.Background2,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    AddCorner(header, 9)

                    New(
                        "Frame",
                        {
                            Parent = header,
                            Name = "CornerMask",
                            Position = UDim2.new(0, 0, 1, -9),
                            Size = UDim2.new(1, 0, 0, 9),
                            BackgroundColor3 = COLORS.Background2,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    New(
                        "TextLabel",
                        {
                            Parent = header,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(12, 0),
                            Size = UDim2.new(1, -55, 1, 0),
                            Text = title,
                            TextColor3 = COLORS.Text,
                            TextSize = 12,
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 1004,
                        }
                    )

                    local modalClose = New(
                        "TextButton",
                        {
                            Parent = header,
                            Position = UDim2.new(1, -42, 0, 7),
                            Size = UDim2.fromOffset(32, 36),
                            BackgroundTransparency = 1,
                            AutoButtonColor = false,
                            Text = "",
                            ZIndex = 1005,
                        }
                    )

                    local modalCloseIcon = Icon(
                        modalClose,
                        "x",
                        18,
                        UDim2.new(0.5, -9, 0.5, -9),
                        1006
                    )

                    if modalCloseIcon then
                        modalCloseIcon.ImageColor3 = COLORS.Danger
                    end

                    modalClose.MouseButton1Click:Connect(
                        ClosePopup
                    )

                    local searchFrame = New(
                        "Frame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(10, 58),
                            Size = UDim2.new(1, -20, 0, 34),
                            BackgroundColor3 = COLORS.Panel,
                            BorderSizePixel = 0,
                            ZIndex = 1003,
                        }
                    )

                    AddCorner(searchFrame, 8)

                    Stroke(
                        searchFrame,
                        COLORS.Border,
                        1
                    )

                    Icon(
                        searchFrame,
                        "search",
                        15,
                        UDim2.fromOffset(9, 9),
                        1004
                    )

                    local popupSearch = New(
                        "TextBox",
                        {
                            Parent = searchFrame,
                            BackgroundTransparency = 1,
                            Position = UDim2.fromOffset(31, 0),
                            Size = UDim2.new(1, -38, 1, 0),
                            PlaceholderText = "Search option...",
                            PlaceholderColor3 = COLORS.Muted,
                            Text = "",
                            TextColor3 = COLORS.Text,
                            TextSize = 10,
                            Font = Enum.Font.Gotham,
                            ClearTextOnFocus = false,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 1005,
                        }
                    )

                    local optionList = New(
                        "ScrollingFrame",
                        {
                            Parent = popup,
                            Position = UDim2.fromOffset(10, 100),
                            Size = UDim2.new(1, -20, 0, 160),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            ScrollBarThickness = 4,
                            ScrollBarImageColor3 = COLORS.Border,
                            CanvasSize = UDim2.new(),
                            AutomaticCanvasSize = Enum.AutomaticSize.Y,
                            ScrollingDirection = Enum.ScrollingDirection.Y,
                            ScrollingEnabled = false,
                            ZIndex = 1003,
                        }
                    )

                    Padding(
                        optionList,
                        1,
                        4,
                        1,
                        4
                    )

                    New(
                        "UIListLayout",
                        {
                            Parent = optionList,
                            FillDirection = Enum.FillDirection.Vertical,
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Padding = UDim.new(0, 4),
                        }
                    )

                    local countLabel = New(
                        "TextLabel",
                        {
                            Parent = popup,
                            Position = UDim2.new(0, 12, 1, -31),
                            Size = UDim2.new(1, -24, 0, 20),
                            BackgroundTransparency = 1,
                            Text = tostring(#values) .. " options",
                            TextColor3 = COLORS.Muted,
                            TextSize = 9,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 1004,
                        }
                    )

                    local renderOptions

                    local function selectOption(value)
                        if multi then
                            local selectedIndex = nil

                            for index, item in ipairs(selected) do
                                if tostring(item) == tostring(value) then
                                    selectedIndex = index
                                    break
                                end
                            end

                            if selectedIndex then
                                table.remove(selected, selectedIndex)
                            else
                                table.insert(selected, value)
                            end

                            selectedLabel.Text = GetSelectedText()

                            -- Refresh the option list immediately so the
                            -- checkmark/highlight reflects the new selection
                            -- while the popup is still open, instead of only
                            -- updating the next time the popup is reopened.
                            if renderOptions then
                                renderOptions()
                            end

                            if typeof(dropdownConfig.Callback) ==
                                "function" then

                                local result = {}

                                for _, item in ipairs(selected) do
                                    table.insert(result, item)
                                end

                                task.spawn(
                                    dropdownConfig.Callback,
                                    result
                                )
                            end
                        else
                            selected = value
                            selectedLabel.Text = GetSelectedText()

                            ClosePopup()

                            if typeof(dropdownConfig.Callback) ==
                                "function" then

                                task.spawn(
                                    dropdownConfig.Callback,
                                    value
                                )
                            end
                        end
                    end

                    renderOptions = function()
                        for _, child in ipairs(
                            optionList:GetChildren()
                        ) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end

                        local filter =
                            popupSearch.Text:lower()

                        local shown = 0

                        for index, value in ipairs(values) do
                            local text = tostring(value)
                            local matches =
                                filter == ""
                                or text:lower():find(
                                    filter,
                                    1,
                                    true
                                ) ~= nil

                            if matches then
                                shown += 1

                                local option = New(
                                    "TextButton",
                                    {
                                        Parent = optionList,
                                        Size = UDim2.new(1, 0, 0, 35),
                                        BackgroundColor3 = COLORS.Panel,
                                        BorderSizePixel = 0,
                                        AutoButtonColor = false,
                                        Text = "",
                                        LayoutOrder = index,
                                        ZIndex = 1005,
                                    }
                                )

                                AddCorner(option, 7)

                                Stroke(
                                    option,
                                    COLORS.Border,
                                    1
                                )

                                New(
                                    "TextLabel",
                                    {
                                        Parent = option,
                                        BackgroundTransparency = 1,
                                        Position = UDim2.fromOffset(10, 0),
                                        Size = UDim2.new(1, -45, 1, 0),
                                        Text = text,
                                        TextColor3 =
                                            IsSelected(value)
                                            and CurrentTheme().Accent2
                                            or COLORS.Text,
                                        TextSize = 10,
                                        Font = Enum.Font.GothamMedium,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextTruncate = Enum.TextTruncate.AtEnd,
                                        ZIndex = 1006,
                                    }
                                )

                                if IsSelected(value) then
                                    Icon(
                                        option,
                                        "check",
                                        15,
                                        UDim2.new(1, -27, 0.5, -7),
                                        1007
                                    )
                                end

                                option.MouseEnter:Connect(function()
                                    Tween(
                                        option,
                                        FAST,
                                        {
                                            BackgroundColor3 = COLORS.Panel2
                                        }
                                    )
                                end)

                                option.MouseLeave:Connect(function()
                                    Tween(
                                        option,
                                        FAST,
                                        {
                                            BackgroundColor3 = COLORS.Panel
                                        }
                                    )
                                end)

                                option.MouseButton1Click:Connect(function()
                                    selectOption(value)
                                end)
                            end
                        end

                        -- Only enable scrolling when the dropdown has 5+ values.
                        -- With 1-4 values the scrollbar is completely hidden and
                        -- scrolling is disabled.
                        local shouldScroll = #values >= 5

                        optionList.ScrollingEnabled = shouldScroll
                        optionList.ScrollBarThickness = shouldScroll and 4 or 0

                        if not shouldScroll then
                            optionList.CanvasPosition = Vector2.zero
                        end

                        countLabel.Text =
                            tostring(shown)
                            .. " options"
                    end

                    popupSearch:GetPropertyChangedSignal("Text")
                        :Connect(renderOptions)

                    renderOptions()

                    Tween(
                        popup,
                        MED,
                        {
                            Size = UDim2.fromOffset(360, 260)
                        }
                    )
                end

                display.MouseButton1Click:Connect(
                    OpenPopup
                )

                local object = {
                    Root = root,
                    Multi = multi,
                }

                function object:Refresh(newValues)
                    if type(newValues) ~= "table" then
                        return
                    end

                    values = newValues

                    if multi then
                        local filtered = {}

                        for _, selectedValue in ipairs(selected) do
                            for _, value in ipairs(values) do
                                if tostring(value) == tostring(selectedValue) then
                                    table.insert(filtered, selectedValue)
                                    break
                                end
                            end
                        end

                        selected = filtered
                    else
                        local found = false

                        for _, value in ipairs(values) do
                            if tostring(value)
                                == tostring(selected) then
                                found = true
                                break
                            end
                        end

                        if not found then
                            selected = values[1]
                        end
                    end

                    selectedLabel.Text =
                        GetSelectedText()
                end

                function object:SetValue(value, callCallback)
                    if multi then
                        selected = {}

                        if type(value) == "table" then
                            for _, item in ipairs(value) do
                                table.insert(selected, item)
                            end
                        elseif value ~= nil then
                            table.insert(selected, value)
                        end

                        selectedLabel.Text =
                            GetSelectedText()

                        if callCallback ~= false
                            and typeof(dropdownConfig.Callback) ==
                                "function" then

                            local result = {}

                            for _, item in ipairs(selected) do
                                table.insert(result, item)
                            end

                            task.spawn(
                                dropdownConfig.Callback,
                                result
                            )
                        end
                    else
                        selected = value

                        selectedLabel.Text =
                            GetSelectedText()

                        if callCallback ~= false
                            and typeof(dropdownConfig.Callback) ==
                                "function" then

                            task.spawn(
                                dropdownConfig.Callback,
                                value
                            )
                        end
                    end
                end

                function object:GetValue()
                    if multi then
                        local result = {}

                        for _, value in ipairs(selected) do
                            table.insert(result, value)
                        end

                        return result
                    end

                    return selected
                end

                function object:GetValues()
                    return values
                end

                function object:IsMulti()
                    return multi
                end

                Register(
                    root,
                    title,
                    desc
                )

                return object
            end

            return Section
        end

        table.insert(
            Window.Tabs,
            Tab
        )

        if not Window.ActiveTab then
            Tab:Select()
        end

        return Tab
    end

    --====================================================
    -- STORE WINDOW
    --====================================================

    DarkyUI._Window = Window

    -- This is the icon source for future notifications.
    if config.Image ~= nil then
        DarkyUI.CurrentImage = config.Image
    end

    --====================================================
    -- OPEN MAIN UI
    --====================================================

    if not Window._KeyLocked then
        main.Size = UDim2.fromOffset(
            WINDOW_WIDTH,
            0
        )

        Tween(
            main,
            MED,
            {
                Size = UDim2.fromOffset(
                    WINDOW_WIDTH,
                    WINDOW_HEIGHT
                )
            }
        )
    end

    return Window
end

return DarkyUI
