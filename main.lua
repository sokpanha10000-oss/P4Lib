--========================================================
-- DarkyUI - Single File Roblox UI Library
--========================================================
--
-- Main:
--   • 550x340 window
--   • PC + mobile dragging
--   • draggable floating minimize button
--   • minimize / restore / destroy
--   • square corners
--   • search bar
--   • profile + username
--   • Lucide icons + Roblox asset IDs
--   • tabs
--   • auto-sized sections (NO section Size property)
--   • automatic page scrolling
--   • button / toggle / slider / input / dropdown
--   • searchable + scrollable dropdown popup
--
-- Themes:
--   Red, BlueSky, White, Yellow, Green, Purple, Orange
--   Theme changes affect ONLY Toggle + Slider colors
--   in the main UI. KeySystem uses the selected theme
--   for its accent/submit state.
--
-- Extra:
--   DarkyUI:SetTheme("BlueSky")
--   DarkyUI:Notify({Title="Success", Content="...", Duration=3})
--========================================================

local DarkyUI = {}

--========================================================
-- SERVICES
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--========================================================
-- CONSTANTS
--========================================================

local UI_NAME = "DarkyUI"
local WINDOW_SIZE = UDim2.fromOffset(550, 340)

local BASE = {
    Background = Color3.fromRGB(18, 18, 21),
    Background2 = Color3.fromRGB(23, 23, 27),
    Panel = Color3.fromRGB(29, 29, 34),
    Panel2 = Color3.fromRGB(35, 35, 41),
    Text = Color3.fromRGB(245, 245, 247),
    SubText = Color3.fromRGB(160, 160, 170),
    Muted = Color3.fromRGB(105, 105, 115),
    Border = Color3.fromRGB(52, 52, 61),
    Danger = Color3.fromRGB(235, 75, 85),
    Warning = Color3.fromRGB(245, 185, 70),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local THEMES = {
    BlueSky = {
        Accent = Color3.fromRGB(70, 125, 255),
        Accent2 = Color3.fromRGB(95, 150, 255),
    },
    Red = {
        Accent = Color3.fromRGB(225, 65, 75),
        Accent2 = Color3.fromRGB(245, 95, 105),
    },
    White = {
        Accent = Color3.fromRGB(215, 215, 220),
        Accent2 = Color3.fromRGB(250, 250, 252),
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
DarkyUI._ThemeObjects = {}

local FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MED = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

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
        return
    end
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function Stroke(parent, color, thickness)
    return New("UIStroke", {
        Parent = parent,
        Color = color or BASE.Border,
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

local function RegisterThemeObject(object)
    table.insert(DarkyUI._ThemeObjects, object)
    return object
end

local function Theme()
    return THEMES[DarkyUI.CurrentTheme] or THEMES.BlueSky
end

--========================================================
-- HTTP / LOADSTRING
--========================================================

local function Http(url)
    local methods = {
        function()
            return game:HttpGet(url)
        end,
        function()
            return request({ Url = url, Method = "GET" }).Body
        end,
        function()
            return http_request({ Url = url, Method = "GET" }).Body
        end,
    }

    for _, method in ipairs(methods) do
        local ok, result = pcall(method)
        if ok and result and result ~= "" then
            return result
        end
    end
    return nil
end

local function LoadStringFn()
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

    if env.IsUI and env.Loadstring and env.Get then
        local ok, result = pcall(function()
            return env.Loadstring(env.Get(LUCIDE_URL))()
        end)
        if ok and type(result) == "table" then
            return result
        end
    end

    local source = Http(LUCIDE_URL)
    local loader = LoadStringFn()

    if source and loader then
        local ok, result = pcall(function()
            return loader(source)()
        end)
        if ok and type(result) == "table" then
            return result
        end
    end

    return {}
end

DarkyUI.Icons = {
    lucide = LoadLucide(),
}

local function ResolveIcon(icon)
    if icon == nil then
        return nil
    end

    if typeof(icon) == "number" then
        return AssetId(icon)
    end

    if typeof(icon) ~= "string" then
        return nil
    end

    if icon:match("^https?://") then
        return icon
    end

    if icon:match("^rbxasset") or icon:match("^%d+$") then
        return AssetId(icon)
    end

    local direct = DarkyUI.Icons.lucide[icon]
    if direct then
        return AssetId(tostring(direct))
    end

    local lower = icon:lower()
    for key, value in pairs(DarkyUI.Icons.lucide) do
        if tostring(key):lower() == lower then
            return AssetId(tostring(value))
        end
    end

    return nil
end

local function Icon(parent, icon, size, position, zIndex)
    local image = ResolveIcon(icon)
    if not image then
        return nil
    end

    return New("ImageLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Position = position,
        Size = UDim2.fromOffset(size, size),
        Image = image,
        ImageColor3 = BASE.Text,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = zIndex or 10,
    })
end

local function ProfileImage()
    local result = ""
    pcall(function()
        result = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end)
    return result
end

--========================================================
-- THEME API
--========================================================

function DarkyUI:SetTheme(name)
    if type(name) ~= "string" then
        return false
    end

    local normalized
    for themeName in pairs(THEMES) do
        if themeName:lower() == name:lower() then
            normalized = themeName
            break
        end
    end

    if not normalized then
        return false
    end

    DarkyUI.CurrentTheme = normalized

    for index = #DarkyUI._ThemeObjects, 1, -1 do
        local item = DarkyUI._ThemeObjects[index]

        if type(item) == "function" then
            local ok = pcall(item, normalized, THEMES[normalized])
            if not ok then
                table.remove(DarkyUI._ThemeObjects, index)
            end
        elseif typeof(item) == "Instance" and not item.Parent then
            table.remove(DarkyUI._ThemeObjects, index)
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

    local title = tostring(config.Title or "DarkyUI")
    local content = tostring(config.Content or "")
    local duration = tonumber(config.Duration) or 3

    local gui = CoreGui:FindFirstChild(UI_NAME)
    if not gui then
        gui = New("ScreenGui", {
            Name = UI_NAME,
            Parent = CoreGui,
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 999999,
        })
    end

    local holder = gui:FindFirstChild("Notifications")
    if not holder then
        holder = New("Frame", {
            Parent = gui,
            Name = "Notifications",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 16),
            Size = UDim2.new(0, 300, 1, -32),
            BackgroundTransparency = 1,
            ZIndex = 3000,
        })
        New("UIListLayout", {
            Parent = holder,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        })
    end

    local notice = New("Frame", {
        Parent = holder,
        Size = UDim2.fromOffset(300, 66),
        BackgroundColor3 = BASE.Background2,
        BorderSizePixel = 0,
        ZIndex = 3001,
    })
    Stroke(notice, BASE.Border, 1)

    local accent = New("Frame", {
        Parent = notice,
        Size = UDim2.fromOffset(3, 66),
        BackgroundColor3 = Theme().Accent,
        BorderSizePixel = 0,
        ZIndex = 3002,
    })

    local image = DarkyUI.CurrentImage
    if image then
        local img = Icon(notice, image, 38, UDim2.fromOffset(11, 14), 3003)
        if not img then
            img = New("ImageLabel", {
                Parent = notice,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(11, 14),
                Size = UDim2.fromOffset(38, 38),
                Image = AssetId(image),
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 3003,
            })
        end
    end

    local textX = image and 58 or 14

    New("TextLabel", {
        Parent = notice,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(textX, 9),
        Size = UDim2.new(1, -textX - 10, 0, 20),
        Text = title,
        TextColor3 = BASE.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3004,
    })

    New("TextLabel", {
        Parent = notice,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(textX, 30),
        Size = UDim2.new(1, -textX - 10, 0, 27),
        Text = content,
        TextColor3 = BASE.SubText,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3004,
    })

    notice.Size = UDim2.fromOffset(0, 66)
    Tween(notice, MED, { Size = UDim2.fromOffset(300, 66) })

    local alive = true
    local function destroyNotice()
        if not alive then
            return
        end
        alive = false
        Tween(notice, FAST, { Size = UDim2.fromOffset(0, 66) })
        task.delay(0.15, function()
            if notice and notice.Parent then
                notice:Destroy()
            end
        end)
    end

    task.delay(math.max(duration, 0.1), destroyNotice)

    return {
        Close = destroyNotice,
        Instance = notice,
    }
end

--========================================================
-- KEY SYSTEM CREATION HELPER
--========================================================

local function MakeKeySystem(DarkyUIObject, config)
    config = config or {}

    local keySystem = {
        Destroyed = false,
        Cancelled = false,
    }

    local title = tostring(config.Title or "Access Required")
    local note = tostring(config.Note or "")
    local url = tostring(config.URL or "")
    local save = config.SaveKey == true
    local thumbnail = config.Thumbnail or {}
    local fileName = "DarkyUI_Key.txt"

    local gui = CoreGui:FindFirstChild(UI_NAME)
    if not gui then
        gui = New("ScreenGui", {
            Name = UI_NAME,
            Parent = CoreGui,
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 999999,
        })
    end

    local overlay = New("Frame", {
        Parent = gui,
        Name = "KeySystem",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = BASE.Black,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 2000,
    })

    local main = New("Frame", {
        Parent = overlay,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(480, 260),
        BackgroundColor3 = BASE.Background,
        BorderSizePixel = 0,
        ZIndex = 2001,
    })
    Stroke(main, BASE.Border, 1)

    local header = New("Frame", {
        Parent = main,
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = BASE.Background2,
        BorderSizePixel = 0,
        ZIndex = 2002,
    })
    Stroke(header, BASE.Border, 1)

    New("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 7),
        Size = UDim2.new(1, -30, 0, 22),
        Text = title,
        TextColor3 = BASE.Text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2003,
    })

    New("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 30),
        Size = UDim2.new(1, -30, 0, 17),
        Text = note,
        TextColor3 = BASE.SubText,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2003,
    })

    local content = New("Frame", {
        Parent = main,
        Position = UDim2.fromOffset(0, 56),
        Size = UDim2.new(1, 0, 1, -56),
        BackgroundTransparency = 1,
        ZIndex = 2002,
    })

    -- Left thumbnail
    local thumb = New("Frame", {
        Parent = content,
        Position = UDim2.fromOffset(13, 14),
        Size = UDim2.fromOffset(145, 147),
        BackgroundColor3 = BASE.Panel,
        BorderSizePixel = 0,
        ZIndex = 2003,
    })
    Stroke(thumb, BASE.Border, 1)

    if thumbnail.Image then
        local thumbImage = New("ImageLabel", {
            Parent = thumb,
            Position = UDim2.fromOffset(7, 7),
            Size = UDim2.new(1, -14, 0, 105),
            BackgroundColor3 = BASE.Panel2,
            BorderSizePixel = 0,
            Image = AssetId(tostring(thumbnail.Image)),
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 2004,
        })
        Stroke(thumbImage, BASE.Border, 1)
    else
        local blank = New("Frame", {
            Parent = thumb,
            Position = UDim2.fromOffset(7, 7),
            Size = UDim2.new(1, -14, 0, 105),
            BackgroundColor3 = BASE.Panel2,
            BorderSizePixel = 0,
            ZIndex = 2004,
        })
        Stroke(blank, BASE.Border, 1)
    end

    New("TextLabel", {
        Parent = thumb,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 117),
        Size = UDim2.new(1, -16, 0, 22),
        Text = tostring(thumbnail.Title or "Premium Member"),
        TextColor3 = BASE.Text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2005,
    })

    -- Right side
    local area = New("Frame", {
        Parent = content,
        Position = UDim2.fromOffset(170, 14),
        Size = UDim2.new(1, -183, 0, 147),
        BackgroundColor3 = BASE.Panel,
        BorderSizePixel = 0,
        ZIndex = 2003,
    })
    Stroke(area, BASE.Border, 1)

    New("TextLabel", {
        Parent = area,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 10),
        Size = UDim2.new(1, -22, 0, 20),
        Text = "Enter your access key",
        TextColor3 = BASE.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2004,
    })

    New("TextLabel", {
        Parent = area,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 31),
        Size = UDim2.new(1, -22, 0, 17),
        Text = "Paste your key below to continue.",
        TextColor3 = BASE.SubText,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2004,
    })

    local inputHolder = New("Frame", {
        Parent = area,
        Position = UDim2.fromOffset(10, 58),
        Size = UDim2.new(1, -20, 0, 38),
        BackgroundColor3 = BASE.Panel2,
        BorderSizePixel = 0,
        ZIndex = 2005,
    })
    Stroke(inputHolder, BASE.Border, 1)
    local keyIcon = Icon(inputHolder, "key-round", 16, UDim2.fromOffset(10, 11), 2006)

    local input = New("TextBox", {
        Parent = inputHolder,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(34, 0),
        Size = UDim2.new(1, -42, 1, 0),
        PlaceholderText = "Enter key...",
        PlaceholderColor3 = BASE.Muted,
        Text = "",
        TextColor3 = BASE.Text,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2006,
    })

    local status = New("TextLabel", {
        Parent = content,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(13, 225),
        Size = UDim2.new(1, -26, 0, 20),
        Text = "",
        TextColor3 = BASE.SubText,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 2006,
    })

    local themeObjects = {}

    local function applyTheme(themeName, colors)
        if keyIcon and keyIcon.Parent then
            keyIcon.ImageColor3 = colors.Accent2
        end
        local submitButton = themeObjects.submit
        if submitButton and submitButton.Parent then
            submitButton.BackgroundColor3 = colors.Accent
        end
        local submitStroke = themeObjects.submitStroke
        if submitStroke and submitStroke.Parent then
            submitStroke.Color = colors.Accent2
        end
        themeObjects.theme = themeName
    end

    local function makeKeyButton(position, bg, iconName, text)
        local button = New("TextButton", {
            Parent = content,
            Position = position,
            Size = UDim2.fromOffset(108, 40),
            BackgroundColor3 = bg,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 2005,
        })
        local buttonStroke = Stroke(button, BASE.Border, 1)
        local buttonIcon = Icon(button, iconName, 16, UDim2.fromOffset(13, 12), 2006)
        if buttonIcon and iconName == "x" then
            buttonIcon.ImageColor3 = BASE.Danger
        end
        New("TextLabel", {
            Parent = button,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(37, 0),
            Size = UDim2.new(1, -42, 1, 0),
            Text = text,
            TextColor3 = bg == BASE.Panel and BASE.Text or BASE.White,
            TextSize = 10,
            Font = bg == BASE.Panel and Enum.Font.GothamMedium or Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2006,
        })
        return button, buttonStroke
    end

    local cancel = makeKeyButton(
        UDim2.fromOffset(13, 176),
        BASE.Panel,
        "x",
        "Cancel"
    )

    local getKey = makeKeyButton(
        UDim2.new(0.5, -54, 0, 176),
        BASE.Panel,
        "key",
        "Get Key"
    )

    local submit, submitStroke = makeKeyButton(
        UDim2.new(1, -121, 0, 176),
        Theme().Accent,
        "arrow-right",
        "Submit"
    )

    themeObjects.submit = submit
    themeObjects.submitStroke = submitStroke
    applyTheme(DarkyUIObject.CurrentTheme, Theme())

    RegisterThemeObject(function(themeName, colors)
        if overlay and overlay.Parent then
            applyTheme(themeName, colors)
        end
    end)

    local function validate(key)
        if typeof(config.KeyValidator) ~= "function" then
            return false
        end
        local ok, result = pcall(config.KeyValidator, key)
        return ok and result == true
    end

    local function saveKey(key)
        if not save or typeof(writefile) ~= "function" then
            return
        end
        pcall(function()
            writefile(fileName, key)
        end)
    end

    local function readKey()
        if not save or typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
            return nil
        end
        local ok, exists = pcall(isfile, fileName)
        if not ok or not exists then
            return nil
        end
        local success, saved = pcall(readfile, fileName)
        if success and saved and saved ~= "" then
            return saved
        end
        return nil
    end

    local function done()
        if keySystem.Destroyed then
            return
        end
        keySystem.Destroyed = true
        if overlay and overlay.Parent then
            overlay:Destroy()
        end
    end

    local busy = false

    local function submitKey()
        if busy or keySystem.Destroyed then
            return
        end
        busy = true

        local key = input.Text
        if key == "" then
            status.Text = "Please enter a key."
            status.TextColor3 = BASE.Warning
            busy = false
            return
        end

        status.Text = "Checking key..."
        status.TextColor3 = BASE.SubText

        if validate(key) then
            status.Text = "Key accepted!"
            status.TextColor3 = Theme().Accent2
            saveKey(key)
            task.delay(0.3, function()
                if overlay and overlay.Parent then
                    done()
                end
            end)
        else
            status.Text = "Invalid key."
            status.TextColor3 = BASE.Danger
        end

        busy = false
    end

    cancel.MouseButton1Click:Connect(function()
        keySystem.Cancelled = true
        done()
    end)

    getKey.MouseButton1Click:Connect(function()
        if url == "" then
            status.Text = "Key URL is not configured."
            status.TextColor3 = BASE.Danger
            return
        end

        local copied = false
        local methods = {
            function() setclipboard(url) end,
            function() toclipboard(url) end,
            function()
                if syn and syn.clipboard then
                    syn.clipboard = url
                else
                    error("clipboard unavailable")
                end
            end,
        }

        for _, method in ipairs(methods) do
            local ok = pcall(method)
            if ok then
                copied = true
                break
            end
        end

        status.Text = copied and "Key URL copied." or url
        status.TextColor3 = copied and Theme().Accent2 or BASE.SubText
    end)

    submit.MouseButton1Click:Connect(submitKey)

    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            submitKey()
        end
    end)

    local saved = readKey()
    if saved then
        input.Text = saved
        task.spawn(function()
            if validate(saved) then
                done()
            end
        end)
    end

    main.Size = UDim2.fromOffset(480, 0)
    Tween(main, MED, { Size = UDim2.fromOffset(480, 260) })

    function keySystem:GetKey()
        return input.Text
    end

    function keySystem:SetKey(value)
        input.Text = tostring(value or "")
    end

    function keySystem:Submit()
        submitKey()
    end

    function keySystem:Destroy()
        done()
    end

    function keySystem:IsDestroyed()
        return keySystem.Destroyed == true
    end

    return keySystem
