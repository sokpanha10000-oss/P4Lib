--[[
    DarkyUI
    Single-file Roblox UI Library
    Features:
    - 550x340 default window
    - Draggable desktop + mobile/touch
    - Square corners
    - Minimize -> floating square button
    - Close -> completely destroys UI
    - SearchBar
    - User profile + username
    - Tabs with Lucide or Asset ID icons
    - Sections
    - Button / Toggle / Slider / Input / Dropdown
    - Automatic scrolling when content is too large
    - Centered Dropdown modal with search + scrolling
    - Dropdown:Refresh(...)
    - Smooth animations
]]

local DarkyUI = {}

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local LIBRARY_NAME = "DarkyUI"

local COLORS = {
    Background = Color3.fromRGB(18, 18, 21),
    Background2 = Color3.fromRGB(24, 24, 28),
    Panel = Color3.fromRGB(28, 28, 33),
    Panel2 = Color3.fromRGB(34, 34, 40),

    Text = Color3.fromRGB(245, 245, 247),
    SubText = Color3.fromRGB(160, 160, 170),
    Muted = Color3.fromRGB(105, 105, 115),

    Border = Color3.fromRGB(52, 52, 61),

    Accent = Color3.fromRGB(70, 125, 255),
    Accent2 = Color3.fromRGB(92, 145, 255),

    Success = Color3.fromRGB(80, 205, 125),
    Danger = Color3.fromRGB(235, 75, 85),
    Warning = Color3.fromRGB(245, 185, 70),

    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local TWEEN_FAST = TweenInfo.new(
    0.14,
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

local TWEEN_MED = TweenInfo.new(
    0.22,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.Out
)

--==================================================
-- HELPERS
--==================================================

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

local function AddStroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Parent = parent,
        Color = color or COLORS.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function AddPadding(parent, left, right, top, bottom)
    return New("UIPadding", {
        Parent = parent,
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    })
end

local function IsAssetId(value)
    if typeof(value) ~= "string" then
        return false
    end

    return value:match("^rbxassetid://")
        or value:match("^%d+$")
end

local function NormalizeAssetId(value)
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

--==================================================
-- LUCIDE
--==================================================

local LUCIDE_URL =
    "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"

local function SafeLoadString(source)
    if typeof(loadstring) == "function" then
        return loadstring(source)
    end

    if typeof(load) == "function" then
        return load(source)
    end

    return nil
end

local function GetHttp(url)
    local requesters = {
        function()
            return game:HttpGet(url)
        end,

        function()
            return request({
                Url = url,
                Method = "GET"
            }).Body
        end,

        function()
            return http_request({
                Url = url,
                Method = "GET"
            }).Body
        end,
    }

    for _, requester in ipairs(requesters) do
        local ok, result = pcall(requester)

        if ok and result and result ~= "" then
            return result
        end
    end

    return nil
end

local function LoadLucide()
    -- Supports environments that already provide these functions.
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

    -- Normal executor-style fallback.
    local source = GetHttp(LUCIDE_URL)

    if source then
        local loader = SafeLoadString(source)

        if loader then
            local ok, result = pcall(loader)

            if ok and type(result) == "table" then
                return result
            end
        end
    end

    return {}
end

local Icons = {
    lucide = LoadLucide()
}

DarkyUI.Icons = Icons

local function ResolveIcon(icon)
    if icon == nil then
        return nil
    end

    if typeof(icon) == "number" then
        return "rbxassetid://" .. tostring(icon)
    end

    if typeof(icon) ~= "string" then
        return nil
    end

    -- Direct asset ID.
    if IsAssetId(icon) then
        return NormalizeAssetId(icon)
    end

    -- URL / image URI.
    if icon:match("^rbxasset") or icon:match("^https?://") then
        return icon
    end

    -- Lucide name.
    local lucideIcon = Icons.lucide[icon]

    if lucideIcon then
        return NormalizeAssetId(tostring(lucideIcon))
    end

    -- Case-insensitive fallback.
    local lower = icon:lower()

    for name, value in pairs(Icons.lucide) do
        if tostring(name):lower() == lower then
            return NormalizeAssetId(tostring(value))
        end
    end

    return nil
end

local function CreateIcon(parent, icon, size, position, zIndex)
    local asset = ResolveIcon(icon)

    if not asset then
        return nil
    end

    local image = New("ImageLabel", {
        Parent = parent,

        BackgroundTransparency = 1,

        Size = UDim2.fromOffset(size or 18, size or 18),
        Position = position or UDim2.new(),

        Image = asset,

        ImageColor3 = COLORS.Text,

        ScaleType = Enum.ScaleType.Fit,

        ZIndex = zIndex or 10,
    })

    return image
end

--==================================================
-- LOCAL PLAYER PROFILE
--==================================================

local function GetProfileImage()
    local image = ""

    pcall(function()
        local content, ready = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )

        if ready and content then
            image = content
        else
            image = content or ""
        end
    end)

    return image
end

--==================================================
-- WINDOW
--==================================================

function DarkyUI:CreateWindow(config)
    config = config or {}

    local Window = {}

    Window.Title = config.Title or "DarkyUI"
    Window.Subtitle = config.Subtitle or ""
    Window.Image = config.Image
    Window.SearchEnabled = config.SearchBar == true
    Window.UserConfig = config.User or {}
    Window.Tabs = {}
    Window.Elements = {}
    Window.ActiveTab = nil
    Window.Destroyed = false
    Window.Minimized = false

    -- Remove previous DarkyUI.
    pcall(function()
        local CoreGui = game:GetService("CoreGui")

        for _, child in ipairs(CoreGui:GetChildren()) do
            if child.Name == LIBRARY_NAME then
                child:Destroy()
            end
        end
    end)

    --==================================================
    -- SCREEN GUI
    --==================================================

    local ScreenGui = New("ScreenGui", {
        Name = LIBRARY_NAME,
        Parent = game:GetService("CoreGui"),

        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999,
    })

    Window.Gui = ScreenGui

    --==================================================
    -- FLOATING MINIMIZE BUTTON
    --==================================================

    local FloatingButton = New("TextButton", {
        Parent = ScreenGui,

        Name = "FloatingButton",

        AnchorPoint = Vector2.new(0, 0.5),

        Position = UDim2.new(0, 18, 0.5, 0),

        Size = UDim2.fromOffset(52, 52),

        BackgroundColor3 = COLORS.Panel,

        BorderSizePixel = 0,

        AutoButtonColor = false,

        Text = "",

        Visible = false,

        ZIndex = 100,
    })

    AddStroke(FloatingButton, COLORS.Border, 1)

    local FloatingIcon = CreateIcon(
        FloatingButton,
        Window.Image or "layout-dashboard",
        24,
        UDim2.new(0.5, -12, 0.5, -12),
        101
    )

    if not FloatingIcon then
        local fallback = New("TextLabel", {
            Parent = FloatingButton,

            BackgroundTransparency = 1,

            Size = UDim2.fromScale(1, 1),

            Text = "D",

            TextColor3 = COLORS.Text,

            TextSize = 20,

            Font = Enum.Font.GothamBold,

            ZIndex = 101,
        })

        FloatingIcon = fallback
    end

    --==================================================
    -- MAIN WINDOW
    --==================================================

    local Main = New("Frame", {
        Parent = ScreenGui,

        Name = "Main",

        AnchorPoint = Vector2.new(0.5, 0.5),

        Position = UDim2.fromScale(0.5, 0.5),

        Size = UDim2.fromOffset(550, 340),

        BackgroundColor3 = COLORS.Background,

        BorderSizePixel = 0,

        ClipsDescendants = true,

        ZIndex = 10,
    })

    Window.Main = Main

    AddStroke(Main, COLORS.Border, 1)

    --==================================================
    -- TOP BAR
    --==================================================

    local TopBar = New("Frame", {
        Parent = Main,

        Name = "TopBar",

        Size = UDim2.new(1, 0, 0, 58),

        BackgroundColor3 = COLORS.Background2,

        BorderSizePixel = 0,

        ZIndex = 20,
    })

    AddStroke(TopBar, COLORS.Border, 1)

    -- Title icon.
    local WindowIconHolder = New("Frame", {
        Parent = TopBar,

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(13, 10),

        Size = UDim2.fromOffset(38, 38),

        ZIndex = 21,
    })

    local WindowIcon = CreateIcon(
        WindowIconHolder,
        Window.Image or "layout-dashboard",
        24,
        UDim2.new(0.5, -12, 0.5, -12),
        22
    )

    if not WindowIcon then
        New("TextLabel", {
            Parent = WindowIconHolder,

            BackgroundTransparency = 1,

            Size = UDim2.fromScale(1, 1),

            Text = string.sub(Window.Title, 1, 1):upper(),

            Font = Enum.Font.GothamBold,

            TextSize = 19,

            TextColor3 = COLORS.Text,

            ZIndex = 22,
        })
    end

    -- Title.
    New("TextLabel", {
        Parent = TopBar,

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(58, 8),

        Size = UDim2.new(1, -220, 0, 22),

        Text = Window.Title,

        TextColor3 = COLORS.Text,

        TextSize = 15,

        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left,

        TextTruncate = Enum.TextTruncate.AtEnd,

        ZIndex = 22,
    })

    New("TextLabel", {
        Parent = TopBar,

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(58, 29),

        Size = UDim2.new(1, -220, 0, 18),

        Text = Window.Subtitle,

        TextColor3 = COLORS.SubText,

        TextSize = 11,

        Font = Enum.Font.Gotham,

        TextXAlignment = Enum.TextXAlignment.Left,

        TextTruncate = Enum.TextTruncate.AtEnd,

        ZIndex = 22,
    })

    --==================================================
    -- SEARCH BAR
    --==================================================

    local SearchFrame

    if Window.SearchEnabled then
        SearchFrame = New("Frame", {
            Parent = TopBar,

            Position = UDim2.new(1, -205, 0, 11),

            Size = UDim2.fromOffset(125, 36),

            BackgroundColor3 = COLORS.Panel,

            BorderSizePixel = 0,

            ZIndex = 25,
        })

        AddStroke(SearchFrame, COLORS.Border, 1)

        CreateIcon(
            SearchFrame,
            "search",
            15,
            UDim2.fromOffset(9, 10),
            26
        )

        local SearchBox = New("TextBox", {
            Parent = SearchFrame,

            BackgroundTransparency = 1,

            Position = UDim2.fromOffset(30, 0),

            Size = UDim2.new(1, -35, 1, 0),

            PlaceholderText = "Search",

            PlaceholderColor3 = COLORS.Muted,

            Text = "",

            TextColor3 = COLORS.Text,

            TextSize = 11,

            Font = Enum.Font.Gotham,

            TextXAlignment = Enum.TextXAlignment.Left,

            ClearTextOnFocus = false,

            ZIndex = 26,
        })

        Window.SearchBox = SearchBox
    end

    --==================================================
    -- CONTROL BUTTONS
    --==================================================

    local MinimizeButton = New("TextButton", {
        Parent = TopBar,

        Position = UDim2.new(1, -75, 0, 9),

        Size = UDim2.fromOffset(30, 38),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        AutoButtonColor = false,

        Text = "",

        ZIndex = 30,
    })

    CreateIcon(
        MinimizeButton,
        "minus",
        17,
        UDim2.new(0.5, -8, 0.5, -8),
        31
    )

    local CloseButton = New("TextButton", {
        Parent = TopBar,

        Position = UDim2.new(1, -40, 0, 9),

        Size = UDim2.fromOffset(30, 38),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        AutoButtonColor = false,

        Text = "",

        ZIndex = 30,
    })

    local CloseIcon = CreateIcon(
        CloseButton,
        "x",
        18,
        UDim2.new(0.5, -9, 0.5, -9),
        31
    )

    if CloseIcon then
        CloseIcon.ImageColor3 = COLORS.Danger
    end

    --==================================================
    -- BODY
    --==================================================

    local Body = New("Frame", {
        Parent = Main,

        Name = "Body",

        Position = UDim2.fromOffset(0, 58),

        Size = UDim2.new(1, 0, 1, -58),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        ZIndex = 10,
    })

    --==================================================
    -- TAB BAR
    --==================================================

    local TabBar = New("ScrollingFrame", {
        Parent = Body,

        Name = "TabBar",

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
    })

    AddStroke(TabBar, COLORS.Border, 1)

    AddPadding(TabBar, 6, 6, 6, 6)

    local TabLayout = New("UIListLayout", {
        Parent = TabBar,

        FillDirection = Enum.FillDirection.Vertical,

        HorizontalAlignment = Enum.HorizontalAlignment.Center,

        SortOrder = Enum.SortOrder.LayoutOrder,

        Padding = UDim.new(0, 5),
    })

    --==================================================
    -- SEARCH / USER PANEL
    --==================================================

    local ProfileHolder

    if Window.UserConfig.Profile or Window.UserConfig.Username then
        ProfileHolder = New("Frame", {
            Parent = TabBar,

            Size = UDim2.new(1, 0, 0, 50),

            BackgroundColor3 = COLORS.Panel,

            BorderSizePixel = 0,

            LayoutOrder = -100,
        })

        AddStroke(ProfileHolder, COLORS.Border, 1)

        if Window.UserConfig.Profile then
            local Avatar = New("ImageLabel", {
                Parent = ProfileHolder,

                Position = UDim2.fromOffset(7, 7),

                Size = UDim2.fromOffset(36, 36),

                BackgroundColor3 = COLORS.Panel2,

                BorderSizePixel = 0,

                Image = GetProfileImage(),

                ZIndex = 13,
            })

            AddStroke(Avatar, COLORS.Border, 1)
        end

        if Window.UserConfig.Username then
            local xPosition = Window.UserConfig.Profile and 49 or 8

            New("TextLabel", {
                Parent = ProfileHolder,

                BackgroundTransparency = 1,

                Position = UDim2.fromOffset(xPosition, 8),

                Size = UDim2.new(1, -xPosition - 5, 0, 18),

                Text = LocalPlayer.DisplayName,

                TextColor3 = COLORS.Text,

                TextSize = 11,

                Font = Enum.Font.GothamBold,

                TextXAlignment = Enum.TextXAlignment.Left,

                TextTruncate = Enum.TextTruncate.AtEnd,

                ZIndex = 13,
            })

            New("TextLabel", {
                Parent = ProfileHolder,

                BackgroundTransparency = 1,

                Position = UDim2.fromOffset(xPosition, 25),

                Size = UDim2.new(1, -xPosition - 5, 0, 16),

                Text = "@" .. LocalPlayer.Name,

                TextColor3 = COLORS.SubText,

                TextSize = 9,

                Font = Enum.Font.Gotham,

                TextXAlignment = Enum.TextXAlignment.Left,

                TextTruncate = Enum.TextTruncate.AtEnd,

                ZIndex = 13,
            })
        end
    end

    --==================================================
    -- CONTENT AREA
    --==================================================

    local Content = New("Frame", {
        Parent = Body,

        Position = UDim2.fromOffset(160, 8),

        Size = UDim2.new(1, -168, 1, -16),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        ZIndex = 11,
    })

    local ContentPages = {}

    --==================================================
    -- DRAGGING
    --==================================================

    do
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPosition = nil

        local function updateDrag(input)
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

        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                dragging = true
                dragStart = input.Position
                startPosition = Main.Position

                dragInput = input

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        TopBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then

                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput then
                updateDrag(input)
            end
        end)
    end

    --==================================================
    -- MINIMIZE / RESTORE
    --==================================================

    function Window:Minimize()
        if Window.Destroyed then
            return
        end

        Window.Minimized = true

        Tween(Main, TWEEN_MED, {
            Size = UDim2.fromOffset(550, 0)
        })

        task.delay(0.22, function()
            if Window.Destroyed then
                return
            end

            Main.Visible = false
            FloatingButton.Visible = true

            FloatingButton.Size = UDim2.fromOffset(0, 0)

            Tween(
                FloatingButton,
                TWEEN_MED,
                {
                    Size = UDim2.fromOffset(52, 52)
                }
            )
        end)
    end

    function Window:Restore()
        if Window.Destroyed then
            return
        end

        Window.Minimized = false

        FloatingButton.Visible = false

        Main.Visible = true

        Main.Size = UDim2.fromOffset(550, 0)

        Tween(
            Main,
            TWEEN_MED,
            {
                Size = UDim2.fromOffset(550, 340)
            }
        )
    end

    MinimizeButton.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)

    FloatingButton.MouseButton1Click:Connect(function()
        Window:Restore()
    end)

    --==================================================
    -- CLOSE / DELETE
    --==================================================

    function Window:Destroy()
        if Window.Destroyed then
            return
        end

        Window.Destroyed = true

        Tween(
            Main,
            TWEEN_MED,
            {
                Size = UDim2.fromOffset(550, 0)
            }
        )

        task.delay(0.23, function()
            if ScreenGui then
                ScreenGui:Destroy()
            end
        end)
    end

    CloseButton.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)

    --==================================================
    -- BUTTON ANIMATION
    --==================================================

    local function AddButtonHover(button, normalColor, hoverColor)
        button.MouseEnter:Connect(function()
            Tween(button, TWEEN_FAST, {
                BackgroundColor3 = hoverColor
            })
        end)

        button.MouseLeave:Connect(function()
            Tween(button, TWEEN_FAST, {
                BackgroundColor3 = normalColor
            })
        end)
    end

    --==================================================
    -- SEARCH SYSTEM
    --==================================================

    local function SearchElements(text)
        text = tostring(text or ""):lower()

        for _, element in ipairs(Window.Elements) do
            if element.Root and element.Root.Parent then
                if text == "" then
                    element.Root.Visible = true
                else
                    local title = tostring(element.Title or ""):lower()
                    local desc = tostring(element.Desc or ""):lower()

                    local visible =
                        title:find(text, 1, true) ~= nil
                        or desc:find(text, 1, true) ~= nil

                    element.Root.Visible = visible
                end
            end
        end
    end

    if Window.SearchBox then
        Window.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            SearchElements(Window.SearchBox.Text)
        end)
    end

    --==================================================
    -- TAB CREATION
    --==================================================

    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}

        local Tab = {}

        Tab.Title = tabConfig.Title or "Tab"
        Tab.Icon = tabConfig.Icon or "circle"

        local tabButton = New("TextButton", {
            Parent = TabBar,

            Name = "TabButton",

            Size = UDim2.new(1, 0, 0, 38),

            BackgroundColor3 = COLORS.Panel,

            BorderSizePixel = 0,

            AutoButtonColor = false,

            Text = "",

            LayoutOrder = #Window.Tabs + 1,

            ZIndex = 15,
        })

        AddStroke(tabButton, COLORS.Border, 1)

        local selectedBar = New("Frame", {
            Parent = tabButton,

            Position = UDim2.fromOffset(0, 0),

            Size = UDim2.fromOffset(3, 38),

            BackgroundColor3 = COLORS.Accent,

            BorderSizePixel = 0,

            Visible = false,

            ZIndex = 16,
        })

        local tabIconHolder = New("Frame", {
            Parent = tabButton,

            BackgroundTransparency = 1,

            Position = UDim2.fromOffset(10, 0),

            Size = UDim2.fromOffset(38, 38),

            ZIndex = 16,
        })

        CreateIcon(
            tabIconHolder,
            Tab.Icon,
            17,
            UDim2.new(0.5, -8, 0.5, -8),
            17
        )

        local tabText = New("TextLabel", {
            Parent = tabButton,

            BackgroundTransparency = 1,

            Position = UDim2.fromOffset(48, 0),

            Size = UDim2.new(1, -55, 1, 0),

            Text = Tab.Title,

            TextColor3 = COLORS.SubText,

            TextSize = 11,

            Font = Enum.Font.GothamMedium,

            TextXAlignment = Enum.TextXAlignment.Left,

            TextTruncate = Enum.TextTruncate.AtEnd,

            ZIndex = 17,
        })

        -- Page.
        local Page = New("ScrollingFrame", {
            Parent = Content,

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
        })

        AddPadding(Page, 0, 5, 0, 8)

        local PageLayout = New("UIListLayout", {
            Parent = Page,

            FillDirection = Enum.FillDirection.Vertical,

            SortOrder = Enum.SortOrder.LayoutOrder,

            Padding = UDim.new(0, 7),
        })

        Tab.Button = tabButton
        Tab.Page = Page
        Tab.Layout = PageLayout
        Tab.Sections = {}

        function Tab:Select()
            for _, otherTab in ipairs(Window.Tabs) do
                local otherSelected = otherTab == Tab

                otherTab.Page.Visible = otherSelected
                otherTab.Selected = otherSelected

                local otherBar =
                    otherTab.Button:FindFirstChildOfClass("Frame")

                if otherBar then
                    otherBar.Visible = otherSelected
                end

                local otherLabel = otherTab.Button:FindFirstChildOfClass("TextLabel")

                if otherLabel then
                    otherLabel.TextColor3 =
                        otherSelected and COLORS.Text or COLORS.SubText
                end

                if otherSelected then
                    Tween(
                        otherTab.Button,
                        TWEEN_FAST,
                        {
                            BackgroundColor3 = COLORS.Panel2
                        }
                    )
                else
                    Tween(
                        otherTab.Button,
                        TWEEN_FAST,
                        {
                            BackgroundColor3 = COLORS.Panel
                        }
                    )
                end
            end

            Window.ActiveTab = Tab

            -- Apply current search.
            if Window.SearchBox then
                SearchElements(Window.SearchBox.Text)
            end
        end

        tabButton.MouseButton1Click:Connect(function()
            Tab:Select()
        end)

        AddButtonHover(
            tabButton,
            COLORS.Panel,
            COLORS.Panel2
        )

        --==================================================
        -- SECTION
        --==================================================

        function Tab:CreateSection(sectionConfig)
            sectionConfig = sectionConfig or {}

            local Section = {}

            Section.Title = sectionConfig.Title or "Section"

            local requestedHeight = 0

            if sectionConfig.Size then
                pcall(function()
                    requestedHeight = sectionConfig.Size.Y.Offset
                end)
            end

            local SectionFrame = New("Frame", {
                Parent = Page,

                Name = "Section_" .. Section.Title,

                Size = UDim2.new(
                    1,
                    -2,
                    0,
                    math.max(requestedHeight, 70)
                ),

                AutomaticSize = Enum.AutomaticSize.Y,

                BackgroundColor3 = COLORS.Background2,

                BorderSizePixel = 0,

                LayoutOrder = #Tab.Sections + 1,

                ZIndex = 13,
            })

            AddStroke(SectionFrame, COLORS.Border, 1)

            AddPadding(
                SectionFrame,
                9,
                9,
                8,
                9
            )

            local SectionTitle = New("TextLabel", {
                Parent = SectionFrame,

                Size = UDim2.new(1, 0, 0, 20),

                BackgroundTransparency = 1,

                Text = Section.Title,

                TextColor3 = COLORS.Text,

                TextSize = 12,

                Font = Enum.Font.GothamBold,

                TextXAlignment = Enum.TextXAlignment.Left,

                ZIndex = 14,
            })

            local ElementHolder = New("Frame", {
                Parent = SectionFrame,

                Position = UDim2.fromOffset(0, 25),

                Size = UDim2.new(1, 0, 0, 0),

                AutomaticSize = Enum.AutomaticSize.Y,

                BackgroundTransparency = 1,

                BorderSizePixel = 0,

                ZIndex = 14,
            })

            local ElementLayout = New("UIListLayout", {
                Parent = ElementHolder,

                FillDirection = Enum.FillDirection.Vertical,

                SortOrder = Enum.SortOrder.LayoutOrder,

                Padding = UDim.new(0, 5),
            })

            Section.Frame = SectionFrame
            Section.Holder = ElementHolder
            Section.Layout = ElementLayout

            table.insert(Tab.Sections, Section)

            --==================================================
            -- REGISTER ELEMENT
            --==================================================

            local function RegisterElement(root, title, desc)
                local item = {
                    Root = root,
                    Title = title,
                    Desc = desc,
                }

                table.insert(Window.Elements, item)

                return item
            end

            --==================================================
            -- BUTTON
            --==================================================

            function Section:CreateButton(buttonConfig)
                buttonConfig = buttonConfig or {}

                local Button = {}

                local title =
                    buttonConfig.Title or "Button"

                local desc =
                    buttonConfig.Desc or ""

                local locked =
                    buttonConfig.Locked == true

                local root = New("Frame", {
                    Parent = ElementHolder,

                    Size = UDim2.new(1, 0, 0, desc ~= "" and 53 or 40),

                    BackgroundColor3 = COLORS.Panel,

                    BorderSizePixel = 0,

                    ZIndex = 15,
                })

                AddStroke(root, COLORS.Border, 1)

                local click = New("TextButton", {
                    Parent = root,

                    Size = UDim2.fromScale(1, 1),

                    BackgroundTransparency = 1,

                    BorderSizePixel = 0,

                    AutoButtonColor = false,

                    Text = "",

                    ZIndex = 17,
                })

                local titleLabel = New("TextLabel", {
                    Parent = root,

                    BackgroundTransparency = 1,

                    Position = UDim2.fromOffset(11, desc ~= "" and 7 or 0),

                    Size = UDim2.new(1, -55, 0, 20),

                    Text = title,

                    TextColor3 =
                        locked and COLORS.Muted or COLORS.Text,

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

                        TextColor3 = COLORS.SubText,

                        TextSize = 9,

                        Font = Enum.Font.Gotham,

                        TextXAlignment = Enum.TextXAlignment.Left,

                        TextTruncate = Enum.TextTruncate.AtEnd,

                        ZIndex = 18,
                    })
                end

                local arrow = CreateIcon(
                    root,
                    "chevron-right",
                    15,
                    UDim2.new(1, -30, 0.5, -7),
                    18
                )

                if arrow then
                    arrow.ImageColor3 = COLORS.SubText
                end

                if locked then
                    local lock = CreateIcon(
                        root,
                        "lock",
                        14,
                        UDim2.new(1, -53, 0.5, -7),
                        18
                    )

                    if lock then
                        lock.ImageColor3 = COLORS.Warning
                    end

                    click.Active = false
                else
                    click.MouseEnter:Connect(function()
                        Tween(
                            root,
                            TWEEN_FAST,
                            {
                                BackgroundColor3 = COLORS.Panel2
                            }
                        )
                    end)

                    click.MouseLeave:Connect(function()
                        Tween(
                            root,
                            TWEEN_FAST,
                            {
                                BackgroundColor3 = COLORS.Panel
                            }
                        )
                    end)

                    click.MouseButton1Click:Connect(function()
                        if typeof(buttonConfig.Callback) == "function" then
                            task.spawn(buttonConfig.Callback)
                        end
                    end)
                end

                Button.Root = root

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Button
            end

            --==================================================
            -- TOGGLE
            --==================================================

            function Section:CreateToggle(toggleConfig)
                toggleConfig = toggleConfig or {}

                local Toggle = {}

                local title =
                    toggleConfig.Title or "Toggle"

                local desc =
                    toggleConfig.Desc or ""

                local state =
                    toggleConfig.Value == true

                local root = New("Frame", {
                    Parent = ElementHolder,

                    Size = UDim2.new(1, 0, 0, desc ~= "" and 57 or 44),

                    BackgroundColor3 = COLORS.Panel,

                    BorderSizePixel = 0,

                    ZIndex = 15,
                })

                AddStroke(root, COLORS.Border, 1)

                New("TextLabel", {
                    Parent = root,

                    BackgroundTransparency = 1,

                    Position = UDim2.fromOffset(11, desc ~= "" and 7 or 0),

                    Size = UDim2.new(1, -75, 0, 20),

                    Text = title,

                    TextColor3 = COLORS.Text,

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

                        Size = UDim2.new(1, -80, 0, 17),

                        Text = desc,

                        TextColor3 = COLORS.SubText,

                        TextSize = 9,

                        Font = Enum.Font.Gotham,

                        TextXAlignment = Enum.TextXAlignment.Left,

                        TextTruncate = Enum.TextTruncate.AtEnd,

                        ZIndex = 18,
                    })
                end

                local switch = New("TextButton", {
                    Parent = root,

                    Position = UDim2.new(1, -59, 0.5, -11),

                    Size = UDim2.fromOffset(44, 22),

                    BackgroundColor3 = COLORS.Panel2,

                    BorderSizePixel = 0,

                    AutoButtonColor = false,

                    Text = "",

                    ZIndex = 19,
                })

                AddStroke(switch, COLORS.Border, 1)

                local knob = New("Frame", {
                    Parent = switch,

                    Position = UDim2.fromOffset(3, 3),

                    Size = UDim2.fromOffset(14, 14),

                    BackgroundColor3 = COLORS.SubText,

                    BorderSizePixel = 0,

                    ZIndex = 20,
                })

                local function UpdateToggle()
                    if state then
                        Tween(
                            switch,
                            TWEEN_FAST,
                            {
                                BackgroundColor3 = COLORS.Accent
                            }
                        )

                        Tween(
                            knob,
                            TWEEN_FAST,
                            {
                                Position = UDim2.new(
                                    1,
                                    -17,
                                    0.5,
                                    -7
                                ),

                                BackgroundColor3 = COLORS.White,
                            }
                        )
                    else
                        Tween(
                            switch,
                            TWEEN_FAST,
                            {
                                BackgroundColor3 = COLORS.Panel2
                            }
                        )

                        Tween(
                            knob,
                            TWEEN_FAST,
                            {
                                Position = UDim2.fromOffset(3, 3),

                                BackgroundColor3 = COLORS.SubText,
                            }
                        )
                    end
                end

                function Toggle:SetValue(value, callCallback)
                    state = value == true

                    UpdateToggle()

                    if callCallback ~= false
                        and typeof(toggleConfig.Callback) == "function" then

                        task.spawn(
                            toggleConfig.Callback,
                            state
                        )
                    end
                end

                function Toggle:GetValue()
                    return state
                end

                switch.MouseButton1Click:Connect(function()
                    Toggle:SetValue(not state, true)
                end)

                Toggle.Root = root

                UpdateToggle()

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Toggle
            end

            --==================================================
            -- SLIDER
            --==================================================

            function Section:CreateSlider(sliderConfig)
                sliderConfig = sliderConfig or {}

                local Slider = {}

                local title =
                    sliderConfig.Title or "Slider"

                local desc =
                    sliderConfig.Desc or ""

                local sliderValue =
                    sliderConfig.Value or {}

                local minimum =
                    tonumber(sliderValue.Min) or 0

                local maximum =
                    tonumber(sliderValue.Max) or 100

                local current =
                    tonumber(sliderValue.Default) or minimum

                local step =
                    tonumber(sliderConfig.Step) or 1

                local root = New("Frame", {
                    Parent = ElementHolder,

                    Size = UDim2.new(1, 0, 0, desc ~= "" and 67 or 56),

                    BackgroundColor3 = COLORS.Panel,

                    BorderSizePixel = 0,

                    ZIndex = 15,
                })

                AddStroke(root, COLORS.Border, 1)

                local titleLabel = New("TextLabel", {
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
                })

                local valueLabel = New("TextLabel", {
                    Parent = root,

                    BackgroundTransparency = 1,

                    Position = UDim2.new(1, -60, 0, 7),

                    Size = UDim2.fromOffset(48, 20),

                    Text = tostring(current),

                    TextColor3 = COLORS.Accent2,

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

                        TextColor3 = COLORS.SubText,

                        TextSize = 9,

                        Font = Enum.Font.Gotham,

                        TextXAlignment = Enum.TextXAlignment.Left,

                        ZIndex = 18,
                    })
                end

                local sliderHolder = New("Frame", {
                    Parent = root,

                    Position = UDim2.fromOffset(
                        11,
                        desc ~= "" and 49 or 38
                    ),

                    Size = UDim2.new(1, -22, 0, 10),

                    BackgroundTransparency = 1,

                    ZIndex = 18,
                })

                local track = New("Frame", {
                    Parent = sliderHolder,

                    Position = UDim2.new(0, 0, 0.5, -3),

                    Size = UDim2.new(1, 0, 0, 6),

                    BackgroundColor3 = COLORS.Panel2,

                    BorderSizePixel = 0,

                    ZIndex = 18,
                })

                AddStroke(track, COLORS.Border, 1)

                local fill = New("Frame", {
                    Parent = track,

                    Size = UDim2.new(0, 0, 1, 0),

                    BackgroundColor3 = COLORS.Accent,

                    BorderSizePixel = 0,

                    ZIndex = 19,
                })

                local knob = New("Frame", {
                    Parent = track,

                    AnchorPoint = Vector2.new(0.5, 0.5),

                    Position = UDim2.new(0, 0, 0.5, 0),

                    Size = UDim2.fromOffset(12, 12),

                    BackgroundColor3 = COLORS.White,

                    BorderSizePixel = 0,

                    ZIndex = 20,
                })

                local dragHandle = New("TextButton", {
                    Parent = sliderHolder,

                    BackgroundTransparency = 1,

                    Size = UDim2.fromScale(1, 1),

                    Text = "",

                    AutoButtonColor = false,

                    ZIndex = 21,
                })

                local function RoundStep(value)
                    value = math.clamp(value, minimum, maximum)

                    local stepped =
                        math.floor(
                            ((value - minimum) / step) + 0.5
                        ) * step

                    return math.clamp(
                        minimum + stepped,
                        minimum,
                        maximum
                    )
                end

                local function SetSliderFromX(x, callback)
                    local absoluteX =
                        sliderHolder.AbsolutePosition.X

                    local width =
                        sliderHolder.AbsoluteSize.X

                    local alpha =
                        math.clamp(
                            (x - absoluteX) / math.max(width, 1),
                            0,
                            1
                        )

                    current =
                        RoundStep(
                            minimum + ((maximum - minimum) * alpha)
                        )

                    local percent =
                        (current - minimum) /
                        math.max(maximum - minimum, 0.00001)

                    Tween(
                        fill,
                        TWEEN_FAST,
                        {
                            Size = UDim2.new(
                                percent,
                                0,
                                1,
                                0
                            )
                        }
                    )

                    Tween(
                        knob,
                        TWEEN_FAST,
                        {
                            Position = UDim2.new(
                                percent,
                                0,
                                0.5,
                                0
                            )
                        }
                    )

                    valueLabel.Text = tostring(current)

                    if callback
                        and typeof(sliderConfig.Callback) == "function" then

                        task.spawn(
                            sliderConfig.Callback,
                            current
                        )
                    end
                end

                local draggingSlider = false

                dragHandle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then

                        draggingSlider = true

                        SetSliderFromX(
                            input.Position.X,
                            true
                        )
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if not draggingSlider then
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then

                        SetSliderFromX(
                            input.Position.X,
                            true
                        )
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then

                        draggingSlider = false
                    end
                end)

                local function RefreshSlider(shouldCallback)
                    current = RoundStep(current)

                    local percent =
                        (current - minimum) /
                        math.max(maximum - minimum, 0.00001)

                    fill.Size =
                        UDim2.new(percent, 0, 1, 0)

                    knob.Position =
                        UDim2.new(percent, 0, 0.5, 0)

                    valueLabel.Text =
                        tostring(current)

                    if shouldCallback
                        and typeof(sliderConfig.Callback) == "function" then

                        task.spawn(
                            sliderConfig.Callback,
                            current
                        )
                    end
                end

                function Slider:SetValue(value, callCallback)
                    current = tonumber(value) or minimum
                    RefreshSlider(callCallback ~= false)
                end

                function Slider:GetValue()
                    return current
                end

                function Slider:SetRange(min, max, default)
                    minimum = tonumber(min) or minimum
                    maximum = tonumber(max) or maximum

                    if default ~= nil then
                        current = tonumber(default) or minimum
                    end

                    RefreshSlider(false)
                end

                Slider.Root = root

                RefreshSlider(false)

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Slider
            end

            --==================================================
            -- INPUT
            --==================================================

            function Section:CreateInput(inputConfig)
                inputConfig = inputConfig or {}

                local Input = {}

                local title =
                    inputConfig.Title or "Input"

                local desc =
                    inputConfig.Desc or ""

                local root = New("Frame", {
                    Parent = ElementHolder,

                    Size = UDim2.new(1, 0, 0, desc ~= "" and 75 or 62),

                    BackgroundColor3 = COLORS.Panel,

                    BorderSizePixel = 0,

                    ZIndex = 15,
                })

                AddStroke(root, COLORS.Border, 1)

                New("TextLabel", {
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
                })

                local y = 27

                if desc ~= "" then
                    New("TextLabel", {
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
                    })

                    y = 46
                end

                local box = New("Frame", {
                    Parent = root,

                    Position = UDim2.fromOffset(10, y),

                    Size = UDim2.new(1, -20, 0, 26),

                    BackgroundColor3 = COLORS.Panel2,

                    BorderSizePixel = 0,

                    ZIndex = 18,
                })

                AddStroke(box, COLORS.Border, 1)

                local textBox = New("TextBox", {
                    Parent = box,

                    BackgroundTransparency = 1,

                    Position = UDim2.fromOffset(8, 0),

                    Size = UDim2.new(1, -16, 1, 0),

                    Text = inputConfig.Value or "",

                    PlaceholderText =
                        inputConfig.Placeholder or "",

                    PlaceholderColor3 = COLORS.Muted,

                    TextColor3 = COLORS.Text,

                    TextSize = 10,

                    Font = Enum.Font.Gotham,

                    ClearTextOnFocus = false,

                    TextXAlignment = Enum.TextXAlignment.Left,

                    ZIndex = 19,
                })

                textBox.FocusLost:Connect(function(enterPressed)
                    if typeof(inputConfig.Callback) == "function" then
                        task.spawn(
                            inputConfig.Callback,
                            textBox.Text,
                            enterPressed
                        )
                    end
                end)

                function Input:GetValue()
                    return textBox.Text
                end

                function Input:SetValue(value)
                    textBox.Text = tostring(value or "")
                end

                Input.Root = root
                Input.TextBox = textBox

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Input
            end

            --==================================================
            -- DROPDOWN
            --==================================================

            function Section:CreateDropdown(dropdownConfig)
                dropdownConfig = dropdownConfig or {}

                local Dropdown = {}

                local title =
                    dropdownConfig.Title or "Dropdown"

                local desc =
                    dropdownConfig.Desc or ""

                local values =
                    dropdownConfig.Values or {}

                local selected =
                    dropdownConfig.Value

                if selected == nil and #values > 0 then
                    selected = values[1]
                end

                local root = New("Frame", {
                    Parent = ElementHolder,

                    Size = UDim2.new(1, 0, 0, desc ~= "" and 72 or 57),

                    BackgroundColor3 = COLORS.Panel,

                    BorderSizePixel = 0,

                    ZIndex = 15,
                })

                AddStroke(root, COLORS.Border, 1)

                New("TextLabel", {
                    Parent = root,

                    BackgroundTransparency = 1,

                    Position = UDim2.fromOffset(11, desc ~= "" and 7 or 6),

                    Size = UDim2.new(1, -200, 0, 19),

                    Text = title,

                    TextColor3 = COLORS.Text,

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

                        TextColor3 = COLORS.SubText,

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

                    BackgroundColor3 = COLORS.Panel2,

                    BorderSizePixel = 0,

                    AutoButtonColor = false,

                    Text = "",

                    ZIndex = 20,
                })

                AddStroke(display, COLORS.Border, 1)

                local selectedLabel = New("TextLabel", {
                    Parent = display,

                    BackgroundTransparency = 1,

                    Position = UDim2.fromOffset(9, 0),

                    Size = UDim2.new(1, -30, 1, 0),

                    Text = tostring(selected or "Select..."),

                    TextColor3 = COLORS.Text,

                    TextSize = 10,

                    Font = Enum.Font.Gotham,

                    TextXAlignment = Enum.TextXAlignment.Left,

                    TextTruncate = Enum.TextTruncate.AtEnd,

                    ZIndex = 21,
                })

                CreateIcon(
                    display,
                    "chevrons-up-down",
                    15,
                    UDim2.new(1, -22, 0.5, -7),
                    21
                )

                --==================================================
                -- DROPDOWN MODAL
                --==================================================

                local overlay

                local function CloseDropdown()
                    if overlay then
                        local old = overlay
                        overlay = nil

                        local popup =
                            old:FindFirstChild("Popup")

                        if popup then
                            Tween(
                                popup,
                                TWEEN_FAST,
                                {
                                    Size = UDim2.fromOffset(350, 0)
                                }
                            )
                        end

                        task.delay(0.14, function()
                            if old then
                                old:Destroy()
                            end
                        end)
                    end
                end

                local function OpenDropdown()
                    if overlay then
                        CloseDropdown()
                        return
                    end

                    overlay = New("Frame", {
                        Parent = ScreenGui,

                        Name = "DropdownOverlay",

                        Size = UDim2.fromScale(1, 1),

                        BackgroundColor3 = COLORS.Black,

                        BackgroundTransparency = 0.52,

                        BorderSizePixel = 0,

                        ZIndex = 1000,
                    })

                    -- Clicking outside popup closes it.
                    local outside = New("TextButton", {
                        Parent = overlay,

                        Size = UDim2.fromScale(1, 1),

                        BackgroundTransparency = 1,

                        Text = "",

                        AutoButtonColor = false,

                        ZIndex = 1000,
                    })

                    local popup = New("Frame", {
                        Parent = overlay,

                        Name = "Popup",

                        AnchorPoint = Vector2.new(0.5, 0.5),

                        Position = UDim2.fromScale(0.5, 0.5),

                        Size = UDim2.fromOffset(350, 0),

                        BackgroundColor3 = COLORS.Background,

                        BorderSizePixel = 0,

                        ZIndex = 1002,
                    })

                    AddStroke(popup, COLORS.Border, 1)

                    outside.MouseButton1Click:Connect(function()
                        CloseDropdown()
                    end)

                    -- Header.
                    local header = New("Frame", {
                        Parent = popup,

                        Size = UDim2.new(1, 0, 0, 50),

                        BackgroundColor3 = COLORS.Background2,

                        BorderSizePixel = 0,

                        ZIndex = 1003,
                    })

                    New("TextLabel", {
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
                    })

                    local modalClose = New("TextButton", {
                        Parent = header,

                        Position = UDim2.new(1, -40, 0, 7),

                        Size = UDim2.fromOffset(32, 36),

                        BackgroundTransparency = 1,

                        BorderSizePixel = 0,

                        AutoButtonColor = false,

                        Text = "",

                        ZIndex = 1005,
                    })

                    local modalCloseIcon = CreateIcon(
                        modalClose,
                        "x",
                        18,
                        UDim2.new(0.5, -9, 0.5, -9),
                        1006
                    )

                    if modalCloseIcon then
                        modalCloseIcon.ImageColor3 =
                            COLORS.Danger
                    end

                    modalClose.MouseButton1Click:Connect(function()
                        CloseDropdown()
                    end)

                    -- Search.
                    local search = New("Frame", {
                        Parent = popup,

                        Position = UDim2.fromOffset(10, 58),

                        Size = UDim2.new(1, -20, 0, 34),

                        BackgroundColor3 = COLORS.Panel,

                        BorderSizePixel = 0,

                        ZIndex = 1003,
                    })

                    AddStroke(search, COLORS.Border, 1)

                    CreateIcon(
                        search,
                        "search",
                        15,
                        UDim2.fromOffset(9, 9),
                        1004
                    )

                    local searchBox = New("TextBox", {
                        Parent = search,

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
                    })

                    -- Options.
                    local optionList = New("ScrollingFrame", {
                        Parent = popup,

                        Position = UDim2.fromOffset(10, 100),

                        Size = UDim2.new(1, -20, 0, 190),

                        BackgroundTransparency = 1,

                        BorderSizePixel = 0,

                        ScrollBarThickness = 4,

                        ScrollBarImageColor3 = COLORS.Border,

                        CanvasSize = UDim2.new(),

                        AutomaticCanvasSize = Enum.AutomaticSize.Y,

                        ScrollingDirection = Enum.ScrollingDirection.Y,

                        ZIndex = 1003,
                    })

                    AddPadding(optionList, 1, 4, 1, 4)

                    local optionLayout = New("UIListLayout", {
                        Parent = optionList,

                        FillDirection = Enum.FillDirection.Vertical,

                        SortOrder = Enum.SortOrder.LayoutOrder,

                        Padding = UDim.new(0, 4),
                    })

                    -- Count.
                    New("TextLabel", {
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
                    })

                    local function SelectOption(value)
                        selected = value

                        selectedLabel.Text =
                            tostring(value)

                        CloseDropdown()

                        if typeof(dropdownConfig.Callback) ==
                            "function" then

                            task.spawn(
                                dropdownConfig.Callback,
                                value
                            )
                        end
                    end

                    local function RenderOptions()
                        for _, child in ipairs(
                            optionList:GetChildren()
                        ) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end

                        local filter =
                            searchBox.Text:lower()

                        for index, value in ipairs(values) do
                            local stringValue =
                                tostring(value)

                            local matches =
                                filter == ""
                                or stringValue:lower():find(
                                    filter,
                                    1,
                                    true
                                )

                            if matches then
                                local option = New(
                                    "TextButton",
                                    {
                                        Parent = optionList,

                                        Size = UDim2.new(
                                            1,
                                            0,
                                            0,
                                            35
                                        ),

                                        BackgroundColor3 =
                                            COLORS.Panel,

                                        BorderSizePixel = 0,

                                        AutoButtonColor = false,

                                        Text = "",

                                        LayoutOrder = index,

                                        ZIndex = 1005,
                                    }
                                )

                                AddStroke(
                                    option,
                                    COLORS.Border,
                                    1
                                )

                                New(
                                    "TextLabel",
                                    {
                                        Parent = option,

                                        BackgroundTransparency =
                                            1,

                                        Position =
                                            UDim2.fromOffset(
                                                10,
                                                0
                                            ),

                                        Size = UDim2.new(
                                            1,
                                            -45,
                                            1,
                                            0
                                        ),

                                        Text =
                                            stringValue,

                                        TextColor3 =
                                            tostring(value) ==
                                            tostring(selected)
                                            and COLORS.Accent2
                                            or COLORS.Text,

                                        TextSize = 10,

                                        Font =
                                            Enum.Font.GothamMedium,

                                        TextXAlignment =
                                            Enum.TextXAlignment.Left,

                                        TextTruncate =
                                            Enum.TextTruncate.AtEnd,

                                        ZIndex = 1006,
                                    }
                                )

                                if tostring(value) ==
                                    tostring(selected) then

                                    CreateIcon(
                                        option,
                                        "check",
                                        15,
                                        UDim2.new(
                                            1,
                                            -27,
                                            0.5,
                                            -7
                                        ),
                                        1007
                                    )
                                end

                                option.MouseEnter:Connect(
                                    function()
                                        Tween(
                                            option,
                                            TWEEN_FAST,
                                            {
                                                BackgroundColor3 =
                                                    COLORS.Panel2
                                            }
                                        )
                                    end
                                )

                                option.MouseLeave:Connect(
                                    function()
                                        Tween(
                                            option,
                                            TWEEN_FAST,
                                            {
                                                BackgroundColor3 =
                                                    COLORS.Panel
                                            }
                                        )
                                    end
                                )

                                option.MouseButton1Click:Connect(
                                    function()
                                        SelectOption(value)
                                    end
                                )
                            end
                        end
                    end

                    searchBox:GetPropertyChangedSignal("Text"):Connect(
                        function()
                            RenderOptions()
                        end
                    )

                    RenderOptions()

                    -- Animate in.
                    Tween(
                        popup,
                        TWEEN_MED,
                        {
                            Size = UDim2.fromOffset(350, 290)
                        }
                    )
                end

                display.MouseEnter:Connect(function()
                    Tween(
                        display,
                        TWEEN_FAST,
                        {
                            BackgroundColor3 = COLORS.Panel2
                        }
                    )
                end)

                display.MouseLeave:Connect(function()
                    Tween(
                        display,
                        TWEEN_FAST,
                        {
                            BackgroundColor3 = COLORS.Panel2
                        }
                    )
                end)

                display.MouseButton1Click:Connect(function()
                    OpenDropdown()
                end)

                function Dropdown:Refresh(newValues)
                    if type(newValues) ~= "table" then
                        return
                    end

                    values = newValues

                    if selected ~= nil then
                        local found = false

                        for _, value in ipairs(values) do
                            if tostring(value) ==
                                tostring(selected) then

                                found = true
                                break
                            end
                        end

                        if not found then
                            selected = values[1]
                        end
                    elseif #values > 0 then
                        selected = values[1]
                    end

                    selectedLabel.Text =
                        tostring(selected or "Select...")
                end

                function Dropdown:SetValue(value, callCallback)
                    selected = value

                    selectedLabel.Text =
                        tostring(selected)

                    if callCallback ~= false
                        and typeof(dropdownConfig.Callback) ==
                        "function" then

                        task.spawn(
                            dropdownConfig.Callback,
                            selected
                        )
                    end
                end

                function Dropdown:GetValue()
                    return selected
                end

                function Dropdown:GetValues()
                    return values
                end

                Dropdown.Root = root

                RegisterElement(
                    root,
                    title,
                    desc
                )

                return Dropdown
            end

            return Section
        end

        table.insert(Window.Tabs, Tab)

        if not Window.ActiveTab then
            Tab:Select()
        end

        return Tab
    end

    --==================================================
    -- EXTRA WINDOW METHODS
    --==================================================

    function Window:SetTitle(title)
        Window.Title = tostring(title)

        for _, object in ipairs(TopBar:GetChildren()) do
            if object:IsA("TextLabel")
                and object.Text ~= Window.Subtitle then

                if object.Position.X.Offset == 58
                    and object.Position.Y.Offset == 8 then

                    object.Text = Window.Title
                end
            end
        end
    end

    function Window:SetIcon(icon)
        Window.Image = icon

        local resolved = ResolveIcon(icon)

        if not resolved then
            return
        end

        for _, child in ipairs(
            WindowIconHolder:GetChildren()
        ) do
            if child:IsA("ImageLabel") then
                child.Image = resolved
            end
        end

        for _, child in ipairs(
            FloatingButton:GetChildren()
        ) do
            if child:IsA("ImageLabel") then
                child.Image = resolved
            end
        end
    end

    function Window:SetVisible(value)
        if value then
            if Window.Minimized then
                Window:Restore()
            else
                Main.Visible = true
            end
        else
            Main.Visible = false
        end
    end

    function Window:GetActiveTab()
        return Window.ActiveTab
    end

    --==================================================
    -- OPEN ANIMATION
    --==================================================

    Main.Size = UDim2.fromOffset(550, 0)

    Tween(
        Main,
        TWEEN_MED,
        {
            Size = UDim2.fromOffset(550, 340)
        }
    )

    return Window
end

return DarkyUI