end

--========================================================
-- KEY SYSTEM PUBLIC API
--========================================================

function DarkyUI:CreateKeySystem(config)
    return MakeKeySystem(self, config)
end

--========================================================
-- WINDOW
--========================================================

function DarkyUI:CreateWindow(config)
    config = config or {}

    pcall(function()
        local old = CoreGui:FindFirstChild(UI_NAME)
        if old then
            old:Destroy()
        end
    end)

    -- The most recently created window image becomes the
    -- global image used automatically by notifications.
    if config.Image ~= nil then
        DarkyUI.CurrentImage = config.Image
    end

    local W = {
        Title = tostring(config.Title or "DarkyUI"),
        Subtitle = tostring(config.Subtitle or ""),
        Image = config.Image,
        SearchEnabled = config.SearchBar == true,
        UserConfig = config.User or {},
        Tabs = {},
        Elements = {},
        ActiveTab = nil,
        Minimized = false,
        Destroyed = false,
    }

    local Gui = New("ScreenGui", {
        Name = UI_NAME,
        Parent = CoreGui,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999,
    })

    W.Gui = Gui

    --====================================================
    -- FLOATING BUTTON
    --====================================================

    local Floating = New("TextButton", {
        Parent = Gui,
        Name = "FloatingButton",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 18, 0.5, 0),
        Size = UDim2.fromOffset(52, 52),
        BackgroundColor3 = BASE.Panel,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Active = true,
        Text = "",
        Visible = false,
        ZIndex = 500,
    })
    Stroke(Floating, BASE.Border, 1)

    local FIcon = Icon(
        Floating,
        W.Image or "layout-dashboard",
        24,
        UDim2.new(0.5, -12, 0.5, -12),
        501
    )

    if not FIcon then
        New("TextLabel", {
            Parent = Floating,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = W.Title:sub(1, 1):upper(),
            TextColor3 = BASE.Text,
            TextSize = 20,
            Font = Enum.Font.GothamBold,
            ZIndex = 501,
        })
    end

    --====================================================
    -- MAIN WINDOW
    --====================================================

    local Main = New("Frame", {
        Parent = Gui,
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = WINDOW_SIZE,
        BackgroundColor3 = BASE.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
    })
    W.Main = Main
    Stroke(Main, BASE.Border, 1)

    --====================================================
    -- TOP BAR
    --====================================================

    local Top = New("Frame", {
        Parent = Main,
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = BASE.Background2,
        BorderSizePixel = 0,
        ZIndex = 20,
    })
    Stroke(Top, BASE.Border, 1)

    -- Main drag
    do
        local dragging = false
        local dragInput
        local dragStart
        local startPosition

        local function update(input)
            if not dragging then
                return
            end
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end

        Top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragInput = input
                dragStart = input.Position
                startPosition = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        Top.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
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
    -- WINDOW ICON / TITLE
    --====================================================

    local IconHolder = New("Frame", {
        Parent = Top,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 9),
        Size = UDim2.fromOffset(40, 40),
        ZIndex = 21,
    })

    local WIcon = Icon(
        IconHolder,
        W.Image or "layout-dashboard",
        24,
        UDim2.new(0.5, -12, 0.5, -12),
        22
    )

    if not WIcon then
        New("TextLabel", {
            Parent = IconHolder,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = W.Title:sub(1, 1):upper(),
            TextColor3 = BASE.Text,
            TextSize = 19,
            Font = Enum.Font.GothamBold,
            ZIndex = 22,
        })
    end

    local Title = New("TextLabel", {
        Parent = Top,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(58, 7),
        Size = UDim2.new(1, -225, 0, 23),
        Text = W.Title,
        TextColor3 = BASE.Text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 22,
    })

    local Subtitle = New("TextLabel", {
        Parent = Top,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(58, 30),
        Size = UDim2.new(1, -225, 0, 17),
        Text = W.Subtitle,
        TextColor3 = BASE.SubText,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 22,
    })

    --====================================================
    -- SEARCH
    --====================================================

    local SearchBox

    if W.SearchEnabled then
        local searchFrame = New("Frame", {
            Parent = Top,
            Position = UDim2.new(1, -205, 0, 11),
            Size = UDim2.fromOffset(125, 36),
            BackgroundColor3 = BASE.Panel,
            BorderSizePixel = 0,
            ZIndex = 25,
        })
        Stroke(searchFrame, BASE.Border, 1)
        Icon(searchFrame, "search", 15, UDim2.fromOffset(9, 10), 26)

        SearchBox = New("TextBox", {
            Parent = searchFrame,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(30, 0),
            Size = UDim2.new(1, -35, 1, 0),
            PlaceholderText = "Search",
            PlaceholderColor3 = BASE.Muted,
            Text = "",
            TextColor3 = BASE.Text,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 26,
        })
        W.SearchBox = SearchBox
    end

    --====================================================
    -- MINIMIZE / CLOSE
    --====================================================

    local MinBtn = New("TextButton", {
        Parent = Top,
        Position = UDim2.new(1, -75, 0, 9),
        Size = UDim2.fromOffset(30, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 30,
    })
    Icon(MinBtn, "minus", 17, UDim2.new(0.5, -8, 0.5, -8), 31)

    local CloseBtn = New("TextButton", {
        Parent = Top,
        Position = UDim2.new(1, -40, 0, 9),
        Size = UDim2.fromOffset(30, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 30,
    })
    local closeIcon = Icon(CloseBtn, "x", 18, UDim2.new(0.5, -9, 0.5, -9), 31)
    if closeIcon then
        closeIcon.ImageColor3 = BASE.Danger
    end

    --====================================================
    -- BODY
    --====================================================

    local Body = New("Frame", {
        Parent = Main,
        Position = UDim2.fromOffset(0, 58),
        Size = UDim2.new(1, 0, 1, -58),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 10,
    })

    local TabBar = New("ScrollingFrame", {
        Parent = Body,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.fromOffset(145, 266),
        BackgroundColor3 = BASE.Background2,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = BASE.Border,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 11,
    })
    Stroke(TabBar, BASE.Border, 1)
    Padding(TabBar, 6, 6, 6, 6)

    New("UIListLayout", {
        Parent = TabBar,
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    })

    --====================================================
    -- USER CARD
    --====================================================

    if W.UserConfig.Profile or W.UserConfig.Username then
        local profile = New("Frame", {
            Parent = TabBar,
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = BASE.Panel,
            BorderSizePixel = 0,
            LayoutOrder = -100,
            ZIndex = 13,
        })
        Stroke(profile, BASE.Border, 1)

        if W.UserConfig.Profile then
            local avatar = New("ImageLabel", {
                Parent = profile,
                Position = UDim2.fromOffset(7, 7),
                Size = UDim2.fromOffset(36, 36),
                BackgroundColor3 = BASE.Panel2,
                BorderSizePixel = 0,
                Image = ProfileImage(),
                ZIndex = 14,
            })
            Stroke(avatar, BASE.Border, 1)
        end

        if W.UserConfig.Username then
            local x = W.UserConfig.Profile and 49 or 8

            New("TextLabel", {
                Parent = profile,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(x, 7),
                Size = UDim2.new(1, -x - 5, 0, 19),
                Text = LocalPlayer.DisplayName,
                TextColor3 = BASE.Text,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 14,
            })

            New("TextLabel", {
                Parent = profile,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(x, 26),
                Size = UDim2.new(1, -x - 5, 0, 16),
                Text = "@" .. LocalPlayer.Name,
                TextColor3 = BASE.SubText,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 14,
            })
        end
    end

    local Content = New("Frame", {
        Parent = Body,
        Position = UDim2.fromOffset(160, 8),
        Size = UDim2.new(1, -168, 1, -16),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 11,
    })

    --====================================================
    -- SEARCH SYSTEM
    --====================================================

    local function SearchElements(text)
        text = tostring(text or ""):lower()

        for _, element in ipairs(W.Elements) do
            if element.Root and element.Root.Parent then
                if text == "" then
                    element.Root.Visible = true
                else
                    local t = tostring(element.Title or ""):lower()
                    local d = tostring(element.Desc or ""):lower()
                    element.Root.Visible =
                        t:find(text, 1, true) ~= nil
                        or d:find(text, 1, true) ~= nil
                end
            end
        end
    end

    if SearchBox then
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            SearchElements(SearchBox.Text)
        end)
    end

    --====================================================
    -- WINDOW METHODS
    --====================================================

    function W:Minimize()
        if self.Destroyed or self.Minimized then
            return
        end

        self.Minimized = true

        Tween(Main, MED, {
            Size = UDim2.fromOffset(550, 0),
        })

        task.delay(0.22, function()
            if self.Destroyed then
                return
            end

            Main.Visible = false
            Floating.Visible = true
            Floating.Size = UDim2.fromOffset(0, 0)

            Tween(Floating, MED, {
                Size = UDim2.fromOffset(52, 52),
            })
        end)
    end

    function W:Restore()
        if self.Destroyed or not self.Minimized then
            return
        end

        self.Minimized = false
        Floating.Visible = false
        Main.Visible = true
        Main.Size = UDim2.fromOffset(550, 0)

        Tween(Main, MED, {
            Size = WINDOW_SIZE,
        })
    end

    function W:Destroy()
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        if Gui then
            Gui:Destroy()
        end
    end

    function W:SetTitle(value)
        self.Title = tostring(value)
        Title.Text = self.Title
    end

    function W:SetSubtitle(value)
        self.Subtitle = tostring(value)
        Subtitle.Text = self.Subtitle
    end

    function W:SetIcon(icon)
        self.Image = icon
        DarkyUI.CurrentImage = icon
        local asset = ResolveIcon(icon)
        if asset then
            if WIcon then
                WIcon.Image = asset
            end
            if FIcon then
                FIcon.Image = asset
            end
        end
    end

    function W:SetVisible(value)
        value = value == true
        if value then
            if self.Minimized then
                self:Restore()
            else
                Main.Visible = true
            end
        else
            Main.Visible = false
        end
    end

    function W:GetActiveTab()
        return self.ActiveTab
    end

    MinBtn.MouseButton1Click:Connect(function()
        W:Minimize()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        W:Destroy()
    end)

    --====================================================
    -- FLOATING BUTTON DRAGGING
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

            local delta = input.Position - dragStart

            if delta.Magnitude > 7 then
                moved = true
            end

            Floating.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end

        Floating.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                dragging = true
                moved = false
                dragStart = input.Position
                startPosition = Floating.Position
                dragInput = input

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if not moved then
                            W:Restore()
                        end
                    end
                end)
            end
        end)

        Floating.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
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
    -- TAB CREATION
    --====================================================

    function W:CreateTab(tabConfig)
        tabConfig = tabConfig or {}

        local T = {
            Title = tostring(tabConfig.Title or "Tab"),
            Icon = tabConfig.Icon or "circle",
            Sections = {},
        }

        local tabButton = New("TextButton", {
            Parent = TabBar,
            Name = "TabButton",
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = BASE.Panel,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = #W.Tabs + 1,
            ZIndex = 15,
        })
        Stroke(tabButton, BASE.Border, 1)

        local selectedBar = New("Frame", {
            Parent = tabButton,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(3, 38),
            BackgroundColor3 = BASE.Accent,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 16,
        })

        local iconHolder = New("Frame", {
            Parent = tabButton,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.fromOffset(38, 38),
            ZIndex = 16,
        })

        local tabIcon = Icon(
            iconHolder,
            T.Icon,
            17,
            UDim2.new(0.5, -8, 0.5, -8),
            17
        )

        if not tabIcon then
            New("TextLabel", {
                Parent = iconHolder,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = T.Title:sub(1, 1):upper(),
                TextColor3 = BASE.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                ZIndex = 17,
            })
        end

        local tabText = New("TextLabel", {
            Parent = tabButton,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(47, 0),
            Size = UDim2.new(1, -53, 1, 0),
            Text = T.Title,
            TextColor3 = BASE.SubText,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 17,
        })

        local page = New("ScrollingFrame", {
            Parent = Content,
            Name = "Page_" .. tostring(#W.Tabs + 1),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = BASE.Border,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            ZIndex = 12,
        })
        Padding(page, 0, 5, 0, 8)

        New("UIListLayout", {
            Parent = page,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 7),
        })

        T.Button = tabButton
        T.Page = page
        T._SelectedBar = selectedBar
        T._TabText = tabText

        function T:Select()
            for _, other in ipairs(W.Tabs) do
                local active = other == T

                other.Page.Visible = active
                other.Selected = active

                if other._SelectedBar then
                    other._SelectedBar.Visible = active
                end

                if other._TabText then
                    other._TabText.TextColor3 = active and BASE.Text or BASE.SubText
                end

                Tween(other.Button, FAST, {
                    BackgroundColor3 = active and BASE.Panel2 or BASE.Panel,
                })
            end

            W.ActiveTab = T

            if SearchBox then
                SearchElements(SearchBox.Text)
            end
        end

        tabButton.MouseButton1Click:Connect(function()
            T:Select()
        end)

        tabButton.MouseEnter:Connect(function()
            if not T.Selected then
                Tween(tabButton, FAST, { BackgroundColor3 = BASE.Panel2 })
            end
        end)

        tabButton.MouseLeave:Connect(function()
            if not T.Selected then
                Tween(tabButton, FAST, { BackgroundColor3 = BASE.Panel })
            end
        end)

        --================================================
        -- SECTION
        --================================================

        function T:CreateSection(sectionConfig)
            sectionConfig = sectionConfig or {}

            local S = {
                Title = tostring(sectionConfig.Title or "Section"),
            }

            -- NO Size PROPERTY.
            -- The section height is driven entirely by its contents.
            local section = New("Frame", {
                Parent = page,
                Name = "Section_" .. S.Title,
                Size = UDim2.new(1, -2, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = BASE.Background2,
                BorderSizePixel = 0,
                LayoutOrder = #T.Sections + 1,
                ZIndex = 13,
            })
            Stroke(section, BASE.Border, 1)
            Padding(section, 9, 9, 8, 9)

            New("TextLabel", {
                Parent = section,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = S.Title,
                TextColor3 = BASE.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 14,
            })

            local holder = New("Frame", {
                Parent = section,
                Position = UDim2.fromOffset(0, 25),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 14,
            })

            New("UIListLayout", {
                Parent = holder,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
            })

            S.Frame = section
            S.Holder = holder
            S.Layout = holder:FindFirstChildOfClass("UIListLayout")

            table.insert(T.Sections, S)

            local function Register(root, title, desc, kind)
                local entry = {
                    Root = root,
                    Title = title,
                    Desc = desc,
                    Kind = kind,
                }
                table.insert(W.Elements, entry)
                return entry
            end

            --=============================================
            -- BUTTON
            --=============================================

            function S:CreateButton(elementConfig)
                elementConfig = elementConfig or {}

                local title = tostring(elementConfig.Title or "Button")
                local desc = tostring(elementConfig.Desc or "")
                local locked = elementConfig.Locked == true

                local root = New("Frame", {
                    Parent = holder,
                    Size = UDim2.new(1, 0, 0, desc ~= "" and 53 or 40),
                    BackgroundColor3 = BASE.Panel,
                    BorderSizePixel = 0,
                    ZIndex = 15,
                })
                Stroke(root, BASE.Border, 1)

                local click = New("TextButton", {
                    Parent = root,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    AutoButtonColor = false,
                    Text = "",
                    Active = not locked,
                    ZIndex = 17,
                })

                New("TextLabel", {
                    Parent = root,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(11, desc ~= "" and 7 or 0),
                    Size = UDim2.new(1, -55, 0, 20),
                    Text = title,
                    TextColor3 = locked and BASE.Muted or BASE.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 18,
                })

                if desc ~= "" then
                    New("TextLabel", {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 28),
                        Size = UDim2.new(1, -20, 0, 16),
                        Text = desc,
                        TextColor3 = BASE.SubText,
                        TextSize = 9,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 18,
                    })
                end

                if locked then
                    local lock = Icon(root, "lock", 14, UDim2.new(1, -25, 0.5, -7), 18)
                    if lock then
                        lock.ImageColor3 = BASE.Warning
                    end
                else
                    Icon(root, "chevron-right", 15, UDim2.new(1, -28, 0.5, -7), 18)

                    click.MouseEnter:Connect(function()
                        Tween(root, FAST, { BackgroundColor3 = BASE.Panel2 })
                    end)

                    click.MouseLeave:Connect(function()
                        Tween(root, FAST, { BackgroundColor3 = BASE.Panel })
                    end)

                    click.MouseButton1Click:Connect(function()
                        if typeof(elementConfig.Callback) == "function" then
                            task.spawn(elementConfig.Callback)
                        end
                    end)
                end

                local api = { Root = root }
                Register(root, title, desc, "Button")
                return api
            end

            --=============================================
            -- TOGGLE
            --=============================================

            function S:CreateToggle(elementConfig)
                elementConfig = elementConfig or {}

                local title = tostring(elementConfig.Title or "Toggle")
                local desc = tostring(elementConfig.Desc or "")
                local state = elementConfig.Value == true

                local root = New("Frame", {
                    Parent = holder,
                    Size = UDim2.new(1, 0, 0, desc ~= "" and 57 or 44),
                    BackgroundColor3 = BASE.Panel,
                    BorderSizePixel = 0,
                    ZIndex = 15,
                })
                Stroke(root, BASE.Border, 1)

                New("TextLabel", {
                    Parent = root,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(11, desc ~= "" and 7 or 0),
                    Size = UDim2.new(1, -75, 0, 20),
                    Text = title,
                    TextColor3 = BASE.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 18,
                })

                if desc ~= "" then
                    New("TextLabel", {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 28),
                        Size = UDim2.new(1, -80, 0, 16),
                        Text = desc,
                        TextColor3 = BASE.SubText,
                        TextSize = 9,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 18,
                    })
                end

                local switch = New("TextButton", {
                    Parent = root,
                    Position = UDim2.new(1, -58, 0.5, -11),
                    Size = UDim2.fromOffset(44, 22),
                    BackgroundColor3 = BASE.Panel2,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                    ZIndex = 19,
                })
                Stroke(switch, BASE.Border, 1)

                local knob = New("Frame", {
                    Parent = switch,
                    Position = UDim2.fromOffset(3, 3),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundColor3 = BASE.Muted,
                    BorderSizePixel = 0,
                    ZIndex = 20,
                })

                local entry
                local api = { Root = root }

                local function update(animated)
                    local colors = Theme()
                    local switchColor = state and colors.Accent or BASE.Panel2
                    local knobColor = state and BASE.White or BASE.Muted
                    local knobPos = state
                        and UDim2.new(1, -19, 0.5, -8)
                        or UDim2.fromOffset(3, 3)

                    if animated then
                        Tween(switch, FAST, { BackgroundColor3 = switchColor })
                        Tween(knob, FAST, { Position = knobPos, BackgroundColor3 = knobColor })
                    else
                        switch.BackgroundColor3 = switchColor
                        knob.Position = knobPos
                        knob.BackgroundColor3 = knobColor
                    end
                end

                RegisterThemeObject(function()
                    if root and root.Parent then
                        update(true)
                    end
                end)

                entry = Register(root, title, desc, "Toggle")

                function api:SetValue(value, callCallback)
                    state = value == true
                    update(true)
                    if callCallback ~= false and typeof(elementConfig.Callback) == "function" then
                        task.spawn(elementConfig.Callback, state)
                    end
                end

                function api:GetValue()
                    return state
                end

                switch.MouseButton1Click:Connect(function()
                    api:SetValue(not state, true)
                end)

                update(false)
                return api
            end

            --=============================================
            -- SLIDER
            --=============================================

            function S:CreateSlider(elementConfig)
                elementConfig = elementConfig or {}

                local title = tostring(elementConfig.Title or "Slider")
                local desc = tostring(elementConfig.Desc or "")
                local range = elementConfig.Value or {}

                local minimum = tonumber(range.Min) or 0
                local maximum = tonumber(range.Max) or 100
                local current = tonumber(range.Default) or minimum
                local step = tonumber(elementConfig.Step) or 1

                local root = New("Frame", {
                    Parent = holder,
                    Size = UDim2.new(1, 0, 0, desc ~= "" and 67 or 56),
                    BackgroundColor3 = BASE.Panel,
                    BorderSizePixel = 0,
                    ZIndex = 15,
                })
                Stroke(root, BASE.Border, 1)

                New("TextLabel", {
                    Parent = root,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(11, 7),
                    Size = UDim2.new(1, -75, 0, 20),
                    Text = title,
                    TextColor3 = BASE.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 18,
                })

                local valueLabel = New("TextLabel", {
                    Parent = root,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -60, 0, 7),
                    Size = UDim2.fromOffset(50, 20),
                    Text = tostring(current),
                    TextColor3 = Theme().Accent2,
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 18,
                })

                if desc ~= "" then
                    New("TextLabel", {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 27),
                        Size = UDim2.new(1, -20, 0, 16),
                        Text = desc,
                        TextColor3 = BASE.SubText,
                        TextSize = 9,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    })
                end

                local holderFrame = New("Frame", {
                    Parent = root,
                    Position = UDim2.fromOffset(11, desc ~= "" and 49 or 38),
                    Size = UDim2.new(1, -22, 0, 10),
                    BackgroundTransparency = 1,
                    ZIndex = 18,
                })

                local track = New("Frame", {
                    Parent = holderFrame,
                    Position = UDim2.new(0, 0, 0.5, -3),
                    Size = UDim2.new(1, 0, 0, 6),
                    BackgroundColor3 = BASE.Panel2,
                    BorderSizePixel = 0,
                    ZIndex = 18,
                })
                Stroke(track, BASE.Border, 1)

                local fill = New("Frame", {
                    Parent = track,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = Theme().Accent,
                    BorderSizePixel = 0,
                    ZIndex = 19,
                })

                local knob = New("Frame", {
                    Parent = track,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    BackgroundColor3 = BASE.White,
                    BorderSizePixel = 0,
                    ZIndex = 20,
                })

                local drag = New("TextButton", {
                    Parent = holderFrame,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    AutoButtonColor = false,
                    Text = "",
                    ZIndex = 21,
                })

                local draggingSlider = false
                local api = { Root = root }

                local function round(value)
                    value = math.clamp(value, minimum, maximum)
                    local stepped = math.floor(((value - minimum) / step) + 0.5) * step
                    return math.clamp(minimum + stepped, minimum, maximum)
                end

                local function render(animated)
                    current = round(current)
                    local percent = (current - minimum) / math.max(maximum - minimum, 0.00001)
                    local colors = Theme()

                    valueLabel.Text = tostring(current)

                    if animated then
                        Tween(fill, FAST, {
                            Size = UDim2.new(percent, 0, 1, 0),
                            BackgroundColor3 = colors.Accent,
                        })
                        Tween(knob, FAST, {
                            Position = UDim2.new(percent, 0, 0.5, 0),
                        })
                        Tween(valueLabel, FAST, {
                            TextColor3 = colors.Accent2,
                        })
                    else
                        fill.Size = UDim2.new(percent, 0, 1, 0)
                        fill.BackgroundColor3 = colors.Accent
                        knob.Position = UDim2.new(percent, 0, 0.5, 0)
                        valueLabel.TextColor3 = colors.Accent2
                    end
                end

                local function setFromX(x, callback)
                    local startX = holderFrame.AbsolutePosition.X
                    local width = holderFrame.AbsoluteSize.X
                    local alpha = math.clamp((x - startX) / math.max(width, 1), 0, 1)
                    current = minimum + ((maximum - minimum) * alpha)
                    render(true)

                    if callback and typeof(elementConfig.Callback) == "function" then
                        task.spawn(elementConfig.Callback, current)
                    end
                end

                drag.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = true
                        setFromX(input.Position.X, true)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if not draggingSlider then
                        return
                    end
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                        setFromX(input.Position.X, true)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = false
                    end
                end)

                RegisterThemeObject(function()
                    if root and root.Parent then
                        render(true)
                    end
                end)

                Register(root, title, desc, "Slider")

                function api:SetValue(value, callCallback)
                    current = tonumber(value) or minimum
                    render(true)
                    if callCallback ~= false and typeof(elementConfig.Callback) == "function" then
                        task.spawn(elementConfig.Callback, current)
                    end
                end

                function api:GetValue()
                    return current
                end

                function api:SetRange(minimumValue, maximumValue, defaultValue)
                    minimum = tonumber(minimumValue) or minimum
                    maximum = tonumber(maximumValue) or maximum
                    if defaultValue ~= nil then
                        current = tonumber(defaultValue) or minimum
                    end
                    render(true)
                end

                render(false)
                return api
            end

            --=============================================
            -- INPUT
            --=============================================

            function S:CreateInput(elementConfig)
                elementConfig = elementConfig or {}

                local title = tostring(elementConfig.Title or "Input")
                local desc = tostring(elementConfig.Desc or "")
                local root = New("Frame", {
                    Parent = holder,
                    Size = UDim2.new(1, 0, 0, desc ~= "" and 75 or 62),
                    BackgroundColor3 = BASE.Panel,
                    BorderSizePixel = 0,
                    ZIndex = 15,
                })
                Stroke(root, BASE.Border, 1)

                New("TextLabel", {
                    Parent = root,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(11, 7),
                    Size = UDim2.new(1, -20, 0, 19),
                    Text = title,
                    TextColor3 = BASE.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 18,
                })

                local y = 27
                if desc ~= "" then
                    New("TextLabel", {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 27),
                        Size = UDim2.new(1, -20, 0, 16),
                        Text = desc,
                        TextColor3 = BASE.SubText,
                        TextSize = 9,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    })
                    y = 46
                end

                local box = New("Frame", {
                    Parent = root,
                    Position = UDim2.fromOffset(10, y),
                    Size = UDim2.new(1, -20, 0, 26),
                    BackgroundColor3 = BASE.Panel2,
                    BorderSizePixel = 0,
                    ZIndex = 18,
                })
                Stroke(box, BASE.Border, 1)

                local textBox = New("TextBox", {
                    Parent = box,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -16, 1, 0),
                    Text = elementConfig.Value or "",
                    PlaceholderText = elementConfig.Placeholder or "",
                    PlaceholderColor3 = BASE.Muted,
                    TextColor3 = BASE.Text,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 19,
                })

                textBox.FocusLost:Connect(function(enterPressed)
                    if typeof(elementConfig.Callback) == "function" then
                        task.spawn(elementConfig.Callback, textBox.Text, enterPressed)
                    end
                end)

                local api = { Root = root, TextBox = textBox }
                Register(root, title, desc, "Input")

                function api:GetValue()
                    return textBox.Text
                end

                function api:SetValue(value)
                    textBox.Text = tostring(value or "")
                end

                return api
            end

            --=============================================
            -- DROPDOWN
            --=============================================

            function S:CreateDropdown(elementConfig)
                elementConfig = elementConfig or {}

                local title = tostring(elementConfig.Title or "Dropdown")
                local desc = tostring(elementConfig.Desc or "")
                local values = elementConfig.Values or {}
                local selected = elementConfig.Value

                if selected == nil and #values > 0 then
                    selected = values[1]
                end

                local root = New("Frame", {
                    Parent = holder,
                    Size = UDim2.new(1, 0, 0, desc ~= "" and 72 or 57),
                    BackgroundColor3 = BASE.Panel,
                    BorderSizePixel = 0,
                    ZIndex = 15,
                })
                Stroke(root, BASE.Border, 1)

                New("TextLabel", {
                    Parent = root,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(11, desc ~= "" and 7 or 6),
                    Size = UDim2.new(1, -180, 0, 20),
                    Text = title,
                    TextColor3 = BASE.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 18,
                })

                if desc ~= "" then
                    New("TextLabel", {
                        Parent = root,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(11, 28),
                        Size = UDim2.new(1, -22, 0, 16),
                        Text = desc,
                        TextColor3 = BASE.SubText,
                        TextSize = 9,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 18,
                    })
                end

                local display = New("TextButton", {
                    Parent = root,
                    Position = UDim2.new(1, -165, 0.5, -14),
                    Size = UDim2.fromOffset(154, 28),
                    BackgroundColor3 = BASE.Panel2,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                    ZIndex = 20,
                })
                Stroke(display, BASE.Border, 1)

                local selectedLabel = New("TextLabel", {
                    Parent = display,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(9, 0),
                    Size = UDim2.new(1, -35, 1, 0),
                    Text = tostring(selected or "Select..."),
                    TextColor3 = BASE.Text,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 21,
                })

                Icon(display, "chevrons-up-down", 15, UDim2.new(1, -22, 0.5, -7), 21)

                local overlay

                local function closeDropdown()
                    if not overlay then
                        return
                    end

                    local old = overlay
                    overlay = nil
                    local popup = old:FindFirstChild("Popup")

                    if popup then
                        Tween(popup, FAST, {
                            Size = UDim2.fromOffset(360, 0),
                        })
                    end

                    task.delay(0.14, function()
                        if old then
                            old:Destroy()
                        end
                    end)
                end

                local function openDropdown()
                    if overlay then
                        closeDropdown()
                        return
                    end

                    overlay = New("Frame", {
                        Parent = Gui,
                        Name = "DropdownOverlay",
                        Size = UDim2.fromScale(1, 1),
                        BackgroundColor3 = BASE.Black,
                        BackgroundTransparency = 0.5,
                        BorderSizePixel = 0,
                        ZIndex = 1000,
                    })

                    local outside = New("TextButton", {
                        Parent = overlay,
                        Size = UDim2.fromScale(1, 1),
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 1000,
                    })

                    local popup = New("Frame", {
                        Parent = overlay,
                        Name = "Popup",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(360, 0),
                        BackgroundColor3 = BASE.Background,
                        BorderSizePixel = 0,
                        ZIndex = 1002,
                    })
                    Stroke(popup, BASE.Border, 1)

                    outside.MouseButton1Click:Connect(function()
                        closeDropdown()
                    end)

                    local header = New("Frame", {
                        Parent = popup,
                        Size = UDim2.new(1, 0, 0, 50),
                        BackgroundColor3 = BASE.Background2,
                        BorderSizePixel = 0,
                        ZIndex = 1003,
                    })

                    New("TextLabel", {
                        Parent = header,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(12, 0),
                        Size = UDim2.new(1, -55, 1, 0),
                        Text = title,
                        TextColor3 = BASE.Text,
                        TextSize = 12,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1004,
                    })

                    local modalClose = New("TextButton", {
                        Parent = header,
                        Position = UDim2.new(1, -42, 0, 7),
                        Size = UDim2.fromOffset(32, 36),
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 1005,
                    })

                    local modalCloseIcon = Icon(
                        modalClose,
                        "x",
                        18,
                        UDim2.new(0.5, -9, 0.5, -9),
                        1006
                    )
                    if modalCloseIcon then
                        modalCloseIcon.ImageColor3 = BASE.Danger
                    end

                    modalClose.MouseButton1Click:Connect(function()
                        closeDropdown()
                    end)

                    local searchFrame = New("Frame", {
                        Parent = popup,
                        Position = UDim2.fromOffset(10, 58),
                        Size = UDim2.new(1, -20, 0, 34),
                        BackgroundColor3 = BASE.Panel,
                        BorderSizePixel = 0,
                        ZIndex = 1003,
                    })
                    Stroke(searchFrame, BASE.Border, 1)
                    Icon(searchFrame, "search", 15, UDim2.fromOffset(9, 9), 1004)

                    local modalSearch = New("TextBox", {
                        Parent = searchFrame,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(31, 0),
                        Size = UDim2.new(1, -38, 1, 0),
                        PlaceholderText = "Search option...",
                        PlaceholderColor3 = BASE.Muted,
                        Text = "",
                        TextColor3 = BASE.Text,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        ClearTextOnFocus = false,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1005,
                    })

                    local list = New("ScrollingFrame", {
                        Parent = popup,
                        Position = UDim2.fromOffset(10, 100),
                        Size = UDim2.new(1, -20, 0, 160),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ScrollBarThickness = 4,
                        ScrollBarImageColor3 = BASE.Border,
                        CanvasSize = UDim2.new(),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        ZIndex = 1003,
                    })
                    Padding(list, 1, 4, 1, 4)
                    New("UIListLayout", {
                        Parent = list,
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 4),
                    })

                    local count = New("TextLabel", {
                        Parent = popup,
                        Position = UDim2.new(0, 12, 1, -31),
                        Size = UDim2.new(1, -24, 0, 20),
                        BackgroundTransparency = 1,
                        Text = tostring(#values) .. " options",
                        TextColor3 = BASE.Muted,
                        TextSize = 9,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 1004,
                    })

                    local function selectOption(value)
                        selected = value
                        selectedLabel.Text = tostring(value)
                        closeDropdown()

                        if typeof(elementConfig.Callback) == "function" then
                            task.spawn(elementConfig.Callback, value)
                        end
                    end

                    local function render()
                        for _, child in ipairs(list:GetChildren()) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end

                        local filter = modalSearch.Text:lower()

                        for index, value in ipairs(values) do
                            local valueText = tostring(value)
                            local match = filter == ""
                                or valueText:lower():find(filter, 1, true) ~= nil

                            if match then
                                local option = New("TextButton", {
                                    Parent = list,
                                    Size = UDim2.new(1, 0, 0, 35),
                                    BackgroundColor3 = BASE.Panel,
                                    BorderSizePixel = 0,
                                    AutoButtonColor = false,
                                    Text = "",
                                    LayoutOrder = index,
                                    ZIndex = 1005,
                                })
                                Stroke(option, BASE.Border, 1)

                                New("TextLabel", {
                                    Parent = option,
                                    BackgroundTransparency = 1,
                                    Position = UDim2.fromOffset(10, 0),
                                    Size = UDim2.new(1, -45, 1, 0),
                                    Text = valueText,
                                    TextColor3 = tostring(value) == tostring(selected)
                                        and Theme().Accent2
                                        or BASE.Text,
                                    TextSize = 10,
                                    Font = Enum.Font.GothamMedium,
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    TextTruncate = Enum.TextTruncate.AtEnd,
                                    ZIndex = 1006,
                                })

                                if tostring(value) == tostring(selected) then
                                    local check = Icon(
                                        option,
                                        "check",
                                        15,
                                        UDim2.new(1, -27, 0.5, -7),
                                        1007
                                    )
                                    if check then
                                        check.ImageColor3 = Theme().Accent2
                                    end
                                end

                                option.MouseEnter:Connect(function()
                                    Tween(option, FAST, { BackgroundColor3 = BASE.Panel2 })
                                end)
                                option.MouseLeave:Connect(function()
                                    Tween(option, FAST, { BackgroundColor3 = BASE.Panel })
                                end)
                                option.MouseButton1Click:Connect(function()
                                    selectOption(value)
                                end)
                            end
                        end

                        count.Text = tostring(#values) .. " options"
                    end

                    modalSearch:GetPropertyChangedSignal("Text"):Connect(render)
                    render()

                    Tween(popup, MED, {
                        Size = UDim2.fromOffset(360, 260),
                    })
                end

                display.MouseButton1Click:Connect(openDropdown)

                local api = { Root = root }
                Register(root, title, desc, "Dropdown")

                function api:Refresh(newValues)
                    if type(newValues) ~= "table" then
                        return
                    end
                    values = newValues

                    local found = false
                    for _, value in ipairs(values) do
                        if tostring(value) == tostring(selected) then
                            found = true
                            break
                        end
                    end

                    if not found then
                        selected = values[1]
                    end

                    selectedLabel.Text = tostring(selected or "Select...")
                end

                function api:SetValue(value, callCallback)
                    selected = value
                    selectedLabel.Text = tostring(value)
                    if callCallback ~= false and typeof(elementConfig.Callback) == "function" then
                        task.spawn(elementConfig.Callback, value)
                    end
                end

                function api:GetValue()
                    return selected
                end

                function api:GetValues()
                    return values
                end

                return api
            end

            return S
        end

        table.insert(W.Tabs, T)

        if not W.ActiveTab then
            T:Select()
        end

        return T
    end

    Main.Size = UDim2.fromOffset(550, 0)
    Tween(Main, MED, { Size = WINDOW_SIZE })

    return W
end

return DarkyUI
